import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var rest: RestController
    @Binding var nav: NavItem
    @State private var showDate = false

    var body: some View {
        VStack(spacing: 0) {
            // pessoa + data
            HStack(spacing: 10) {
                PessoaSelector()
                DateChip(showDate: $showDate)
            }
            .padding(.horizontal, 14)
            .padding(.top, 11)
            .padding(.bottom, 12)

            if nav == .treino {
                TabsRow()
                ProgressRow()
            }
        }
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showDate) { DatePickerSheet() }
    }
}

private struct PessoaSelector: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var rest: RestController

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Plans.pessoas) { p in
                let sel = p.id == store.pessoaId
                Button {
                    guard !sel else { return }
                    rest.skip()
                    store.trocarPessoa(p.id)
                } label: {
                    Text(p.nome)
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundStyle(sel ? Color.white : Pal.muted)
                        .background(sel ? Pal.accent : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Pal.surface2, in: Capsule())
        .frame(maxWidth: .infinity)
    }
}

private struct DateChip: View {
    @EnvironmentObject var store: Store
    @Binding var showDate: Bool

    var body: some View {
        Button { showDate = true } label: {
            Text(store.isToday ? "hoje" : DateUtils.fmtDate(store.dateISO))
                .font(.system(size: 13.5, weight: .semibold))
                .lineLimit(1)
                .padding(.horizontal, 13).padding(.vertical, 7)
                .foregroundStyle(store.isToday ? Pal.text : Pal.accent)
                .background(store.isToday ? Pal.surface : Pal.accentSoft, in: Capsule())
                .overlay(Capsule().strokeBorder(store.isToday ? Pal.border : Pal.accent))
        }
        .buttonStyle(.plain)
    }
}

private struct DatePickerSheet: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var rest: RestController
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            let binding = Binding<Date>(
                get: { DateUtils.date(from: store.dateISO) },
                set: { newDate in
                    rest.skip()
                    store.dateISO = DateUtils.iso.string(from: newDate)
                    store.tab = store.openingTab(for: store.pessoaId)
                }
            )
            DatePicker("Data do treino", selection: binding, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Data do treino")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { Button("Pronto") { dismiss() } }
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Hoje") {
                            rest.skip()
                            store.dateISO = DateUtils.todayISO()
                            store.tab = store.openingTab(for: store.pessoaId)
                        }
                    }
                }
        }
        .presentationDetents([.medium])
    }
}

private struct TabsRow: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var rest: RestController

    var body: some View {
        let sug = store.suggested()
        let apertado = store.letters.count > 3
        HStack(spacing: apertado ? 6 : 7) {
            ForEach(store.letters, id: \.self) { l in
                let plano = store.pessoa.plano(l)!
                let s = store.db.sessions[store.keyOf(store.dateISO, store.pessoaId, l)]
                let c = store.count(s, l)
                let sel = l == store.tab
                Button {
                    guard l != store.tab else { return }
                    rest.skip(); store.tab = l
                } label: {
                    VStack(spacing: 1) {
                        Text(apertado ? l : "Treino \(l)")
                            .font(.system(size: apertado ? 17 : 15, weight: .bold))
                        Text(plano.short)
                            .font(.system(size: apertado ? 9 : 10, weight: .semibold))
                            .lineLimit(1)
                            .foregroundStyle(sel ? Color.white.opacity(0.82) : Pal.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8).padding(.horizontal, 2)
                    .foregroundStyle(sel ? Color.white : Pal.text)
                    .background(sel ? Pal.accent : Pal.surface, in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(sel ? Pal.accent : Pal.border))
                    .overlay(alignment: .top) {
                        if l == sug && c.done == 0 {
                            Text("próximo")
                                .font(.system(size: 8.5, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Pal.accent, in: Capsule())
                                .offset(y: -6)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if let s, s.done {
                            Text("✓").font(.system(size: 11))
                                .foregroundStyle(sel ? .white : Pal.done)
                                .padding(5)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 11)
    }
}

private struct ProgressRow: View {
    @EnvironmentObject var store: Store

    var body: some View {
        let c = store.count(store.session(), store.tab)
        let pct = c.total > 0 ? Double(c.done) / Double(c.total) : 0
        let full = c.done == c.total && c.total > 0
        HStack(spacing: 10) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Pal.surface2)
                    Capsule().fill(full ? Pal.done : Pal.accent)
                        .frame(width: geo.size.width * pct)
                        .animation(.easeInOut(duration: 0.3), value: pct)
                }
            }
            .frame(height: 8)
            Text("\(c.done)/\(c.total) séries")
                .font(.system(size: 12.5, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Pal.muted)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 11)
    }
}
