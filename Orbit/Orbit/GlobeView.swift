import SwiftUI

/// Mutable camera + scene for the dotted globe. Not observed: the TimelineView redraws it every frame.
final class GlobeModel {
    var lon = -100.0
    var lat = 25.0
    var zoom = 1.0
    var autoSpin = true

    var origin: Airport?
    var dest: Airport?
    var showArc = false
    var arcStart = 0.0

    private struct Anim {
        let t0: Double, duration: Double
        let fromLon: Double, fromLat: Double, fromZoom: Double
        let dLon: Double, dLat: Double, dZoom: Double
    }
    private var anim: Anim?
    private var dragStart: (lon: Double, lat: Double)?
    private var lastT = 0.0

    private let land = LandMask.points
    private let airportDots = Airports.all.map { Geo.vec($0.lat, $0.lon) }
    private let stars: [(x: Double, y: Double, s: Double, a: Double)] = (0..<140).map { _ in
        (Double.random(in: 0...1), Double.random(in: 0...1), Double.random(in: 0.3...1.5), Double.random(in: 0...1))
    }

    static func now() -> Double { Date().timeIntervalSinceReferenceDate * 1000 }

    // MARK: Camera

    func spinTo(lat: Double, lon: Double, duration: Double, zoom: Double = 1) {
        self.lon = remainder(self.lon, 360)          // keep the auto-spin angle bounded
        let dl = remainder(lon - self.lon, 360)      // shortest way round, in -180...180
        anim = Anim(t0: Self.now(), duration: duration * 1000,
                    fromLon: self.lon, fromLat: self.lat, fromZoom: self.zoom,
                    dLon: dl, dLat: lat - self.lat, dZoom: zoom - self.zoom)
    }

    /// Center on the route midpoint and zoom so both airports stay in view.
    func frameRoute(from a: Airport, to b: Airport, withRoute: Bool) -> (lat: Double, lon: Double, zoom: Double) {
        guard withRoute else { return (b.lat, b.lon, 1.6) }
        let A = Geo.vec(a.lat, a.lon), B = Geo.vec(b.lat, b.lon)
        let om = acos(max(-1, min(1, (A * B).sum())))
        var m = A + B
        let n = sqrt((m * m).sum())
        if n < 1e-6 { return (b.lat, b.lon, 1) }
        m /= n
        let lat = asin(m.y) * 180 / .pi
        let lon = atan2(m.x, m.z) * 180 / .pi
        let z = max(1, min(2.4, 0.62 / max(0.01, sin(om / 2))))
        return (lat, lon, z)
    }

    func drag(_ t: CGSize) {
        if dragStart == nil { dragStart = (lon, lat); anim = nil }
        guard let s = dragStart else { return }
        lon = s.lon - Double(t.width) * 0.35 / zoom
        lat = max(-70, min(70, s.lat + Double(t.height) * 0.35 / zoom))
    }

    func endDrag() { dragStart = nil }

    // MARK: Projection

    private struct Camera {
        let cl: Double, sl: Double, cp: Double, sp: Double
        let r: Double, cx: Double, cy: Double

        func project(_ v: SIMD3<Double>, alt: Double = 1) -> (x: Double, y: Double, z: Double, d2: Double) {
            let x = v.x * cl - v.z * sl
            let z1 = v.x * sl + v.z * cl
            let y = v.y * cp - z1 * sp
            let z = v.y * sp + z1 * cp
            return (cx + x * r * alt, cy - y * r * alt, z, (x * x + y * y) * alt * alt)
        }
    }

    // MARK: Drawing

