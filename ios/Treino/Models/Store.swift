import Foundation
import SwiftUI

/// Estado + persistência do app. Porta fiel da lógica do `index.html`:
/// mesmas chaves de sessão (`data|pessoa|treino`), mesma herança de carga e
/// mesmo formato de arquivo do backup `.json`.
@MainActor
final class Store: ObservableObject {
    @Published var db = DB()
    @Published var prefs = Prefs()

    @Published var pessoaId: String = "dienert"
    @Published var tab: String = "A"
    @Published var dateISO: String = DateUtils.todayISO()

    private var saveTask: DispatchWorkItem?

    private let dbURL: URL
    private let prefsURL: URL

    var pessoa: Pessoa { Plans.pessoa(pessoaId) }
    var plan: Plano { pessoa.plano(tab) ?? pessoa.planos[0] }
    var letters: [String] { pessoa.letters }
    var isToday: Bool { dateISO == DateUtils.todayISO() }

    init() {
        let dir = Store.storageDir()
        dbURL = dir.appendingPathComponent("treino.json")
        prefsURL = dir.appendingPathComponent("prefs.json")
        load()
        // abre na pessoa salva, no treino já começado hoje ou no sugerido
        pessoaId = Plans.pessoas.contains { $0.id == prefs.pessoa } ? prefs.pessoa : "dienert"
        tab = openingTab(for: pessoaId)
    }

    // MARK: - Diretório

