import Foundation
import SwiftUI
import UIKit

/// Cronômetro de descanso + alarme. Coordena áudio, notificação de fundo,
/// Live Activity, haptics e a tela para não apagar. Espelha o comportamento
/// de `startRest`/`fireAlarm` do site, com o que só o nativo permite.
@MainActor
final class RestController: ObservableObject {
    @Published var resting = false
    @Published var remaining = 0            // segundos, para o rótulo
    @Published var progress: Double = 1     // 1 → 0, para a barra
    @Published var alarmShowing = false
    @Published var alarmLabel = ""

    private var restEnd = Date()
    private var restTotal: TimeInterval = 50
    private var restLabel = ""
    private var timer: Timer?
    private var autoDismiss: Timer?
    private var mode: AudioMode = .duck
    private var pessoaNome = ""
    private var workout = ""

    /// Prefs vivas (injetadas pelo app a cada início de descanso).
    var prefs = Prefs()

    // MARK: - Iniciar

    func start(seconds: TimeInterval, label: String, pessoaNome: String, workout: String, prefs: Prefs) {
        self.prefs = prefs
        self.mode = prefs.audio
        self.pessoaNome = pessoaNome
        self.workout = workout
        restLabel = label
        restTotal = seconds
        restEnd = Date().addingTimeInterval(seconds)
        resting = true
        alarmShowing = false

        UIApplication.shared.isIdleTimerDisabled = true   // "wake lock" nativo

        if prefs.lockAlarm {
            NotificationManager.shared.scheduleRestEnd(in: seconds, label: label)
        }
        if prefs.liveActivity, #available(iOS 16.1, *) {
            LiveActivityController.shared.start(
                pessoa: pessoaNome, workout: workout,
                end: restEnd, total: seconds, label: label
            )
        }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        tick()
    }

    /// Recalcula pelo horário real — chamado ao voltar do segundo plano.
    func refresh() {
        guard resting else { return }
        UIApplication.shared.isIdleTimerDisabled = true
        tick()
    }

    private func tick() {
        let leftMs = restEnd.timeIntervalSinceNow
        remaining = max(0, Int(ceil(leftMs)))
        progress = max(0, min(1, leftMs / restTotal))
        if leftMs <= 0 { fireAlarm() }
    }

    func addTime(_ s: TimeInterval) {
        restEnd = restEnd.addingTimeInterval(s)
        restTotal += s
        if prefs.lockAlarm {
            NotificationManager.shared.scheduleRestEnd(in: restEnd.timeIntervalSinceNow, label: restLabel)
        }
        if prefs.liveActivity, #available(iOS 16.1, *) {
            LiveActivityController.shared.update(end: restEnd, total: restTotal, label: restLabel)
        }
        tick()
    }

    /// "Pular" — encerra o descanso sem alarme.
    func skip() {
        stopTimers()
        resting = false
        AudioManager.shared.stop(mode: mode)
        NotificationManager.shared.cancelRestEnd()
        if #available(iOS 16.1, *) { LiveActivityController.shared.end() }
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - Alarme

    func fireAlarm() {
        stopTimers()
        resting = false
        alarmLabel = restLabel
        alarmShowing = true

        // estamos em primeiro plano: a notificação de fundo é redundante
        NotificationManager.shared.cancelRestEnd()
        if #available(iOS 16.1, *) { LiveActivityController.shared.end() }

        AudioManager.shared.playAlarm(mode: mode, seconds: 8)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)   // impossível na web

        autoDismiss?.invalidate()
        autoDismiss = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.dismissAlarm() }
        }
    }

    func dismissAlarm() {
        guard alarmShowing else { return }
        alarmShowing = false
        AudioManager.shared.stop(mode: mode)
        UIApplication.shared.isIdleTimerDisabled = false
        autoDismiss?.invalidate()
    }

    /// Alarme de teste (Ajustes) — dispara já, sem agendar nada de fundo.
    func testAlarm(prefs: Prefs) {
        self.prefs = prefs
        self.mode = prefs.audio
        restLabel = "É só um teste"
        fireAlarm()
    }

    private func stopTimers() {
        timer?.invalidate(); timer = nil
    }
}