    func draw(_ c: inout GraphicsContext, size: CGSize, t: Double, trip: Bool, dark: Bool, accent: Color) {
        let dt = min(64, max(0, t - lastT))
        lastT = t
        if let a = anim {
            let p = min(1, (t - a.t0) / a.duration)
            let e = p < 0.5 ? 4 * p * p * p : 1 - pow(-2 * p + 2, 3) / 2
            lon = a.fromLon + a.dLon * e
            lat = a.fromLat + a.dLat * e
            zoom = a.fromZoom + a.dZoom * e
            if p >= 1 { anim = nil }
        } else if dragStart == nil && dest == nil && autoSpin {
            lon += dt * 0.004
        }

        let W = Double(size.width), H = Double(size.height)
        let cx = W / 2
        let cy = trip ? H * 0.58 : H * 0.46
        let baseR = trip ? min(W * 0.36, H * 0.36) : min(W * 0.44, H * 0.36)
        let R = baseR * zoom
        let cam = Camera(cl: cos(Geo.rad(lon)), sl: sin(Geo.rad(lon)), cp: cos(Geo.rad(lat)), sp: sin(Geo.rad(lat)), r: R, cx: cx, cy: cy)

        let look = dark ? GlobeLook.dusk : GlobeLook.daylight

        // Stars only at night
        if dark {
            let starColor = Color(red: 0.78, green: 0.84, blue: 1)
            for (i, s) in stars.enumerated() {
                let a = 0.08 + 0.3 * s.a * (0.6 + 0.4 * sin(t / 900 + Double(i)))
                c.fill(Path(CGRect(x: s.x * W, y: s.y * H, width: s.s, height: s.s)), with: .color(starColor.opacity(a)))
            }
        }

        // Atmosphere and ocean
        c.fill(Path(ellipseIn: CGRect(x: cx - R * 1.32, y: cy - R * 1.32, width: R * 2.64, height: R * 2.64)),
               with: .radialGradient(Gradient(colors: [look.glow.opacity(look.glowAlpha), look.glow.opacity(0)]),
                                     center: CGPoint(x: cx, y: cy), startRadius: R * 0.9, endRadius: R * 1.32))
        let sphere = Path(ellipseIn: CGRect(x: cx - R, y: cy - R, width: 2 * R, height: 2 * R))
        c.fill(sphere, with: .radialGradient(Gradient(colors: look.ocean),
                                             center: CGPoint(x: cx - R * 0.35, y: cy - R * 0.4),
                                             startRadius: R * 0.05, endRadius: R * 1.1))
        c.stroke(sphere, with: .color(look.rim), lineWidth: 1)

        // Graticule
        var grid = Path()
        for la in stride(from: -60.0, through: 60.0, by: 30.0) {
            addLine(&grid, cam, count: 73) { k in Geo.vec(la, -180 + Double(k) * 5) }
        }
        for lo in stride(from: -180.0, to: 180.0, by: 30.0) {
            addLine(&grid, cam, count: 73) { k in Geo.vec(-90 + Double(k) * 2.5, lo) }
        }
        c.stroke(grid, with: .color(look.grid), lineWidth: 1)

        // Land dots, bucketed by depth for shading
        var buckets = [Path(), Path(), Path(), Path()]
        let dot = max(1.1, baseR / 210) * 1.15 * sqrt(zoom)
        for v in land {
            let q = cam.project(v)
            if q.z <= 0.02 { continue }
            let b = min(3, Int(q.z * 4))
            let s = dot * (0.65 + Double(b) * 0.14)
            buckets[b].addRect(CGRect(x: q.x - s / 2, y: q.y - s / 2, width: s, height: s))
        }
        for (i, p) in buckets.enumerated() {
            c.fill(p, with: .color(look.land[i]))
        }

        // Known airports
        var ap = Path()
        for v in airportDots {
            let q = cam.project(v)
            if q.z > 0.05 { ap.addEllipse(in: CGRect(x: q.x - 1.6, y: q.y - 1.6, width: 3.2, height: 3.2)) }
        }
        c.fill(ap, with: .color(look.airports))

        // Route
        if let o = origin, let d = dest, showArc { drawArc(&c, cam, from: o, to: d, t: t, accent: accent, glow: look.planeGlow) }

        // Home airport
        if let o = origin {
            let q = cam.project(Geo.vec(o.lat, o.lon))
            if q.z > 0 {
                c.fill(circle(q.x, q.y, 9), with: .color(Theme.sage.opacity(0.22)))
                c.fill(circle(q.x, q.y, 4), with: .color(Theme.sage))
                tag(&c, q.x, q.y, o.code, Theme.sage, width: W)
            }
        }

        // Destination: slow, soft pulse
        if let d = dest {
            let q = cam.project(Geo.vec(d.lat, d.lon))
            if q.z > 0 {
                for k in 0..<2 {
                    let ph = (t / 3400 + Double(k) / 2).truncatingRemainder(dividingBy: 1)
                    let ease = 1 - pow(1 - ph, 2)
                    c.stroke(circle(q.x, q.y, 6 + ease * 16), with: .color(accent.opacity((1 - ph) * 0.4)), lineWidth: 1.2)
                }
                c.fill(circle(q.x, q.y, 16),
                       with: .radialGradient(Gradient(colors: [accent.opacity(0.22 + 0.08 * sin(t / 900)), accent.opacity(0)]),
                                             center: CGPoint(x: q.x, y: q.y), startRadius: 0, endRadius: 16))
                c.fill(circle(q.x, q.y, 4.5), with: .color(accent))
                c.fill(circle(q.x, q.y, 2.2), with: .color(.white))
                tag(&c, q.x, q.y, "\(d.code) · \(d.city)", accent, width: W)
            }
        }
    }

