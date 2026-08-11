import Foundation
import ActivityKit

/// Inicia, atualiza e encerra a Live Activity do descanso (Dynamic Island +
/// tela bloqueada). Só o 14 Pro/Pro Max e afins têm a ilha; nos demais a
/// atividade aparece na tela de bloqueio.
@available(iOS 16.1, *)
final class LiveActivityController {
    static let shared = LiveActivityController()
    private var activity: Activity<RestAttributes>?

    var isSupported: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    func start(pessoa: String, workout: String, end: Date, total: TimeInterval, label: String) {
        guard isSupported else { return }
        endImmediate()
        let attr = RestAttributes(pessoaNome: pessoa, workout: workout)
        let state = RestAttributes.ContentState(endDate: end, total: total, nextLabel: label)
        do {
            if #available(iOS 16.2, *) {
                activity = try Activity.request(
                    attributes: attr,
                    content: .init(state: state, staleDate: end.addingTimeInterval(3))
                )
            } else {
                activity = try Activity.request(attributes: attr, contentState: state)
            }
        } catch {
            activity = nil
        }
    }

    func update(end: Date, total: TimeInterval, label: String) {
        guard let activity else { return }
        let state = RestAttributes.ContentState(endDate: end, total: total, nextLabel: label)
        Task {
            if #available(iOS 16.2, *) {
                await activity.update(.init(state: state, staleDate: end.addingTimeInterval(3)))
            } else {
                await activity.update(using: state)
            }
        }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        Task {
            if #available(iOS 16.2, *) {
                await activity.end(nil, dismissalPolicy: .immediate)
            } else {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }

    /// Encerra a atividade anterior de forma síncrona-otimista (troca de treino).
    private func endImmediate() {
        let old = activity
        activity = nil
        guard let old else { return }
        Task {
            if #available(iOS 16.2, *) {
                await old.end(nil, dismissalPolicy: .immediate)
            } else {
                await old.end(dismissalPolicy: .immediate)
            }
        }
    }
}
