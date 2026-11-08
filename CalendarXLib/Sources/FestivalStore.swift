import Foundation

@MainActor
public enum Tiaoxiu: Int, Decodable {
    case ordinary, ban, xiu
    public var isOrdinary: Bool { self == .ordinary }
    public var isXiu: Bool { self == .xiu }
    public var description: String { self == .xiu ? "•" : "" }
}

/// Vietnamese cultural festivals, not government workday/substitute-day schedules.
@MainActor
public struct FestivalStore {
    private static let lunarFestivals = [
        "0101": "Tết Nguyên đán", "0102": "Mùng 2 Tết", "0103": "Mùng 3 Tết",
        "0115": "Tết Nguyên tiêu", "0310": "Giỗ Tổ Hùng Vương", "0415": "Lễ Phật Đản",
        "0505": "Tết Đoan ngọ", "0715": "Lễ Vu Lan", "0815": "Tết Trung thu",
        "0909": "Tết Trùng cửu", "1223": "Ông Công Ông Táo"
    ]
    private static let solarFestivals = [
        "0101": "Tết Dương lịch", "0214": "Lễ Tình nhân", "0308": "Quốc tế Phụ nữ",
        "0430": "Ngày Thống nhất", "0501": "Quốc tế Lao động", "0601": "Quốc tế Thiếu nhi",
        "0902": "Quốc khánh", "1020": "Phụ nữ Việt Nam", "1120": "Nhà giáo Việt Nam",
        "1225": "Giáng sinh"
    ]

    public nonisolated init() {}

    public func all(date: AppDate) -> [String] {
        var result: [String] = []
        if let festival = lunar(date: date) { result.append(festival) }
        if let festival = Self.solarFestivals[date.sMDKey] { result.append(festival) }
        if date.lunarDay == 1 { result.append("Mùng 1") }
        if date.lunarDay == 15 { result.append("Ngày rằm") }
        return result
    }

    public func display(date: AppDate) -> String { date.lunarDayTitle }

    public func tiaoxiu(date: AppDate) -> Tiaoxiu {
        lunar(date: date) != nil || Self.solarFestivals[date.sMDKey] != nil ? .xiu : .ordinary
    }

    private func lunar(date: AppDate) -> String? {
        guard !date.isLeapMonth else { return nil }
        if date.lunarMonth == 12, date.tomorrow.lunarMonth == 1, date.tomorrow.lunarDay == 1 {
            return "Giao thừa"
        }
        return Self.lunarFestivals[date.lMDKey]
    }
}
