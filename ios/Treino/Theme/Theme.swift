import SwiftUI
import UIKit

/// Paleta portada das variáveis CSS do site (claro/escuro). Os `Color`s são
/// dinâmicos: respeitam o esquema do sistema e o override manual de tema
/// (`.preferredColorScheme`).
enum Pal {
    static let bg          = dyn("#f4f6f9", "#0d0f14")
    static let surface     = dyn("#ffffff", "#161a22")
    static let surface2    = dyn("#eaeef4", "#1e232d")
    static let border      = dyn("#dde3ec", "#2a303c")
    static let text        = dyn("#111620", "#e9ecf3")
    static let muted       = dyn("#6b7383", "#98a1b4")
    static let faint       = dyn("#98a1b2", "#6f7889")
    static let accent      = dyn("#2f6df6", "#5b8cff")
    static let accentSoft  = dyn("#e6eeff", "#1a2740")
    static let done        = dyn("#0ea765", "#2fd08c")
    static let doneSoft    = dyn("#e2f7ee", "#0f2c20")
    static let doneLine    = dyn("#8fdcbd", "#1f6b4c")
    static let alarm       = dyn("#f0431f", "#ff5c3a")

    static func dyn(_ light: String, _ dark: String) -> Color {
        Color(UIColor { trait in
            UIColor(hex: trait.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r = CGFloat((v >> 16) & 0xff) / 255
        let g = CGFloat((v >> 8) & 0xff) / 255
        let b = CGFloat(v & 0xff) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

extension Color {
    init(hex: String) { self.init(UIColor(hex: hex)) }
}
