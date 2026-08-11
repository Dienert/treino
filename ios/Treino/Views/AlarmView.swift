import SwiftUI
import Combine

/// Tela cheia vermelha piscando + sirene — o alarme impossível de perder.
struct AlarmView: View {
    @EnvironmentObject var rest: RestController
    @State private var flip = false
    @State private var shake = false

    private let flash = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            (flip ? Color.white : Pal.alarm).ignoresSafeArea()
            VStack(spacing: 0) {
                Text("⏰")
                    .font(.system(size: 74))
                    .rotationEffect(.degrees(shake ? 13 : -13))
                    .animation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true), value: shake)
                    .padding(.bottom, 14)
                Text("Descanso acabou!")
                    .font(.system(size: 34, weight: .heavy))
                    .padding(.bottom, 8)
                VStack(spacing: 5) {
                    Text("Hora da próxima série").font(.system(size: 16, weight: .semibold)).opacity(0.92)
                    Text(rest.alarmLabel).font(.system(size: 20, weight: .heavy)).multilineTextAlignment(.center)
                }
                .padding(.bottom, 30)
                Button { rest.dismissAlarm() } label: {
                    Text("Vamos lá")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(flip ? Color.white : Pal.alarm)
                        .padding(.horizontal, 46).padding(.vertical, 18)
                        .background(flip ? Pal.alarm : Color.white, in: Capsule())
                        .shadow(color: .black.opacity(0.3), radius: 15, y: 8)
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(flip ? Pal.alarm : Color.white)
            .padding(28)
        }
        .contentShape(Rectangle())
        .onTapGesture { rest.dismissAlarm() }
        .onReceive(flash) { _ in flip.toggle() }
        .onAppear { shake = true }
        .transition(.opacity)
    }
}
