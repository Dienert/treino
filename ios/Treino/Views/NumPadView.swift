import SwiftUI

/// Teclado numérico próprio, herdado do site. No nativo o motivo original
/// (zoom do Safari ao focar `<input>`) não existe, mas o teclado grande com
/// atalhos de +2,5 / +5 / +10 é ótimo na academia — então foi mantido.
struct NumPadView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    let ex: Exercise
    let n: Int

    @State private var buf = ""
    @State private var fresh = true

    private var isSeconds: Bool { ex.unit == "s" }
    private var quick: [Double] { isSeconds ? [-5, 5, 10, 15] : [-2.5, 2.5, 5, 10] }

    var body: some View {
        VStack(spacing: 9) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ex.name).font(.system(size: 13.5, weight: .semibold)).lineLimit(2)
                    Text("Série \(n + 1) de \(ex.sets) · alvo \(ex.reps)\(isSeconds ? "s" : " reps")")
                        .font(.system(size: 12)).foregroundStyle(Pal.muted)
                }
                Spacer(minLength: 0)
                Button { dismiss() } label: {
                    Text("Pronto")
                        .font(.system(size: 14.5, weight: .bold)).foregroundStyle(.white)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(Pal.accent, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 14).padding(.horizontal, 4)

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(buf.isEmpty ? "0" : DateUtils.fmtLoad(buf))
                    .font(.system(size: 42, weight: .heavy)).monospacedDigit()
                Text(ex.u).font(.system(size: 16, weight: .bold)).foregroundStyle(Pal.muted)
            }
            .padding(.bottom, 6)

            HStack(spacing: 7) {
                ForEach(quick, id: \.self) { q in
                    Button { applyQuick(q) } label: {
                        Text("\(q > 0 ? "+" : "−")\(DateUtils.fmtLoad(numStr(abs(q))))")
                            .font(.system(size: 14, weight: .bold)).monospacedDigit()
                            .foregroundStyle(Pal.accent)
                            .frame(maxWidth: .infinity).padding(.vertical, 11)
                            .background(Pal.accentSoft, in: RoundedRectangle(cornerRadius: 11))
                    }
                    .buttonStyle(.plain)
                }
            }

            let keys = ["1","2","3","4","5","6","7","8","9",".","0","del"]
            LazyVGrid(columns: Array(repeating: GridItem(spacing: 7), count: 3), spacing: 7) {
                ForEach(keys, id: \.self) { k in
                    Button { press(k) } label: {
                        Text(k == "del" ? "⌫" : k == "." ? "," : k)
                            .font(.system(size: k == "del" ? 19 : 23, weight: .regular)).monospacedDigit()
                            .foregroundStyle(k == "del" ? Pal.alarm : Pal.text)
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(Pal.surface2, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 12)
        .background(Pal.surface)
        .onAppear { buf = store.loadOf(ex, n); fresh = true }
    }

    private func press(_ k: String) {
        if k == "del" {
            buf = String(buf.dropLast()); fresh = false
        } else {
            if fresh { buf = ""; fresh = false }
            if k == "." && buf.contains(".") { return }
            if k == "." && buf.isEmpty { buf = "0" }
            if buf.replacingOccurrences(of: ".", with: "").count >= 5 { return }
            buf += k
        }
        commit()
    }

    private func applyQuick(_ q: Double) {
        let base = Double(buf) ?? 0
        buf = numStr(max(0, ((base + q) * 10).rounded() / 10))
        fresh = false
        commit()
    }

    private func commit() {
        store.setLoad(ex, n, buf)
    }
}
