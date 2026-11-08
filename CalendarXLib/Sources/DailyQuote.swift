import Foundation

public struct DailyQuote: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let text: String
    public let author: String
    public let sourceURL: URL

    public init(id: String, text: String, author: String, sourceURL: URL) {
        self.id = id
        self.text = text
        self.author = author
        self.sourceURL = sourceURL
    }
}

/// A stable permutation shared by the app, widgets and future timeline entries.
/// No process-random Hasher or runtime random choice is used to select a daily quote.
public struct QuoteDeck: Sendable {
    public let quotes: [DailyQuote]
    private let order: [Int]

    public init(quotes: [DailyQuote], seed: UInt64 = 0xA11C_2026_5A17_9EED) {
        precondition(!quotes.isEmpty, "A quote deck needs at least one quote")
        self.quotes = quotes
        var order = Array(quotes.indices)
        var random = SeededRandom(state: seed)
        if order.count > 1 {
            for index in stride(from: order.count - 1, through: 1, by: -1) {
                let other = Int(random.next() % UInt64(index + 1))
                order.swapAt(index, other)
            }
        }
        self.order = order
    }

    public func quote(dayOffset: Int, advance: Int = 0) -> DailyQuote {
        func positiveRemainder(_ value: Int) -> Int {
            let remainder = value % order.count
            return remainder >= 0 ? remainder : remainder + order.count
        }
        let index = (positiveRemainder(dayOffset) + positiveRemainder(advance)) % order.count
        return quotes[order[index]]
    }

    /// Calendar days, rather than seconds/86400, preserve midnight boundaries across DST.
    public static func dayOffset(for date: Date, calendar: Calendar = .gregorian) -> Int {
        let epoch = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        return calendar.dateComponents([.day], from: epoch, to: calendar.startOfDay(for: date)).day ?? 0
    }
}

private struct SeededRandom {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

@MainActor
public enum DailyQuoteStore {
    public static let advanceKey = "AmLich.quotes.advance.v1"

    public static let quotes: [DailyQuote] = {
        struct Catalog: Decodable { let quotes: [DailyQuote] }
        if let url = Bundle.module.url(forResource: "daily_quotes", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let catalog = try? JSONDecoder().decode(Catalog.self, from: data),
            !catalog.quotes.isEmpty {
            return catalog.quotes
        }
        return [DailyQuote(
            id: "fallback-proverb",
            text: "Có công mài sắt, có ngày nên kim.",
            author: "Tục ngữ Việt Nam",
            sourceURL: URL(string: "https://vi.wikiquote.org/wiki/T%E1%BB%A5c_ng%E1%BB%AF_Vi%E1%BB%87t_Nam")!
        )]
    }()

    private static let deck = QuoteDeck(quotes: quotes)

    public static func quote(for date: Date, calendar: Calendar = .gregorian, advance: Int? = nil) -> DailyQuote {
        let settings = UserDefaults.group ?? .standard
        return deck.quote(
            dayOffset: QuoteDeck.dayOffset(for: date, calendar: calendar),
            advance: advance ?? settings.integer(forKey: advanceKey)
        )
    }

    /// Advance the shared deck. Future daily choices move forward with it.
    @discardableResult
    public static func shuffle(defaults: UserDefaults? = nil) -> Int {
        let settings = defaults ?? UserDefaults.group ?? .standard
        let previous = settings.integer(forKey: advanceKey) % quotes.count
        let next = (previous + 1 + quotes.count) % quotes.count
        settings.set(next, forKey: advanceKey)
        return next
    }
}
