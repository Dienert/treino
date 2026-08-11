import Foundation

/// Datas em texto ISO `yyyy-MM-dd`, no fuso local — igual ao site.
enum DateUtils {
    static let iso: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static let months = ["jan","fev","mar","abr","mai","jun","jul","ago","set","out","nov","dez"]
    static let week = ["dom","seg","ter","qua","qui","sex","sáb"]

    static func todayISO() -> String { iso.string(from: Date()) }

    static func date(from isoStr: String) -> Date {
        iso.date(from: isoStr) ?? Date()
    }

    /// "seg, 11 ago"
    static func fmtDate(_ isoStr: String) -> String {
        guard let d = iso.date(from: isoStr) else { return isoStr }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let comps = cal.dateComponents([.year, .month, .day, .weekday], from: d)
        let wd = (comps.weekday ?? 1) - 1
        return "\(week[wd]), \(comps.day ?? 0) \(months[(comps.month ?? 1) - 1])"
    }

    /// "hoje", "ontem", "há 3 dias", … (idêntico ao `relDate` do site).
    static func relDate(_ isoStr: String) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let today = cal.startOfDay(for: Date())
        let d = cal.startOfDay(for: date(from: isoStr))
        let days = cal.dateComponents([.day], from: d, to: today).day ?? 0
        if days == 0 { return "hoje" }
        if days == 1 { return "ontem" }
        if days == -1 { return "amanhã" }
        if days < 0 { return fmtDate(isoStr) }
        if days < 7 { return "há \(days) dias" }
        if days < 14 { return "há 1 semana" }
        if days < 60 { return "há \(days / 7) semanas" }
        return "há \(days / 30) meses"
    }

    /// Carga guardada com ponto; mostrada com vírgula.
    static func fmtLoad(_ v: String) -> String { v.replacingOccurrences(of: ".", with: ",") }
}
