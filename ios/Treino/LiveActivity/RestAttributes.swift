import Foundation
import ActivityKit

/// Estado da Live Activity do descanso — compartilhado entre o app e o widget.
/// (Arquivo é membro dos DOIS alvos no Xcode.)
struct RestAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Quando o descanso termina — a contagem na Dynamic Island usa esta data.
        var endDate: Date
        /// Duração total escolhida, para desenhar a barra de progresso.
        var total: TimeInterval
        /// "Supino reto · série 2" — a próxima série pendente.
        var nextLabel: String
    }

    /// "Diénert", "Cida" — fixo durante o descanso.
    var pessoaNome: String
    /// Letra do treino em andamento.
    var workout: String
}
