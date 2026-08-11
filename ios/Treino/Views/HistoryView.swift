import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        let all = store.historySessions()
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                statsRow(all)
                SectionLabel("Treinos registrados").padding(.top, 22).padding(.bottom, 9)
                if all.isEmpty {
                    Text("Nenhum treino registrado ainda.\nMarque suas séries na aba Treino e elas aparecem aqui.")
                        .font(.system(size: 14)).foregroundStyle(Pal.muted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity).padding(.vertical, 46)
                } else {
                    ForEach(all, id: \.self) { s in
                        HistoryItem(session: s)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)
            .padding(.bottom, 150)
        }
    }

    private func statsRow(_ all: [Session]) -> some View {
        let cutoff = DateUtils.iso.string(from: Date().addingTimeInterval(-30 * 86400))
        let recent = all.filter { $0.date >= cutoff }.count
        let vol = all.reduce(0.0) { $0 + store.sessionStats($1).volume }
        let volStr = vol >= 1000 ? String(format: "%.1ft", vol / 1000) : "\(Int(vol.rounded()))kg"
        return HStack(spacing: 8) {
            StatCard(value: "\(all.count)", label: "treinos\nno total")
            StatCard(value: "\(recent)", label: "nos últimos\n30 dias")
            StatCard(value: volStr, label: "volume\nacumulado")
        }
        .padding(.top, 16)
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 22, weight: .heavy)).monospacedDigit()
                .foregroundStyle(Pal.text)
            Text(label).font(.system(size: 11)).foregroundStyle(Pal.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Pal.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Pal.border))
    }
}

struct SectionLabel: View {
    let text: String
    init(_ t: String) { text = t }
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11.5, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(Pal.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HistoryItem: View {
    @EnvironmentObject var store: Store
    let session: Session
    @State private var open = false
    @State private var confirmDelete = false

    var body: some View {
        let st = store.sessionStats(session)
        VStack(spacing: 0) {
            HStack(spacing: 11) {
                Text(session.workout)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Pal.accent)
                    .frame(width: 34, height: 34)
                    .background(Pal.accentSoft, in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 1) {
                    Text(DateUtils.fmtDate(session.date))
                        .font(.system(size: 14.5, weight: .semibold)).foregroundStyle(Pal.text)
                    Text("\(DateUtils.relDate(session.date)) · \(st.done)/\(st.total) séries\(session.done ? " · concluído" : "")")
                        .font(.system(size: 12)).foregroundStyle(Pal.muted)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold)).foregroundStyle(Pal.faint)
                    .rotationEffect(.degrees(open ? 90 : 0))
            }
            .padding(.horizontal, 13).padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { open.toggle() } }

            if open {
                VStack(spacing: 0) {
                    ForEach(detailLines(), id: \.name) { line in
                        HStack {
                            Text(line.name).font(.system(size: 13)).foregroundStyle(Pal.muted)
                            Spacer(minLength: 14)
                            Text(line.loads).font(.system(size: 13, weight: .semibold)).monospacedDigit()
                                .foregroundStyle(Pal.text)
                        }
                        .padding(.vertical, 5)
                        .overlay(Rectangle().frame(height: 1).foregroundStyle(Pal.border), alignment: .top)
                    }
                    Button(role: .destructive) { confirmDelete = true } label: {
                        Text("Apagar este treino")
                            .font(.system(size: 13, weight: .semibold)).foregroundStyle(Pal.muted)
                            .frame(maxWidth: .infinity).padding(.vertical, 11)
                            .overlay(Rectangle().frame(height: 1).foregroundStyle(Pal.border), alignment: .top)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 13).padding(.bottom, 4)
            }
        }
        .background(Pal.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Pal.border))
        .padding(.bottom, 8)
        .confirmationDialog("Apagar este treino do histórico?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Apagar", role: .destructive) {
                store.deleteSession(store.keyOf(session.date, session.pessoa, session.workout))
                Toast.show("Treino apagado")
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    private func detailLines() -> [(name: String, loads: String)] {
        guard let plano = store.planoDaSessao(session) else { return [] }
        return plano.ex.compactMap { ex in
            let feitas = (session.sets[ex.id] ?? []).prefix(ex.sets).filter { $0.done }
            guard !feitas.isEmpty else { return nil }
            let loads = feitas.map { $0.load.isEmpty ? "✓" : DateUtils.fmtLoad($0.load) + ex.u }.joined(separator: " · ")
            return (ex.name, loads)
        }
    }
}
