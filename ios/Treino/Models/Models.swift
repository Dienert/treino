import Foundation

// MARK: - Plano (dados estáticos dos treinos)

/// Um exercício de um plano. O `id` é a chave estável do histórico e é único
/// entre TODAS as pessoas — nunca mude o `id` de um exercício existente, senão
/// o registro antigo se perde (mesma regra do site).
struct Exercise: Identifiable, Hashable {
    let id: String
    let name: String
    let sets: Int
    let reps: String
    /// "kg" (padrão) ou "s" (segundos, ex.: prancha).
    let unit: String
    /// Peso corporal: o campo mostra "livre" e some os −/+.
    let bw: Bool

    init(id: String, name: String, sets: Int, reps: String, unit: String = "kg", bw: Bool = false) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.unit = unit
        self.bw = bw
    }

    /// Unidade normalizada, igual ao `unitOf` do site.
    var u: String { unit == "s" ? "s" : "kg" }
}

/// Um treino (A, B, C, …) de uma pessoa.
struct Plano: Identifiable, Hashable {
    /// Letra do treino — "A", "B", "C", "D".
    let letter: String
    /// Rótulo curto da aba, ex.: "Peito · Tríceps".
    let short: String
    let ex: [Exercise]
    var id: String { letter }
}

/// Uma pessoa com seus planos, na ordem do ciclo.
struct Pessoa: Identifiable, Hashable {
    let id: String
    let nome: String
    let planos: [Plano]

    func plano(_ letter: String) -> Plano? { planos.first { $0.letter == letter } }
    var letters: [String] { planos.map(\.letter) }
}

// MARK: - Estado persistido (mesmo formato JSON do backup do site)

/// Uma série de um exercício. `load` é texto ("", "20", "22.5") como no site,
/// para guardar exatamente o que o usuário digitou. `auto` marca herança.
struct SetEntry: Codable, Hashable {
    var done: Bool
    var load: String
    var auto: Bool?

    init(done: Bool = false, load: String = "", auto: Bool? = nil) {
        self.done = done
        self.load = load
        self.auto = auto
    }
}

/// Uma sessão de treino de um dia. Chave no dicionário: `data|pessoa|treino`.
struct Session: Codable, Hashable {
    var date: String
    var pessoa: String
    var workout: String
    var sets: [String: [SetEntry]]
    var done: Bool
    /// Epoch em milissegundos (compatível com o `Date.now()` do site) ou nil.
    var finishedAt: Double?

    init(date: String, pessoa: String, workout: String) {
        self.date = date
        self.pessoa = pessoa
        self.workout = workout
        self.sets = [:]
        self.done = false
        self.finishedAt = nil
    }

    /// Decodificação tolerante: backups muito antigos podem não trazer todos os
    /// campos (ex.: `pessoa`). O `migrar()` do Store reconstrói o que faltar.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = try c.decodeIfPresent(String.self, forKey: .date) ?? ""
        pessoa = try c.decodeIfPresent(String.self, forKey: .pessoa) ?? ""
        workout = try c.decodeIfPresent(String.self, forKey: .workout) ?? ""
        sets = try c.decodeIfPresent([String: [SetEntry]].self, forKey: .sets) ?? [:]
        done = try c.decodeIfPresent(Bool.self, forKey: .done) ?? false
        finishedAt = try c.decodeIfPresent(Double.self, forKey: .finishedAt)
    }
}

/// Banco inteiro — o mesmo shape do arquivo `.json` exportado pelo site.
struct DB: Codable {
    var sessions: [String: Session]

    init(sessions: [String: Session] = [:]) {
        self.sessions = sessions
    }
}

// MARK: - Preferências

enum ThemeChoice: String, Codable, CaseIterable {
    case auto, light, dark
}

/// Modos de convivência com outro app de áudio (Spotify).
/// No iOS nativo, ao contrário da web, os três funcionam de verdade.
enum AudioMode: String, Codable, CaseIterable {
    case duck        // abaixa a música e toca por cima (recomendado no nativo)
    case pauseResume // pausa e devolve a música ao terminar
    case override    // toma tudo: a música para e não volta
}

struct Prefs: Codable {
    var rest: Int = 50
    var theme: ThemeChoice = .auto
    var pessoa: String = "dienert"
    var audio: AudioMode = .duck
    /// Notificação local com tela bloqueada (o "alarme de fundo" do nativo).
    var lockAlarm: Bool = true
    /// Live Activity na Dynamic Island durante o descanso.
    var liveActivity: Bool = true

    init() {}

    /// Decodificação tolerante: um `prefs.json` de uma versão anterior pode não
    /// ter todas as chaves; as ausentes ficam no padrão em vez de zerar tudo.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rest = try c.decodeIfPresent(Int.self, forKey: .rest) ?? 50
        theme = try c.decodeIfPresent(ThemeChoice.self, forKey: .theme) ?? .auto
        pessoa = try c.decodeIfPresent(String.self, forKey: .pessoa) ?? "dienert"
        audio = try c.decodeIfPresent(AudioMode.self, forKey: .audio) ?? .duck
        lockAlarm = try c.decodeIfPresent(Bool.self, forKey: .lockAlarm) ?? true
        liveActivity = try c.decodeIfPresent(Bool.self, forKey: .liveActivity) ?? true
    }
}
