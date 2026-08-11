import Foundation

/// Plano de treino — mexa aqui para mudar os exercícios.
/// NUNCA troque o `id` de um exercício existente: ele é a chave do histórico
/// e o registro antigo se perde. (Idêntico à constante `PESSOAS` do site.)
enum Plans {
    static let pessoas: [Pessoa] = [
        Pessoa(id: "dienert", nome: "Diénert", planos: [
            Plano(letter: "A", short: "Peito · Tríceps", ex: [
                Exercise(id: "a1", name: "Aquecimento manguito rotador (elástico)", sets: 2, reps: "15", bw: true),
                Exercise(id: "a2", name: "Supino reto halteres pegada neutra",      sets: 3, reps: "12"),
                Exercise(id: "a3", name: "Crucifixo máquina",                        sets: 3, reps: "12"),
                Exercise(id: "a4", name: "Elevação lateral halteres leves",          sets: 3, reps: "15"),
                Exercise(id: "a5", name: "Tríceps polia com corda",                  sets: 3, reps: "12"),
                Exercise(id: "a6", name: "Tríceps unilateral na polia",              sets: 3, reps: "15"),
                Exercise(id: "a7", name: "Prancha",                                  sets: 3, reps: "30", unit: "s", bw: true),
            ]),
            Plano(letter: "B", short: "Costas · Bíceps", ex: [
                Exercise(id: "b1", name: "Puxada frontal (pegada supinada)", sets: 3, reps: "12"),
                Exercise(id: "b2", name: "Remada baixa máquina",             sets: 3, reps: "12"),
                Exercise(id: "b3", name: "Face pull com corda (leve)",       sets: 3, reps: "15"),
                Exercise(id: "b4", name: "Rosca direta barra W",             sets: 3, reps: "12"),
                Exercise(id: "b5", name: "Rosca martelo",                    sets: 3, reps: "12"),
                Exercise(id: "b6", name: "Abdominal supra",                  sets: 3, reps: "15", bw: true),
            ]),
            Plano(letter: "C", short: "Pernas", ex: [
                Exercise(id: "c1", name: "Leg press",                         sets: 4, reps: "12"),
                Exercise(id: "c2", name: "Cadeira extensora",                 sets: 3, reps: "15"),
                Exercise(id: "c3", name: "Cadeira flexora",                   sets: 3, reps: "12"),
                Exercise(id: "c4", name: "Agachamento livre (peso corporal)", sets: 3, reps: "20", bw: true),
                Exercise(id: "c5", name: "Abdutora",                          sets: 3, reps: "20"),
                Exercise(id: "c6", name: "Adutora",                           sets: 3, reps: "15"),
                Exercise(id: "c7", name: "Panturrilha em pé",                 sets: 4, reps: "20"),
                Exercise(id: "c8", name: "Abdominal infra",                   sets: 3, reps: "15", bw: true),
            ]),
        ]),

        Pessoa(id: "cida", nome: "Cida", planos: [
            Plano(letter: "A", short: "Quadríceps", ex: [
                Exercise(id: "ca1", name: "Agachamento com halteres",  sets: 3, reps: "10–12"),
                Exercise(id: "ca2", name: "Leg press",                 sets: 3, reps: "12"),
                Exercise(id: "ca3", name: "Cadeira extensora",         sets: 3, reps: "15"),
                Exercise(id: "ca4", name: "Afundo livre (cada perna)", sets: 3, reps: "10"),
                Exercise(id: "ca5", name: "Cadeira abdutora",          sets: 3, reps: "15–20"),
                Exercise(id: "ca6", name: "Panturrilha em pé",         sets: 4, reps: "15"),
            ]),
            Plano(letter: "B", short: "Costas", ex: [
                Exercise(id: "cb1", name: "Puxada frente na polia",       sets: 3, reps: "10–12"),
                Exercise(id: "cb2", name: "Remada baixa",                 sets: 3, reps: "12"),
                Exercise(id: "cb3", name: "Remada articulada",            sets: 3, reps: "10"),
                Exercise(id: "cb4", name: "Rosca direta na barra",        sets: 3, reps: "12"),
                Exercise(id: "cb5", name: "Rosca alternada com halteres", sets: 3, reps: "12"),
                Exercise(id: "cb6", name: "Prancha",                      sets: 3, reps: "30–45", unit: "s", bw: true),
            ]),
            Plano(letter: "C", short: "Posterior", ex: [
                Exercise(id: "cc1", name: "Cadeira flexora",               sets: 3, reps: "12"),
                Exercise(id: "cc2", name: "Stiff com halteres",            sets: 3, reps: "10"),
                Exercise(id: "cc3", name: "Elevação pélvica (hip thrust)", sets: 4, reps: "10–12"),
                Exercise(id: "cc4", name: "Glúteo na polia (cada perna)",  sets: 3, reps: "15"),
                Exercise(id: "cc5", name: "Abdutora",                      sets: 3, reps: "20"),
                Exercise(id: "cc6", name: "Panturrilha no leg",            sets: 4, reps: "15"),
            ]),
            Plano(letter: "D", short: "Peito · Ombro", ex: [
                Exercise(id: "cd1", name: "Supino máquina",             sets: 3, reps: "12"),
                Exercise(id: "cd2", name: "Crucifixo máquina",          sets: 3, reps: "15"),
                Exercise(id: "cd3", name: "Desenvolvimento",            sets: 3, reps: "10–12"),
                Exercise(id: "cd4", name: "Elevação lateral",           sets: 3, reps: "15"),
                Exercise(id: "cd5", name: "Tríceps corda",              sets: 3, reps: "12"),
                Exercise(id: "cd6", name: "Tríceps francês com halter", sets: 3, reps: "12"),
            ]),
        ]),
    ]

    static func pessoa(_ id: String) -> Pessoa {
        pessoas.first { $0.id == id } ?? pessoas[0]
    }

    /// Todos os exercícios de todo mundo, indexados por id (único entre pessoas).
    static let exById: [String: Exercise] = {
        var m: [String: Exercise] = [:]
        for p in pessoas { for t in p.planos { for e in t.ex { m[e.id] = e } } }
        return m
    }()
}