    private func circle(_ x: Double, _ y: Double, _ r: Double) -> Path {
        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
    }

    private func addLine(_ path: inout Path, _ cam: Camera, count: Int, _ f: (Int) -> SIMD3<Double>) {
        var pen = false
        for k in 0..<count {
            let q = cam.project(f(k))
            if q.z > 0 {
                let p = CGPoint(x: q.x, y: q.y)
                if pen { path.addLine(to: p) } else { path.move(to: p) }
                pen = true
            } else {
                pen = false
            }
        }
    }

    private func drawArc(_ c: inout GraphicsContext, _ cam: Camera, from o: Airport, to d: Airport, t: Double, accent: Color, glow: Color) {
        let A = Geo.vec(o.lat, o.lon), B = Geo.vec(d.lat, d.lon)
        let om = acos(max(-1, min(1, (A * B).sum())))
        if om < 0.001 { return }
        var prog = max(0, min(1, (t - arcStart) / 2400))
        prog = 1 - pow(1 - prog, 3)
        if prog <= 0 { return }
        let n = 90
        let lift = (0.03 + 0.17 * min(1, om / 1.6)) / sqrt(zoom)
        // Normal to the route's plane, pointed north, used to bow the path into a visible curve.
        var nrm = SIMD3(A.y * B.z - A.z * B.y, A.z * B.x - A.x * B.z, A.x * B.y - A.y * B.x)
        let nl = sqrt((nrm * nrm).sum())
        if nl > 1e-9 { nrm /= nl }
        if nrm.y < 0 { nrm = -nrm }
        let bow = min(0.3, 0.26 * om + 0.02)
        var pts: [(p: CGPoint, vis: Bool)] = []
        pts.reserveCapacity(n + 1)
        for i in 0...n {
            let u = Double(i) / Double(n) * prog
            let s1 = sin((1 - u) * om) / sin(om), s2 = sin(u * om) / sin(om)
            var v = A * s1 + B * s2 + nrm * (bow * sin(.pi * u))
            v /= sqrt((v * v).sum())
            let q = cam.project(v, alt: 1 + lift * sin(.pi * u))
            pts.append((CGPoint(x: q.x, y: q.y), q.z > 0 || q.d2 > 1))
        }
        var path = Path()
        var pen = false
        for pt in pts {
            if pt.vis {
                if pen { path.addLine(to: pt.p) } else { path.move(to: pt.p) }
                pen = true
            } else {
                pen = false
            }
        }
        c.stroke(path, with: .color(accent.opacity(0.18)), lineWidth: 4)
        c.stroke(path, with: .color(accent.opacity(0.95)),
                 style: StrokeStyle(lineWidth: 1.8, lineCap: .round, dash: [5, 6], dashPhase: -t / 90))
        if prog >= 1 {
            let ph = (t / 9000).truncatingRemainder(dividingBy: 1)
            let pt = pts[min(n, Int(ph * Double(n)))]
            if pt.vis {
                c.fill(circle(pt.p.x, pt.p.y, 9),
                       with: .radialGradient(Gradient(colors: [glow.opacity(0.9), glow.opacity(0)]),
                                             center: pt.p, startRadius: 0, endRadius: 9))
            }
        }
    }