    /// Guarda no container do App Group (compartilhado com o widget) se houver,
    /// senão em Documents. Nada é enviado para servidor nenhum.
    static func storageDir() -> URL {
        if let g = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroup) {
            return g
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Chaves

    func keyOf(_ d: String, _ p: String, _ w: String) -> String { "\(d)|\(p)|\(w)" }

    // MARK: - Carregar / salvar

    func load() {
        if let data = try? Data(contentsOf: dbURL),
           let decoded = try? JSONDecoder().decode(DB.self, from: data) {
            db = decoded
        }
        if let data = try? Data(contentsOf: prefsURL),
           let decoded = try? JSONDecoder().decode(Prefs.self, from: data) {
            prefs = decoded
        }
        migrar()
    }

    /// Chaves antigas eram `data|treino` (só existia o Diénert). Viram
    /// `data|pessoa|treino` sem perder nada — mesma `migrar()` do site.
    private func migrar() {
        var mexeu = false
        for k in Array(db.sessions.keys) {
            let partes = k.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            if partes.count == 2 {
                let d = partes[0], w = partes[1]
                var s = db.sessions[k]!
                s.pessoa = "dienert"
                db.sessions[keyOf(d, "dienert", w)] = s
                db.sessions[k] = nil
                mexeu = true
            } else if partes.count == 3, db.sessions[k]?.pessoa.isEmpty == true {
                db.sessions[k]?.pessoa = partes[1]
                mexeu = true
            }
        }
        if mexeu { save() }
    }

    func save() {
        saveTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if let data = try? JSONEncoder().encode(self.db) {
                try? data.write(to: self.dbURL, options: .atomic)
            }
        }
        saveTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: task)
    }

    func savePrefs() {
        if let data = try? JSONEncoder().encode(prefs) {
            try? data.write(to: prefsURL, options: .atomic)
        }
    }

    // MARK: - Sessão

    /// Sessão atual (data/pessoa/treino selecionados). Cria se `create`.
    @discardableResult
    func session(create: Bool = false) -> Session? {
        let k = keyOf(dateISO, pessoaId, tab)
        if db.sessions[k] == nil && create {
            db.sessions[k] = Session(date: dateISO, pessoa: pessoaId, workout: tab)
        }
        return db.sessions[k]
    }

    /// Grava a sessão de volta no banco.
    private func put(_ s: Session) {
        db.sessions[keyOf(s.date, s.pessoa, s.workout)] = s
    }

    /// Plano da pessoa dona da sessão — o histórico mistura as duas.
    func planoDaSessao(_ s: Session) -> Plano? {
        Plans.pessoa(s.pessoa).plano(s.workout)
    }

    /// Vetor de séries de um exercício na sessão, criando/expandindo se preciso.
    func setsOf(_ s: inout Session, _ ex: Exercise, create: Bool) -> [SetEntry]? {
        if s.sets[ex.id] == nil {
            if !create { return nil }
            s.sets[ex.id] = Array(repeating: SetEntry(), count: ex.sets)
        }
        var arr = s.sets[ex.id]!
        while arr.count < ex.sets { arr.append(SetEntry()) }  // o plano pode ter crescido
        s.sets[ex.id] = arr
        return arr
    }

    /// Sessão anterior mais recente em que este exercício teve alguma série feita.
    func lastPerformed(_ exId: String) -> (date: String, sets: [SetEntry])? {
        var best: Session?
        for s in db.sessions.values {
            guard s.pessoa == pessoaId, s.date < dateISO,
                  let arr = s.sets[exId], arr.contains(where: { $0.done }) else { continue }
            if best == nil || s.date > best!.date { best = s }
        }
        guard let b = best, let arr = b.sets[exId] else { return nil }
        return (b.date, arr.filter { $0.done })
    }

    // MARK: - Progresso / sugestão

    func count(_ s: Session?, _ letter: String) -> (done: Int, total: Int) {
        var done = 0, total = 0
        guard let plano = pessoa.plano(letter) else { return (0, 0) }
        for ex in plano.ex {
            total += ex.sets
            if let arr = s?.sets[ex.id] {
                done += arr.prefix(ex.sets).filter { $0.done }.count
            }
        }
        return (done, total)
    }

    /// Próximo treino do ciclo (A→B→C[→D]).
    func suggested() -> String {
        var last: Session?
        for s in db.sessions.values {
            guard s.done, s.pessoa == pessoaId else { continue }
            if last == nil || s.date > last!.date ||
                (s.date == last!.date && (s.finishedAt ?? 0) > (last!.finishedAt ?? 0)) {
                last = s
            }
        }
        guard let l = last else { return letters.first ?? "A" }
        guard let i = letters.firstIndex(of: l.workout) else { return letters.first ?? "A" }
        return letters[(i + 1) % letters.count]
    }

    func openingTab(for p: String) -> String {
        let pes = Plans.pessoa(p)
        if let started = pes.letters.first(where: { db.sessions[keyOf(dateISO, p, $0)] != nil }) {
            return started
        }
        // sugerido, mas calculado para a pessoa `p`
        var last: Session?
        for s in db.sessions.values where s.done && s.pessoa == p {
            if last == nil || s.date > last!.date ||
                (s.date == last!.date && (s.finishedAt ?? 0) > (last!.finishedAt ?? 0)) { last = s }
        }
        if let l = last, let i = pes.letters.firstIndex(of: l.workout) {
            return pes.letters[(i + 1) % pes.letters.count]
        }
        return pes.letters.first ?? "A"
    }

    /// Índice do primeiro exercício ainda não concluído — o "AGORA".
    func nextIndex() -> Int {
        let s = session()
        return plan.ex.firstIndex { ex in
            guard let arr = s?.sets[ex.id] else { return true }
            return !arr.prefix(ex.sets).allSatisfy { $0.done }
        } ?? -1
    }

    /// "Supino reto · série 2" da próxima série pendente — usado no alarme.
    func nextSetLabel() -> String {
        let s = session()
        for ex in plan.ex {
            let arr = s?.sets[ex.id]
            for n in 0..<ex.sets {
                if arr == nil || n >= arr!.count || !arr![n].done {
                    return "\(ex.name) · série \(n + 1)"
                }
            }
        }
        return "Treino completo 🎉"
    }

    // MARK: - Edição de séries

    /// Copia a carga da série `n` para as seguintes que estejam vazias ou que
    /// vieram desta mesma herança (`auto`). Carga posta à mão nunca é
    /// sobrescrita; corrigir a série 1 corrige as herdadas junto.
    private func herdar(_ ex: Exercise, _ n: Int, _ arr: inout [SetEntry]) {
        let load = arr[n].load
        guard !load.isEmpty else { return }
        var m = n + 1
        while m < ex.sets {
            if arr[m].done || (!arr[m].load.isEmpty && arr[m].auto != true) { m += 1; continue }
            arr[m].load = load
            arr[m].auto = true
            m += 1
        }
    }

    /// −/+ na carga (2,5 kg ou 5 s). Parte da última carga se o campo vazio.
    func step(_ ex: Exercise, _ n: Int, _ dir: Int) {
        var s = session(create: true)!
        guard var arr = setsOf(&s, ex, create: true) else { return }
        let inc = (ex.unit == "s" ? 5.0 : 2.5) * Double(dir)
        let base = Double(arr[n].load)
            ?? Double(lastPerformed(ex.id)?.sets[safe: n]?.load ?? "")
            ?? 0
        let novo = max(0, ((base + inc) * 10).rounded() / 10)
        arr[n].load = numStr(novo)
        arr[n].auto = nil
        herdar(ex, n, &arr)
        s.sets[ex.id] = arr
        put(s)
        save()
    }

    /// Grava a carga digitada no teclado próprio.
    func setLoad(_ ex: Exercise, _ n: Int, _ load: String) {
        var s = session(create: true)!
        guard var arr = setsOf(&s, ex, create: true) else { return }
        arr[n].load = load
        arr[n].auto = nil
        herdar(ex, n, &arr)
        s.sets[ex.id] = arr
        put(s)
        save()
    }

    /// Preenche o exercício inteiro com o que foi feito da última vez.
    func reuse(_ ex: Exercise) {
        guard let prev = lastPerformed(ex.id) else { return }
        var s = session(create: true)!
        guard var arr = setsOf(&s, ex, create: true) else { return }
        for n in 0..<ex.sets {
            let src = prev.sets[safe: n] ?? prev.sets.last
            if let src, !src.load.isEmpty {
                arr[n].load = src.load
                arr[n].auto = nil
            }
        }
        s.sets[ex.id] = arr
        put(s)
        save()
    }

    /// Marca/desmarca a série. Devolve `true` se, ao marcar, o exercício ficou
    /// completo (para o chamador rolar até o próximo e começar o descanso).
    @discardableResult
    func toggleSet(_ ex: Exercise, _ n: Int) -> (done: Bool, complete: Bool) {
        var s = session(create: true)!
        guard var arr = setsOf(&s, ex, create: true) else { return (false, false) }
        arr[n].done.toggle()
        let nowDone = arr[n].done

        if nowDone && arr[n].load.isEmpty {
            // herda a carga da série anterior desta sessão, ou da última vez
            let src = arr.prefix(n).reversed().first { !$0.load.isEmpty }?.load
                ?? lastPerformed(ex.id)?.sets[safe: n]?.load
            if let src, !src.isEmpty { arr[n].load = src }
        }

        s.sets[ex.id] = arr
        put(s)
        save()

        let complete = arr.prefix(ex.sets).allSatisfy { $0.done }
        return (nowDone, complete)
    }

    func feitas(_ ex: Exercise) -> Int {
        (session()?.sets[ex.id] ?? []).prefix(ex.sets).filter { $0.done }.count
    }

    func loadOf(_ ex: Exercise, _ n: Int) -> String {
        session()?.sets[ex.id]?[safe: n]?.load ?? ""
    }

    // MARK: - Concluir treino

    /// Alterna concluído. Devolve `true` se passou a concluído agora.
    @discardableResult
    func toggleFinish() -> (changed: Bool, nowDone: Bool, done: Int, total: Int) {
        var s = session(create: true)!
        let c = count(s, tab)
        if !s.done && c.done == 0 { return (false, false, c.done, c.total) }
        s.done.toggle()
        s.finishedAt = s.done ? Date().timeIntervalSince1970 * 1000 : nil
        put(s)
        save()
        return (true, s.done, c.done, c.total)
    }

    // MARK: - Histórico

    func sessionStats(_ s: Session) -> (done: Int, total: Int, volume: Double) {
        guard let plano = planoDaSessao(s) else { return (0, 0, 0) }
        var done = 0, total = 0, volume = 0.0
        for ex in plano.ex {
            total += ex.sets
            for st in (s.sets[ex.id] ?? []).prefix(ex.sets) where st.done {
                done += 1
                if ex.unit != "s", let kg = Double(st.load), let reps = Int(ex.reps.prefix { $0.isNumber }), kg > 0, reps > 0 {
                    volume += kg * Double(reps)
                }
            }
        }
        return (done, total, volume)
    }

    func historySessions() -> [Session] {
        db.sessions.values
            .filter { $0.pessoa == pessoaId && planoDaSessao($0) != nil && sessionStats($0).done > 0 }
            .sorted { $0.date > $1.date }
    }

    func deleteSession(_ key: String) {
        db.sessions[key] = nil
        save()
    }

    func clearDay() -> Bool {
        let k = keyOf(dateISO, pessoaId, tab)
        guard db.sessions[k] != nil else { return false }
        db.sessions[k] = nil
        save()
        return true
    }

    // MARK: - Backup

    func exportData() -> URL? {
        guard let data = try? JSONEncoder().encodePretty(db) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("treino-dienert-\(DateUtils.todayISO()).json")
        try? data.write(to: url, options: .atomic)
        return url
    }

    /// Importa um backup `.json` do site ou do app. `merge=false` substitui tudo.
    func importData(_ url: URL, merge: Bool) throws {
        let needsStop = url.startAccessingSecurityScopedResource()
        defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        let incoming = try JSONDecoder().decode(DB.self, from: data)
        if merge {
            db.sessions.merge(incoming.sessions) { _, new in new }
        } else {
            db.sessions = incoming.sessions
        }
        migrar()
        save()
    }

    // MARK: - Trocar seleção

    func trocarPessoa(_ p: String) {
        pessoaId = p
        prefs.pessoa = p
        savePrefs()
        tab = openingTab(for: p)
    }
}

// MARK: - Utilidades

/// Número sem ".0" à toa — "22.5" e não "22.500000", "20" e não "20.0".
/// Guardamos sempre com ponto (a exibição troca por vírgula).
func numStr(_ v: Double) -> String {
    if v == v.rounded() { return String(Int(v)) }
    return String(format: "%g", v)
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}

extension JSONEncoder {
    func encodePretty<T: Encodable>(_ value: T) throws -> Data {
        outputFormatting = [.prettyPrinted]
        return try encode(value)
    }
}
