import Foundation
import UserNotifications

/// Alarme de fundo: notificação local `.timeSensitive`, que dispara com a tela
/// bloqueada e atravessa o Modo Foco — o que a web não conseguia fazer.
final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    private let restId = "rest-alarm"
    private var soundName: UNNotificationSoundName?

    private init() { installSound() }

    /// Pede permissão de notificação (a interrupção "time sensitive" vem junto).
    func requestAuth() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// Grava a sirene gerada em Library/Sounds para a notificação usar o mesmo
    /// som do alarme dentro do app. Se falhar, cai no som padrão do sistema.
    private func installSound() {
        guard let dir = try? FileManager.default.url(
            for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        ).appendingPathComponent("Sounds", isDirectory: true) else { return }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("treino-alarm.wav")
        if !FileManager.default.fileExists(atPath: url.path) {
            try? AudioManager.makeAlarmClip().write(to: url, options: .atomic)
        }
        if FileManager.default.fileExists(atPath: url.path) {
            soundName = UNNotificationSoundName("treino-alarm.wav")
        }
    }

    /// Agenda o disparo do fim do descanso.
    func scheduleRestEnd(in seconds: TimeInterval, label: String) {
        cancelRestEnd()
        let content = UNMutableNotificationContent()
        content.title = "Descanso acabou! ⏰"
        content.body = "Hora da próxima série\n\(label)"
        content.sound = soundName.map { UNNotificationSound(named: $0) } ?? .default
        content.interruptionLevel = .timeSensitive
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        center.add(UNNotificationRequest(identifier: restId, content: content, trigger: trigger))
    }

    func cancelRestEnd() {
        center.removePendingNotificationRequests(withIdentifiers: [restId])
        center.removeDeliveredNotifications(withIdentifiers: [restId])
    }
}
