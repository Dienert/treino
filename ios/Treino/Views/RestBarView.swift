import SwiftUI

struct RestBarView: View {
    @EnvironmentObject var rest: RestController

    private var timeStr: String {
        let s = rest.remaining
        return "\(s / 60):\(String(format: "%02d", s % 60))"
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.gray.opacity(0.35))
                    Rectangle().fill(Pal.bg)
                        .frame(width: geo.size.width * rest.progress)
                        .animation(.linear(duration: 0.25), value: rest.progress)
                }
            }
            .frame(height: 4)

            HStack(spacing: 12) {
                Button { rest.skip() } label: { pill("Pular") }
                Text(timeStr)
                    .font(.system(size: 30, weight: .heavy)).monospacedDigit()
                    .foregroundStyle(Pal.bg)
                    .frame(minWidth: 74)
                Text("DESCANSO")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Pal.bg.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button { rest.addTime(15) } label: { pill("+15s") }
            }
            .padding(.horizontal, 16).padding(.top, 11).padding(.bottom, 13)
        }
        .background(Pal.text)
        .transition(.move(edge: .bottom))
    }

    private func pill(_ t: String) -> some View {
        Text(t)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Pal.bg)
            .padding(.horizontal, 13).padding(.vertical, 9)
            .background(Color.gray.opacity(0.28), in: RoundedRectangle(cornerRadius: 10))
    }
}
