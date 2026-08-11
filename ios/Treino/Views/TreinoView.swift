import SwiftUI
import UIKit

struct PadTarget: Identifiable {
    let ex: Exercise
    let n: Int
    var id: String { "\(ex.id)-\(n)" }
}

struct TreinoView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var rest: RestController
    @State private var pad: PadTarget?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(Array(store.plan.ex.enumerated()), id: \.element.id) { item in
                        ExerciseCardView(
                            ex: item.element,
                            index: item.offset,
                            onEditLoad: { n in pad = PadTarget(ex: item.element, n: n) },
                            onMark: { n in mark(item.element, n, proxy) }
                        )
                        .id(item.element.id)
                    }
                    FinishButton()
                    tip
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 150)
            }
        }
        .sheet(item: $pad) { t in
            NumPadView(ex: t.ex, n: t.n)
                .presentationDetents([.height(480)])
        }
    }

    private func mark(_ ex: Exercise, _ n: Int, _ proxy: ScrollViewProxy) {
        let r = store.toggleSet(ex, n)
        if r.done {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            rest.start(
                seconds: TimeInterval(store.prefs.rest),
                label: store.nextSetLabel(),
                pessoaNome: store.pessoa.nome,
                workout: store.tab,
                prefs: store.prefs
            )
            if r.complete {
                let next = store.nextIndex()
                if next >= 0 {
                    let id = store.plan.ex[next].id
                    withAnimation(.easeInOut) { proxy.scrollTo(id, anchor: .top) }
                }
            }
        }
    }

    private var tip: some View {
        Text("Toque no ✓ para marcar a série — o descanso começa sozinho.\nTudo é salvo automaticamente neste aparelho.")
            .font(.system(size: 12))
            .foregroundStyle(Pal.faint)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 14)
    }
}

/// Botão "Concluir treino" com os três estados do site.
private struct FinishButton: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var rest: RestController
    @State private var toastMsg: String?

    var body: some View {
        let c = store.count(store.session(), store.tab)
        let s = store.session()
        let isDone = s?.done ?? false
        let ready = !isDone && c.done > 0

        Button {
            let r = store.toggleFinish()
            if !r.changed {
                Toast.show("Marque pelo menos uma série antes de concluir")
                return
            }
            if r.nowDone {
                rest.skip()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                Toast.show(r.done == r.total
                    ? "Treino \(store.tab) completo! 🎉  Próximo: \(store.suggested())"
                    : "Treino \(store.tab) salvo — \(r.done) de \(r.total) séries")
            }
        } label: {
            Text(finishLabel(isDone: isDone, c: c))
                .font(.system(size: 15.5, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(16)
                .foregroundStyle(isDone ? Pal.done : ready ? Color.white : Pal.text)
                .background(background(isDone: isDone, ready: ready), in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(isDone ? Pal.done : ready ? Pal.accent : Pal.border))
        }
        .buttonStyle(.plain)
        .padding(.top, 18)
    }

    private func finishLabel(isDone: Bool, c: (done: Int, total: Int)) -> String {
        if isDone { return "✓ Treino concluído — toque para reabrir" }
        if c.done == 0 { return "Concluir treino" }
        if c.done == c.total { return "🎉 Concluir treino" }
        return "Concluir treino (\(c.done)/\(c.total))"
    }

    private func background(isDone: Bool, ready: Bool) -> Color {
        if isDone { return Pal.doneSoft }
        if ready { return Pal.accent }
        return Pal.surface
    }
}
