import Foundation

/// Modern Vietnamese lunisolar calendar, with astronomical days resolved at UTC+7.
/// Dates before 1968 are proleptic; regional historical calendars are not modeled.
public enum VietnameseLunarCalendar {
    public struct LunarDate: Equatable, Sendable {
        public let day: Int
        public let month: Int
        public let year: Int
        public let isLeapMonth: Bool

        public var yearName: String { Self.cycle(stem: year + 6, branch: year + 8) }
        public var monthName: String {
            Self.cycle(stem: year * 12 + month + 3, branch: month + 1)
        }

        fileprivate static func cycle(stem: Int, branch: Int) -> String {
            let stems = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
            let branches = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]
            return stems[stem % 10] + " " + branches[branch % 12]
        }
    }

    public static func convert(_ date: Date, calendar: Calendar = .gregorian) -> LunarDate {
        let parts = calendar.dateComponents([.day, .month, .year], from: date)
        return convert(day: parts.day!, month: parts.month!, year: parts.year!)
    }

    /// The input is a Gregorian civil date; the lunar calendar always uses UTC+7.
    public static func convert(day: Int, month: Int, year: Int) -> LunarDate {
        let jd = julianDay(day: day, month: month, year: year)
        var moon = Int(floor((Double(jd) - epoch) / synodicMonth))
        while newMoonDay(moon) > jd { moon -= 1 }
        while newMoonDay(moon + 1) <= jd { moon += 1 }

        var anchorYear = year
        var first = monthEleven(year)
        if jd < newMoonDay(first) {
            anchorYear -= 1
            first = monthEleven(anchorYear)
        }
        let next = monthEleven(anchorYear + 1)
        let index = moon - first
        var ordinal = 11 + index
        var leap = false
        if next - first == 13 {
            // The first month without a major solar term repeats the prior month.
            let leapIndex = (1..<13).first {
                solarSector(newMoonDay(first + $0)) == solarSector(newMoonDay(first + $0 + 1))
            } ?? 12
            if index >= leapIndex { ordinal -= 1 }
            leap = index == leapIndex
        }
        return LunarDate(
            day: jd - newMoonDay(moon) + 1,
            month: (ordinal - 1) % 12 + 1,
            year: anchorYear + (ordinal >= 13 ? 1 : 0),
            isLeapMonth: leap
        )
    }

    public static func dayName(_ date: Date, calendar: Calendar = .gregorian) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        let jd = julianDay(day: c.day!, month: c.month!, year: c.year!)
        return LunarDate.cycle(stem: jd + 9, branch: jd + 1)
    }

    private static let epoch = 2451550.09766
    private static let synodicMonth = 29.530588861

    private static func julianDay(day: Int, month: Int, year: Int) -> Int {
        let a = (14 - month) / 12
        let y = year + 4800 - a
        let m = month + 12 * a - 3
        return day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045
    }

    private static func monthEleven(_ year: Int) -> Int {
        let end = julianDay(day: 31, month: 12, year: year)
        var k = Int(floor((Double(end) - epoch) / synodicMonth))
        while newMoonDay(k) > end { k -= 1 }
        while newMoonDay(k + 1) <= end { k += 1 }
        if solarSector(newMoonDay(k)) >= 9 { k -= 1 }
        return k
    }

    private static func solarSector(_ day: Int) -> Int {
        let t = (Double(day) - 0.5 - 7.0 / 24 - 2451545) / 36525
        let anomaly = (357.52911 + 35999.05029 * t - 0.0001537 * t * t) * .pi / 180
        let mean = 280.46646 + 36000.76983 * t + 0.0003032 * t * t
        let correction = (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(anomaly)
            + (0.019993 - 0.000101 * t) * sin(2 * anomaly) + 0.000289 * sin(3 * anomaly)
        let longitude = (mean + correction).truncatingRemainder(dividingBy: 360)
        return Int(floor((longitude + 360).truncatingRemainder(dividingBy: 360) / 30))
    }

    private static func newMoonDay(_ lunation: Int) -> Int {
        let k = Double(lunation)
        let t = k / 1236.85
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        let r = Double.pi / 180
        let e = 1 - 0.002516 * t - 0.0000074 * t2
        let m = (2.5534 + 29.1053567 * k - 0.0000014 * t2 - 0.00000011 * t3) * r
        let p = (201.5643 + 385.81693528 * k + 0.0107582 * t2 + 0.00001238 * t3 - 0.000000058 * t4) * r
        let f = (160.7108 + 390.67050284 * k - 0.0016118 * t2 - 0.00000227 * t3 + 0.000000011 * t4) * r
        let omega = (124.7746 - 1.56375588 * k + 0.0020672 * t2 + 0.00000215 * t3) * r

        // Meeus, chapter 49. Swift adaptation of MIT-licensed astronomia/moonphase.
        // Copyright (c) 2013 Sonia Keys; (c) 2016 Commenthol. See THIRD_PARTY_NOTICES.md.
        let terms: [(Double, Double)] = [
            (-0.40720, sin(p)), (0.17241, e * sin(m)), (0.01608, sin(2 * p)),
            (0.01039, sin(2 * f)), (0.00739, e * sin(p - m)), (-0.00514, e * sin(p + m)),
            (0.00208, e * e * sin(2 * m)), (-0.00111, sin(p - 2 * f)), (-0.00057, sin(p + 2 * f)),
            (0.00056, e * sin(2 * p + m)), (-0.00042, sin(3 * p)), (0.00042, e * sin(m + 2 * f)),
            (0.00038, e * sin(m - 2 * f)), (-0.00024, e * sin(2 * p - m)), (-0.00017, sin(omega)),
            (-0.00007, sin(p + 2 * m)), (0.00004, sin(2 * (p - f))), (0.00004, sin(3 * m)),
            (0.00003, sin(p + m - 2 * f)), (0.00003, sin(2 * (p + f))),
            (-0.00003, sin(p + m + 2 * f)), (0.00003, sin(p - m + 2 * f)),
            (-0.00002, sin(p - m - 2 * f)), (-0.00002, sin(3 * p + m)), (0.00002, sin(4 * p))
        ]
        let planetary: [(Double, Double)] = [
            (0.000325, 299.77 + 0.107408 * k - 0.009173 * t2),
            (0.000165, 251.88 + 0.016321 * k), (0.000164, 251.83 + 26.651886 * k),
            (0.000126, 349.42 + 36.412478 * k), (0.000110, 84.66 + 18.206239 * k),
            (0.000062, 141.74 + 53.303771 * k), (0.000060, 207.14 + 2.453732 * k),
            (0.000056, 154.84 + 7.306860 * k), (0.000047, 34.52 + 27.261239 * k),
            (0.000042, 207.19 + 0.121824 * k), (0.000040, 291.34 + 1.844379 * k),
            (0.000037, 161.72 + 24.198154 * k), (0.000035, 239.56 + 25.513099 * k),
            (0.000023, 331.55 + 3.592518 * k)
        ]
        let corrections = terms.reduce(0) { $0 + $1.0 * $1.1 }
            + planetary.reduce(0) { $0 + $1.0 * sin($1.1 * r) }
        let jde = epoch + synodicMonth * k + 0.00015437 * t2 - 0.00000015 * t3 + 0.00000000073 * t4 + corrections
        let approximateYear = 2000 + k / 12.3685
        let utc = jde - deltaT(approximateYear) / 86400
        return Int(floor(utc + 0.5 + 7.0 / 24))
    }

    /// NASA/Espenak–Meeus polynomial approximations: TT − UT in seconds.
    private static func deltaT(_ year: Double) -> Double {
        let t: Double
        switch year {
        case ..<1920:
            t = year - 1900
            return polynomial(t, [-2.79, 1.494119, -0.0598939, 0.0061966, -0.000197])
        case ..<1941:
            t = year - 1920
            return polynomial(t, [21.20, 0.84493, -0.076100, 0.0020936])
        case ..<1961:
            t = year - 1950
            return polynomial(t, [29.07, 0.407, -1 / 233.0, 1 / 2547.0])
        case ..<1986:
            t = year - 1975
            return polynomial(t, [45.45, 1.067, -1 / 260.0, -1 / 718.0])
        case ..<2005:
            t = year - 2000
            return polynomial(t, [63.86, 0.3345, -0.060374, 0.0017275, 0.000651814, 0.00002373599])
        case ..<2050:
            t = year - 2000
            return polynomial(t, [62.92, 0.32217, 0.005589])
        default:
            t = (year - 1820) / 100
            return -20 + 32 * t * t - 0.5628 * (2150 - year)
        }
    }

    private static func polynomial(_ x: Double, _ coefficients: [Double]) -> Double {
        coefficients.reversed().reduce(0) { $0 * x + $1 }
    }
}
