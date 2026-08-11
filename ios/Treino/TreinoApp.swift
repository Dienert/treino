import SwiftUI

@main
struct TreinoApp: App {
    @StateObject private var store = Store()
    @StateObject private var rest = RestController()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(rest)
                .preferredColorScheme(scheme(store.prefs.theme))
                .tint(Pal.accent)
                .onAppear { NotificationManager.shared.requestAuth() }
                .onChange(of: scenePhase) { phase in
                    if phase == .active { rest.refresh() }
                }
        }
    }

    private func scheme(_ t: ThemeChoice) -> ColorScheme? {
        switch t {
        case .auto: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
