import SwiftUI

enum NavItem: String, CaseIterable {
    case treino, history, config
    var icon: String { self == .treino ? "🏋️" : self == .history ? "📅" : "⚙️" }
    var label: String { self == .treino ? "Treino" : self == .history ? "Histórico" : "Ajustes" }
}

struct ContentView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var rest: RestController
    @State private var nav: NavItem = .treino

    var body: some View {
        ZStack(alignment: .bottom) {
            Pal.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderView(nav: $nav)
                Divider().overlay(Pal.border)

                Group {
                    switch nav {
                    case .treino:  TreinoView()
                    case .history: HistoryView()
                    case .config:  SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // barra de descanso + navegação, presas embaixo
            VStack(spacing: 0) {
                if rest.resting { RestBarView() }
                BottomNav(nav: $nav)
            }
        }
        .overlay { ToastView() }
        .overlay { if rest.alarmShowing { AlarmView() } }
    }
}

/// Navegação inferior — emoji + rótulo, no estilo do site.
struct BottomNav: View {
    @Binding var nav: NavItem

    var body: some View {
        HStack(spacing: 0) {
            ForEach(NavItem.allCases, id: \.self) { item in
                Button {
                    nav = item
                } label: {
                    VStack(spacing: 2) {
                        Text(item.icon).font(.system(size: 19))
                        Text(item.label).font(.system(size: 10.5, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(nav == item ? Pal.accent : Pal.muted)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 60)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Pal.border), alignment: .top)
    }
}