    private func tag(_ c: inout GraphicsContext, _ x: Double, _ y: Double, _ text: String, _ color: Color, width: Double) {
        let label = c.resolve(Text(text).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.text))
        let size = label.measure(in: CGSize(width: 300, height: 40))
        let w = Double(size.width) + 14, h = 20.0
        var tx = x + 12
        let ty = y - h - 8
        if tx + w > width - 6 { tx = x - 12 - w }
        let box = Path(roundedRect: CGRect(x: tx, y: ty, width: w, height: h), cornerRadius: 6)
        c.fill(box, with: .color(Theme.surface.opacity(0.9)))
        c.stroke(box, with: .color(color), lineWidth: 1)
        c.draw(label, at: CGPoint(x: tx + 7, y: ty + h / 2), anchor: .leading)
    }
}

/// The two globe looks. Same dotted style; only the palette changes.
private struct GlobeLook {
    let glow: Color, glowAlpha: Double
    let ocean: [Color]
    let rim: Color, grid: Color
    let land: [Color]
    let airports: Color, planeGlow: Color

    private static func rgba(_ r: Double, _ g: Double, _ b: Double, _ a: Double) -> Color {
        Color(red: r / 255, green: g / 255, blue: b / 255).opacity(a)
    }

    static let daylight = GlobeLook(
        glow: Color(hex: 0x7FAEE6), glowAlpha: 0.30,
        ocean: [Color(hex: 0xFAFCFF), Color(hex: 0xE3EEF9), Color(hex: 0xC8DBF0)],
        rim: Color(hex: 0x5A82BE).opacity(0.35), grid: Color(hex: 0x4A6FA5).opacity(0.10),
        land: [rgba(88, 118, 160, 0.22), rgba(70, 102, 148, 0.42), rgba(55, 88, 135, 0.66), rgba(40, 70, 118, 0.88)],
        airports: Color(hex: 0xE57F2E).opacity(0.45), planeGlow: Color(hex: 0xE57F2E))

    static let dusk = GlobeLook(
        glow: Color(hex: 0x82A5DC), glowAlpha: 0.16,
        ocean: [Color(hex: 0x22314C), Color(hex: 0x1A263A), Color(hex: 0x141C2A)],
        rim: Color(hex: 0xA0B9E1).opacity(0.25), grid: Color(hex: 0x96AAD2).opacity(0.07),
        land: [rgba(150, 170, 205, 0.2), rgba(165, 185, 215, 0.38), rgba(185, 200, 225, 0.58), rgba(214, 224, 238, 0.85)],
        airports: Color(hex: 0xF0D7B4).opacity(0.45), planeGlow: .white)
}

struct GlobeView: View {
    let model: GlobeModel
    let trip: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                model.draw(&context, size: size, t: timeline.date.timeIntervalSinceReferenceDate * 1000, trip: trip, dark: colorScheme == .dark, accent: Theme.route)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { model.drag($0.translation) }
                .onEnded { _ in model.endDrag() }
        )
        .accessibilityElement()
        .accessibilityLabel("Globe showing your nearest airport and destination. Drag to rotate.")
    }
}
