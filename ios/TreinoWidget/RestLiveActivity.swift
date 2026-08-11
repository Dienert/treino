import ActivityKit
import WidgetKit
import SwiftUI

/// A Live Activity do descanso: tela de bloqueio + Dynamic Island.
@available(iOS 16.1, *)
struct RestLiveActivity: Widget {
    private let accent = Color(red: 0.36, green: 0.55, blue: 1.0)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestAttributes.self) { context in
            // ---- Tela de bloqueio / banner ----
            HStack(spacing: 14) {
                badge(context.attributes.workout)
                VStack(alignment: .leading, spacing: 3) {
                    Text("DESCANSO")
                        .font(.system(size: 11, weight: .bold)).tracking(0.8)
                        .foregroundStyle(.secondary)
                    Text(context.state.nextLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    ProgressView(timerInterval: range(context), countsDown: true)
                        .labelsHidden()
                        .tint(accent)
                }
                Spacer(minLength: 6)
                Text(timerInterval: range(context), countsDown: true)
                    .font(.system(size: 30, weight: .heavy)).monospacedDigit()
                    .foregroundStyle(accent)
                    .frame(width: 76)
                    .multilineTextAlignment(.trailing)
            }
            .padding(16)
            .activityBackgroundTint(Color.black.opacity(0.55))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    badge(context.attributes.workout).padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: range(context), countsDown: true)
                        .font(.system(size: 24, weight: .heavy)).monospacedDigit()
                        .foregroundStyle(accent)
                        .frame(width: 68)
                        .multilineTextAlignment(.trailing)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Descanso").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 5) {
                        Text(context.state.nextLabel)
                            .font(.system(size: 13, weight: .semibold)).lineLimit(1)
                        ProgressView(timerInterval: range(context), countsDown: true)
                            .labelsHidden().tint(accent)
                    }
                }
            } compactLeading: {
                Text("🏋️")
            } compactTrailing: {
                Text(timerInterval: range(context), countsDown: true)
                    .monospacedDigit().foregroundStyle(accent)
                    .frame(width: 44)
            } minimal: {
                Text(timerInterval: range(context), countsDown: true)
                    .monospacedDigit().foregroundStyle(accent)
            }
            .keylineTint(accent)
        }
    }

    private func range(_ ctx: ActivityViewContext<RestAttributes>) -> ClosedRange<Date> {
        let end = ctx.state.endDate
        return end.addingTimeInterval(-ctx.state.total)...end
    }

    private func badge(_ letter: String) -> some View {
        Text(letter)
            .font(.system(size: 16, weight: .heavy))
            .foregroundStyle(accent)
            .frame(width: 36, height: 36)
            .background(accent.opacity(0.18), in: RoundedRectangle(cornerRadius: 11))
    }
}
