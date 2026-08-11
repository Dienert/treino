import Foundation
import AVFoundation

/// Toca a sirene do alarme por cima da música.
///
/// No iPhone nativo — ao contrário da web — dá para **abaixar** o Spotify e
/// tocar por cima (`.duckOthers + .mixWithOthers`), pausar e retomar, ou
/// simplesmente tomar a sessão. O modo é escolhido em Ajustes.
///
/// A sirene é o MESMO WAV de dois tons gerado em tempo de execução do site
/// (`makeAlarmClip`), aqui reproduzido com AVAudioPlayer.
final class AudioManager {
    static let shared = AudioManager()

    private var player: AVAudioPlayer?
    private let session = AVAudioSession.sharedInstance()
    private var clip: Data = Data()

    private init() {
        clip = AudioManager.makeAlarmClip()
    }

    // MARK: - Sessão

    private func options(for mode: AudioMode) -> AVAudioSession.CategoryOptions {
        switch mode {
        case .duck:        return [.duckOthers, .mixWithOthers]
        case .pauseResume: return []            // interrompe; devolve ao desativar
        case .override:    return []            // interrompe e não devolve
        }
    }

    /// Ativa a sessão no modo escolhido, imediatamente antes de tocar.
    func activate(_ mode: AudioMode) {
        do {
            try session.setCategory(.playback, options: options(for: mode))
            try session.setActive(true)
        } catch {
            // fallback: modo que sempre toca
            try? session.setCategory(.playback)
            try? session.setActive(true)
        }
    }

    /// Devolve a sessão. Em "pausar e retomar" avisa o outro app para voltar.
    func deactivate(_ mode: AudioMode) {
        let opts: AVAudioSession.SetActiveOptions = mode == .pauseResume ? [.notifyOthersOnDeactivation] : []
        try? session.setActive(false, options: opts)
    }

    // MARK: - Tocar

    /// Toca a sirene em loop por até `seconds` segundos.
    @discardableResult
    func playAlarm(mode: AudioMode, seconds: TimeInterval = 8) -> Bool {
        activate(mode)
        do {
            let p = try AVAudioPlayer(data: clip, fileTypeHint: AVFileType.wav.rawValue)
            p.volume = 1
            p.numberOfLoops = Int(ceil(seconds / max(0.1, p.duration))) // repete até cobrir o tempo
            p.prepareToPlay()
            p.play()
            player = p
            return true
        } catch {
            return false
        }
    }

    func stop(mode: AudioMode) {
        player?.stop()
        player = nil
        deactivate(mode)
    }

    var isPlaying: Bool { player?.isPlaying ?? false }

    // MARK: - Sirene WAV (porta de makeAlarmClip)

    /// Renderiza a sirene de dois tons num WAV PCM 16-bit mono, 22.05 kHz.
    /// Começa com 0,15 s de silêncio de propósito (herança do destravamento
    /// do site; aqui só mantém o ataque limpo).
    static func makeAlarmClip() -> Data {
        let sr = 22050.0
        let dur = 1.40
        let n = Int((sr * dur).rounded())
        var pcm = [Int16](repeating: 0, count: n)

        let tones: [(start: Double, len: Double, freq: Double)] = [
            (0.15, 0.20, 980), (0.39, 0.20, 1460), (0.63, 0.20, 980), (0.87, 0.30, 1460),
        ]
        for t in tones {
            let s0 = Int((t.start * sr).rounded())
            let s1 = min(n, Int(((t.start + t.len) * sr).rounded()))
            guard s0 < s1 else { continue }
            for i in s0..<s1 {
                let tt = Double(i - s0) / sr
                let env = min(1.0, tt / 0.008, (t.len - tt) / 0.03) // evita estalo no ataque
                let sample = (sin(2 * .pi * t.freq * tt) >= 0 ? 1.0 : -1.0) * env * 0.6
                pcm[i] = Int16(max(-32767, min(32767, sample * 32767)))
            }
        }

        var data = Data()
        func str(_ s: String) { data.append(contentsOf: s.utf8) }
        func u32(_ v: UInt32) { var x = v.littleEndian; withUnsafeBytes(of: &x) { data.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { var x = v.littleEndian; withUnsafeBytes(of: &x) { data.append(contentsOf: $0) } }

        let bytes = pcm.count * 2
        str("RIFF"); u32(UInt32(36 + bytes))
        str("WAVE"); str("fmt "); u32(16)
        u16(1); u16(1)                 // PCM, mono
        u32(UInt32(sr)); u32(UInt32(sr) * 2)
        u16(2); u16(16)
        str("data"); u32(UInt32(bytes))
        for sample in pcm { u16(UInt16(bitPattern: sample)) }  // amostras little-endian
        return data
    }
}
