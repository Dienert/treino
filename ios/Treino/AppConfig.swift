import Foundation

/// Identificadores compartilhados entre o app e o widget.
/// Se você trocar o bundle id, atualize também o App Group aqui e nos dois
/// arquivos `.entitlements`, além do painel Signing & Capabilities no Xcode.
enum AppConfig {
    static let appGroup = "group.com.dienert.treino"
}
