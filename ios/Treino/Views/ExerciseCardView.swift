import SwiftUI

struct ExerciseCardView: View {
    @EnvironmentObject var store: Store
    let ex: Exercise
    let index: Int
    let onEditLoad: (Int) -> Void
    let onMark: (Int) -> Void

    @State private var userExpanded: Bool?

    private var feitas: Int { store.feitas(ex) }
    private var complete: Bool { feitas == ex.sets }
    private var isNow: Bool { index == store.nextIndex() && !complete }
    private var expanded: Bool { complete ? (userExpanded ?? false) : true }

    var body: some View {
        VStack(spacing: 0) {
            header
            if expanded {
                VStack(spacing: 0) {
                    if let prev = store.lastPerformed(ex.id), prev.sets.contains(where: { !$0.load.isEmpty }), feitas == 0 {
                        ReuseButton { store.reuse(ex) }
                            .padding(.bottom, 10)
                    }
                    ForEach(0..<ex.sets, id: \.self) { n in
                        SetRow(ex: ex, n: n, onEditLoad: onEditLoad, onMark: onMark)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
        .background(Pal.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(borderColor, lineWidth: isNow ? 2 : 1))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var borderColor: Color {
        if isNow { return Pal.accent }
        if complete { return Pal.doneLine }
        return Pal.border
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(complete ? Pal.done : isNow ? Pal.accent : Pal.surface2)
                Text(complete ? "✓" : "\(index + 1)")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(complete || isNow ? Color.white : Pal.muted)
            }
            .frame(width: 25, height: 25)

            VStack(alignment: .leading, spacing: 3) {
                Text(ex.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Pal.text)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    subLine.lineLimit(1)
                    if isNow {
                        Text("AGORA")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(Pal.accent)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Pal.accentSoft, in: Capsule())
                    }
                    Text("\(feitas)/\(ex.sets)")
                        .font(.system(size: 12, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(complete ? Pal.done : Pal.faint)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(complete ? Pal.doneSoft : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { if complete { userExpanded = !expanded } }
    }

    @ViewBuilder private var subLine: some View {
        if let prev = store.lastPerformed(ex.id) {
            let loads = prev.sets.map { $0.load.isEmpty ? "✓" : DateUtils.fmtLoad($0.load) + ex.u }.joined(separator: " · ")
            (Text("Última vez (\(DateUtils.relDate(prev.date))): ").foregroundStyle(Pal.muted)
                + Text(loads).foregroundStyle(Pal.text).bold())
                .font(.system(size: 12))
        } else {
            Text("\(ex.sets) séries × \(ex.reps)\(ex.u == "s" ? "s" : " reps")")
                .font(.system(size: 12))
                .foregroundStyle(Pal.muted)
        }
    }
}

private struct ReuseButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text("↺ Repetir as cargas da última vez")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(Pal.muted)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Pal.surface2, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Pal.border, style: StrokeStyle(lineWidth: 1, dash: [4])))
        }
        .buttonStyle(.plain)
    }
}

private struct SetRow: View {
    @EnvironmentObject var store: Store
    let ex: Exercise
    let n: Int
    let onEditLoad: (Int) -> Void
    let onMark: (Int) -> Void

    private var st: SetEntry? { store.session()?.sets[ex.id]?[safe: n] }
    private var on: Bool { st?.done ?? false }
    private var load: String { st?.load ?? "" }

    var body: some View {
        HStack(spacing: 6) {
            Text("\(n + 1)")
                .font(.system(size: 12, weight: .heavy)).monospacedDigit()
                .foregroundStyle(on ? Pal.done : Pal.faint)
                .frame(width: 18)

            if !ex.bw {
                StepButton(symbol: "−") { store.step(ex, n, -1) }
            }

            Button { onEditLoad(n) } label: {
                HStack(spacing: 5) {
                    Text(load.isEmpty ? (ex.bw ? "livre" : "—") : DateUtils.fmtLoad(load))
                        .font(.system(size: load.isEmpty ? 14 : 17, weight: load.isEmpty ? .medium : .bold))
                        .monospacedDigit()
                        .foregroundStyle(load.isEmpty ? Pal.faint : Pal.text)
                        .lineLimit(1)
                    Text(ex.u).font(.system(size: 11, weight: .bold)).foregroundStyle(Pal.muted)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(on ? Pal.doneSoft : Pal.bg, in: RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(on ? Pal.doneLine : Pal.border, lineWidth: 1.5))
            }
            .buttonStyle(.plain)

            if !ex.bw {
                StepButton(symbol: "+") { store.step(ex, n, 1) }
            }

            Button { onMark(n) } label: {
                Text(on ? "✓" : "○")
                    .font(.system(size: 19))
                    .foregroundStyle(on ? Color.white : Pal.faint)
                    .frame(width: 58, height: 42)
                    .background(on ? Pal.done : Pal.surface2, in: RoundedRectangle(cornerRadius: 11))
                    .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(on ? Pal.done : Pal.border, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

private struct StepButton: View {
    let symbol: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Pal.muted)
                .frame(width: 38, height: 42)
                .background(Pal.surface2, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Pal.border, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}
