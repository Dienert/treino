import SwiftUI
import UserNotifications
import ActivityKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var rest: RestController
    @State private var exportURL: URL?
    @State private var showImporter = false
    @State private var pendingImport: URL?
    @State private var confirmClear = false
    @State private var notifStatus = "verificando…"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel("Descanso entre séries").padding(.top, 8)
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 9) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Duração").font(.system(size: 14.5, weight: .semibold))
                            Text("Começa sozinho ao marcar uma série").font(.system(size: 12)).foregroundStyle(Pal.muted)
                        }
                        FlowLayout {
                            ForEach([30, 45, 50, 60, 90, 120], id: \.self) { v in
                                chip("\(v)s", on: store.prefs.rest == v) {
                                    store.prefs.rest = v; store.savePrefs()
                                    Toast.show("Descanso de \(v) segundos")
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(13)
                    Divider().overlay(Pal.border)
                    row("Alarme", "Sirene + tela cheia piscando no fim") {
                        chip("Testar", on: false) { rest.testAlarm(prefs: store.prefs) }
                    }
                }
                .modifier(GroupBox2())

                SectionLabel("Com música tocando")
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 9) {
                        Text("Quando o alarme tocar").font(.system(size: 14.5, weight: .semibold))
                        Text(audioDesc).font(.system(size: 12)).foregroundStyle(Pal.muted)
                        FlowLayout {
                            ForEach(AudioMode.allCases, id: \.self) { m in
                                chip(audioLabel(m), on: store.prefs.audio == m) {
                                    store.prefs.audio = m; store.savePrefs()
                                    Toast.show("Toque em Testar para ouvir")
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(13)
                    Divider().overlay(Pal.border)
                    toggleRow("Alarme com tela bloqueada",
                              "Notificação local no fim do descanso — atravessa o Modo Foco",
                              isOn: $store.prefs.lockAlarm)
                    Divider().overlay(Pal.border)
                    toggleRow("Live Activity na Dynamic Island",
                              "Contagem do descanso na tela bloqueada",
                              isOn: $store.prefs.liveActivity)
                }
                .modifier(GroupBox2())

                SectionLabel("Diagnóstico")
                VStack(spacing: 0) {
                    diag("Notificações", notifStatus)
                    Divider().overlay(Pal.border)
                    diag("Live Activity", liveActivitySupported ? "suportada ✓" : "indisponível neste aparelho")
                    Divider().overlay(Pal.border)
                    diag("Haptics", "suportado ✓ — vibra de verdade no iPhone")
                    Divider().overlay(Pal.border)
                    diag("Tela acesa no descanso", "ligada automaticamente")
                }
                .modifier(GroupBox2())

                SectionLabel("Aparência")
                VStack(spacing: 0) {
                    row("Tema", nil) {
                        HStack(spacing: 6) {
                            chip("Auto", on: store.prefs.theme == .auto) { setTheme(.auto) }
                            chip("Claro", on: store.prefs.theme == .light) { setTheme(.light) }
                            chip("Escuro", on: store.prefs.theme == .dark) { setTheme(.dark) }
                        }
                    }
                }
                .modifier(GroupBox2())

                SectionLabel("Seus dados")
                VStack(spacing: 0) {
                    if let url = exportURL {
                        ShareLink(item: url) { lineBtn("Exportar backup (.json)") }
                    } else {
                        Button { exportURL = store.exportData() } label: { lineBtn("Preparar backup (.json)") }
                            .buttonStyle(.plain)
                    }
                    Divider().overlay(Pal.border)
                    Button { showImporter = true } label: { lineBtn("Importar backup") }
                        .buttonStyle(.plain)
                    Divider().overlay(Pal.border)
                    Button { confirmClear = true } label: {
                        lineBtn("Apagar o treino deste dia", color: Pal.alarm)
                    }
                    .buttonStyle(.plain)
                }
                .modifier(GroupBox2())

                Text("Os treinos ficam só neste aparelho. Exporte de vez em quando para não perder o histórico.")
                    .font(.system(size: 12)).foregroundStyle(Pal.faint)
                    .multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.top, 4)
            }
            .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 150)
        }
        .onAppear(perform: refreshNotifStatus)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result { pendingImport = url }
        }
        .confirmationDialog("Importar backup", isPresented: Binding(get: { pendingImport != nil }, set: { if !$0 { pendingImport = nil } }), titleVisibility: .visible) {
            Button("Juntar com o histórico atual") { doImport(merge: true) }
            Button("Substituir tudo", role: .destructive) { doImport(merge: false) }
            Button("Cancelar", role: .cancel) { pendingImport = nil }
        }
        .confirmationDialog("Apagar o Treino \(store.tab) de \(store.pessoa.nome) em \(DateUtils.fmtDate(store.dateISO))?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Apagar", role: .destructive) {
                Toast.show(store.clearDay() ? "Registro apagado" : "Não há nada registrado neste dia")
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    // MARK: - Ações

    private func setTheme(_ t: ThemeChoice) { store.prefs.theme = t; store.savePrefs() }

    private func doImport(merge: Bool) {
        guard let url = pendingImport else { return }
        defer { pendingImport = nil }
        do { try store.importData(url, merge: merge); Toast.show("Backup importado") }
        catch { Toast.show("Não consegui ler esse arquivo") }
    }

    private func refreshNotifStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            let txt: String
            switch s.authorizationStatus {
            case .authorized, .provisional, .ephemeral: txt = "autorizadas ✓"
            case .denied: txt = "negadas — o alarme de fundo não vai tocar"
            default: txt = "ainda não pedidas"
            }
            DispatchQueue.main.async { notifStatus = txt }
        }
    }

    private var liveActivitySupported: Bool {
        if #available(iOS 16.1, *) { return ActivityAuthorizationInfo().areActivitiesEnabled }
        return false
    }

    private func audioLabel(_ m: AudioMode) -> String {
        switch m {
        case .duck: return "Só abaixar"
        case .pauseResume: return "Pausar e retomar"
        case .override: return "Acima de tudo"
        }
    }
    private var audioDesc: String {
        switch store.prefs.audio {
        case .duck: return "Abaixa a música e toca a sirene por cima. Ao fim, a música volta ao volume normal."
        case .pauseResume: return "Pausa a música, toca a sirene e devolve a música ao terminar."
        case .override: return "Toma o áudio: a música para e você despausa na mão."
        }
    }

    // MARK: - Peças de UI

    @ViewBuilder
    private func row<C: View>(_ title: String, _ sub: String?, @ViewBuilder trailing: () -> C) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 14.5, weight: .semibold))
                if let sub { Text(sub).font(.system(size: 12)).foregroundStyle(Pal.muted) }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .padding(13)
    }

    private func toggleRow(_ title: String, _ sub: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: Binding(get: { isOn.wrappedValue }, set: { isOn.wrappedValue = $0; store.savePrefs() })) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 14.5, weight: .semibold))
                Text(sub).font(.system(size: 12)).foregroundStyle(Pal.muted)
            }
        }
        .tint(Pal.accent)
        .padding(13)
    }

    private func diag(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).font(.system(size: 14.5, weight: .semibold))
            Spacer(minLength: 8)
            Text(value).font(.system(size: 12)).foregroundStyle(value.contains("✓") ? Pal.done : Pal.muted)
                .multilineTextAlignment(.trailing)
        }
        .padding(13)
    }

    private func chip(_ t: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(t).font(.system(size: 13, weight: .bold)).monospacedDigit()
                .foregroundStyle(on ? Color.white : Pal.text)
                .padding(.horizontal, 11).padding(.vertical, 7)
                .background(on ? Pal.accent : Pal.surface2, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }

    private func lineBtn(_ t: String, color: Color = Pal.text) -> some View {
        Text(t).font(.system(size: 14.5, weight: .semibold)).foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading).padding(14)
            .contentShape(Rectangle())
    }
}

/// Cartão branco arredondado, como os `.group` do site.
private struct GroupBox2: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Pal.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Pal.border))
    }
}
