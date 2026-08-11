import SwiftUI

@MainActor
final class ToastCenter: ObservableObject {
    static let shared = ToastCenter()
    @Published var message: String?
    private var task: Task<Void, Never>?

    func post(_ m: String) {
        message = m
        task?.cancel()
        task = Task {
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            if !Task.isCancelled { message = nil }
        }
    }
}

enum Toast {
    @MainActor static func show(_ m: String) { ToastCenter.shared.post(m) }
}

struct ToastView: View {
    @ObservedObject var center = ToastCenter.shared

    var body: some View {
        VStack {
            Spacer()
            if let m = center.message {
                Text(m)
                    .font(.system(size: 14, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Pal.bg)
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .background(Pal.text, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 96)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .animation(.spring(duration: 0.3), value: center.message)
    }
}
