//
//  Models.swift
//  TableReady
//

import Foundation

// MARK: - Menu Effort

enum MenuEffort: String, CaseIterable {
    case light = "Light"
    case medium = "Medium"
    case heavy = "Heavy"

    var icon: String {
        switch self {
        case .light: return "leaf.fill"
        case .medium: return "flame.fill"
        case .heavy: return "frying.pan.fill"
        }
    }
}

// MARK: - Menu Item

/// One dish within a DayMenu, tagged with its category (curry, bread,
/// rice, etc.) so a day's menu can be edited one category at a time
/// instead of as one flat list. `quantity` is mainly meaningful for
/// bread items (e.g. "10 chapathis") — nil just means "one of these".
struct MenuItem: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var category: DishCategory
    var quantity: Int?

    init(id: UUID = UUID(), name: String, category: DishCategory? = nil, quantity: Int? = nil) {
        self.id = id
        self.name = name
        self.category = category ?? DishCategory.categorize(name)
        self.quantity = quantity
    }

    /// Splits raw free-text menu item strings (as typed in Quick Menu, or
    /// parsed from markdown/older saved data) into structured MenuItems.
    /// Only splits on "&" (e.g. "10 chapathis & 3 parathas") — never on
    /// "and", since that word shows up inside ordinary dish descriptions
    /// (e.g. "garlic / ginger and pepper") and splitting there would break
    /// a single dish into nonsense fragments.
    static func parseItems(from rawText: String) -> [MenuItem] {
        rawText.components(separatedBy: "&").compactMap { segment in
            let trimmed = segment.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            let (quantity, name) = extractLeadingQuantity(trimmed)
            guard !name.isEmpty else { return nil }
            return MenuItem(name: name, quantity: quantity)
        }
    }

    /// Extracts a leading quantity phrase ("5 ", "1 batch of ", "5-6 ")
    /// from raw item text, returning the number and the remaining name.
    private static func extractLeadingQuantity(_ text: String) -> (Int?, String) {
        let pattern = #"^(\d+)(-\d+)?\s+(batch(es)?\s+of\s+)?"#
        guard let range = text.range(of: pattern, options: .regularExpression) else {
            return (nil, text)
        }
        let digits = text[range].prefix(while: \.isNumber)
        var name = text
        name.removeSubrange(range)
        return (Int(digits), name.trimmingCharacters(in: .whitespaces))
    }

    /// Migrates old-format menu data (a flat list of raw item strings plus
    /// a separate bread count) into structured items. Parses each raw
    /// string via `parseItems`, then reconciles the total against the old
    /// bread count: if free-text parsing didn't capture enough bread
    /// quantity (e.g. "Soya kadhi pakoda - 7 chapathis" has its quantity
    /// embedded mid-sentence, not at the start), a generic "Bread" item
    /// makes up the shortfall so effort calculation stays accurate.
    static func migrating(rawItems: [String], targetBreadCount: Int) -> [MenuItem] {
        var items = rawItems.flatMap { parseItems(from: $0) }
        let parsedBreadCount = items.filter { $0.category == .bread }.reduce(0) { $0 + ($1.quantity ?? 1) }
        let shortfall = targetBreadCount - parsedBreadCount
        if shortfall > 0 {
            items.append(MenuItem(name: "Bread", category: .bread, quantity: shortfall))
        }
        return items
    }
}

// MARK: - Menu

struct DayMenu: Identifiable, Codable {
    var id: Int
    var items: [MenuItem]
    var chaiCount: Int

    init(id: Int, items: [MenuItem], chaiCount: Int) {
        self.id = id
        self.items = items
        self.chaiCount = chaiCount
    }

    /// Total bread quantity, derived from bread-category items instead of
    /// being tracked as a separate number — so bread is just another
    /// swappable slot like curry or the lunch item.
    var breadCount: Int {
        items.filter { $0.category == .bread }.reduce(0) { $0 + ($1.quantity ?? 1) }
    }

    func items(in category: DishCategory) -> [MenuItem] {
        items.filter { $0.category == category }
    }

    /// Effort is computed from bread count (chapathis + parathas + theplas).
    /// Deep-frying (pakoda, manchurian, egg rolls) nudges a borderline menu up.
    ///   0–6 breads  → light
    ///   7–10 breads → medium
    ///   11+ breads  → heavy
    var effort: MenuEffort {
        let hasDeepFrying = items.contains { item in
            let lower = item.name.lowercased()
            return lower.contains("pakod")
                || lower.contains("manchurian")
                || lower.contains("egg roll")
                || lower.contains("vada")
                || lower.contains("bhaji")
        }

        switch breadCount {
        case 0...6:
            return hasDeepFrying && breadCount >= 5 ? .medium : .light
        case 7...10:
            return hasDeepFrying && breadCount >= 9 ? .heavy : .medium
        default:
            return .heavy
        }
    }

    // MARK: Codable (migrates the old {breadCount: Int, items: [String]} shape)

    private enum CodingKeys: String, CodingKey {
        case id, items, chaiCount, breadCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        chaiCount = try container.decode(Int.self, forKey: .chaiCount)

        if let structuredItems = try? container.decode([MenuItem].self, forKey: .items) {
            items = structuredItems
        } else {
            let rawItems = try container.decodeIfPresent([String].self, forKey: .items) ?? []
            let oldBreadCount = try container.decodeIfPresent(Int.self, forKey: .breadCount) ?? 0
            items = MenuItem.migrating(rawItems: rawItems, targetBreadCount: oldBreadCount)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(items, forKey: .items)
        try container.encode(chaiCount, forKey: .chaiCount)
    }
}

// MARK: - Day Plan

struct DayPlan: Identifiable, Codable {
    let id: UUID
    var dayOfWeek: DayOfWeek
    var menu: DayMenu?

    init(id: UUID = UUID(), dayOfWeek: DayOfWeek, menu: DayMenu? = nil) {
        self.id = id
        self.dayOfWeek = dayOfWeek
        self.menu = menu
    }
}

// MARK: - Day of Week

enum DayOfWeek: Int, CaseIterable, Identifiable, Codable {
    case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    var shortName: String {
        String(name.prefix(3))
    }
}

// MARK: - Dish Category

enum DishCategory: String, Codable, CaseIterable, Identifiable {
    case curry, bread, rice, snack, drink, side

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .curry: return "cup.and.saucer.fill"
        case .bread: return "circle.grid.cross.fill"
        case .rice: return "bowl.fill"
        case .snack: return "flame.fill"
        case .drink: return "mug.fill"
        case .side: return "leaf.fill"
        }
    }

    /// Auto-detect category from a dish name using keyword matching
    static func categorize(_ name: String) -> DishCategory {
        let lower = name.lowercased()
        if lower.contains("chapathi") || lower.contains("paratha") || lower.contains("roti")
            || lower.contains("thepla") || lower.contains("cheela") || lower.contains("naan") {
            return .bread
        }
        if lower.contains("rice") || lower.contains("khichdi") || lower.contains("biryani")
            || lower.contains("poha") || lower.contains("pulao") {
            return .rice
        }
        if lower.contains("chai") || lower.contains("tea") || lower.contains("coffee")
            || lower.contains("lassi") || lower.contains("pani") {
            return .drink
        }
        if lower.contains("manchurian") || lower.contains("pakod") || lower.contains("roll")
            || lower.contains("sandwich") || lower.contains("paddu") || lower.contains("muthiya")
            || lower.contains("puri") {
            return .snack
        }
        if lower.contains("salad") || lower.contains("raita") || lower.contains("chutney")
            || lower.contains("dip") || lower.contains("pickle") {
            return .side
        }
        // Default: curry covers dal, paneer, sabzi, gravy dishes, etc.
        return .curry
    }
}

// MARK: - Dish

struct Dish: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var category: DishCategory

    init(id: UUID = UUID(), name: String, category: DishCategory? = nil) {
        self.id = id
        self.name = name
        self.category = category ?? DishCategory.categorize(name)
    }

    /// Strips a leading quantity phrase (e.g. "5 ", "1 batch of ", "5-6 ")
    /// so raw menu item text like "5 parathas" becomes a reusable dish
    /// name like "parathas" for the Dish Library.
    static func cleanedName(from rawItem: String) -> String {
        var name = rawItem.trimmingCharacters(in: .whitespaces)
        let pattern = #"^\d+(-\d+)?\s+(batch(es)?\s+of\s+)?"#
        if let range = name.range(of: pattern, options: .regularExpression) {
            name.removeSubrange(range)
        }
        return name.trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Family Member

struct FamilyMember: Identifiable, Codable {
    let id: UUID
    var name: String
    var emoji: String
    var dietaryNotes: String

    init(id: UUID = UUID(), name: String, emoji: String = "🧑", dietaryNotes: String = "") {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.dietaryNotes = dietaryNotes
    }
}

// MARK: - Grocery Item

struct GroceryItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var isPurchased: Bool
    var fromMenu: String

    init(id: UUID = UUID(), name: String, isPurchased: Bool = false, fromMenu: String = "") {
        self.id = id
        self.name = name
        self.isPurchased = isPurchased
        self.fromMenu = fromMenu
    }
}

// MARK: - Markdown Parser

struct MenuParser {
    /// Parses a markdown string with the format:
    /// ## <id> | <effort> — <count> breads
    /// - item 1
    /// - item 2
    /// - N chais
    ///
    /// Effort is NOT read from the header — it is auto-computed by DayMenu
    /// from bread count and deep-frying detection.
    static func parse(_ markdown: String) -> [DayMenu] {
        var menus: [DayMenu] = []
        let lines = markdown.components(separatedBy: "\n")
        var currentID: Int?
        var currentBreadCount = 0
        var currentItems: [String] = []
        var currentChaiCount = 0

        func saveCurrentMenu() {
            guard let id = currentID else { return }
            menus.append(DayMenu(
                id: id,
                items: MenuItem.migrating(rawItems: currentItems, targetBreadCount: currentBreadCount),
                chaiCount: currentChaiCount
            ))
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Match menu headers like: ## 1 | light — 5 breads
            if trimmed.hasPrefix("## ") && trimmed.contains("|") {
                saveCurrentMenu()

                // Parse new header
                let afterHash = trimmed.dropFirst(3)
                let parts = afterHash.components(separatedBy: "|")
                guard parts.count >= 2 else { continue }

                currentID = Int(parts[0].trimmingCharacters(in: .whitespaces))
                let effortPart = parts[1].lowercased()

                // Extract bread count from the header
                let numberPattern = /(\d+)\s*breads?/
                if let match = effortPart.firstMatch(of: numberPattern) {
                    currentBreadCount = Int(match.1) ?? 0
                } else {
                    currentBreadCount = 0
                }

                currentItems = []
                currentChaiCount = 0

            } else if trimmed.hasPrefix("- "), currentID != nil {
                let item = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                // Separate chai lines from food items
                let lower = item.lowercased()
                if lower.contains("chai") {
                    let chaiPattern = /(\d+)\s*chais?/
                    if let match = lower.firstMatch(of: chaiPattern) {
                        currentChaiCount = Int(match.1) ?? 2
                    }
                } else if !item.isEmpty {
                    currentItems.append(item)
                }

            } else if trimmed == "---" && currentID != nil {
                // End marker — save current menu
                saveCurrentMenu()
                currentID = nil
                currentItems = []
            }
        }

        // Save last menu if file doesn't end with ---
        saveCurrentMenu()

        return menus
    }
}

// MARK: - Sample Data

struct SampleData {

    static let sampleMarkdown = """
    ## 1 | light — 5 breads

    - Gobi manchurian / Street side fried rice
    - Mushroom pepper fry
    - 5 parathas
    - 2 chais

    ## 2 | heavy — 15 breads

    - Dal khichdi with garlic / ginger and pepper
    - Rice bowl using black, pinto, 1/2 cup rice, avocado, jalapeño
    - 10 chapathis palak paneer for dinner
    - 5 parathas
    - 2 chais

    ## 3 | light — 6 breads

    - Sprouted Misal (green) gravy with veggies
    - Cheela with grated paneer and carrot
    - 6 parathas
    - 5-6 vertical long tofu marinated and toasted
    - 2 chais

    ## 4 | heavy — 13 breads

    - 1 batch of rava paddu with veggies
    - Mushroom/Paneer tikka curry with mild cashews
    - 10 chapathis & 3 parathas
    - 2 chais

    ## 5 | medium — 10 breads

    - Dal makhani
    - 10 chapathis
    - Pani for pani puri (we have pineapple cut and kiwis)
    - Rava paddus
    - 2 chais

    ## 6 | medium — 7 breads

    - 4 hot moong cheelas with veggies
    - Soya kadhi pakoda - 7 chapathis
    - 2 chais

    ## 7 | heavy — 12 breads

    - Bottlegourd muthiya
    - Palak paneer
    - 12 chapathis
    - 2 chais
    """

    static let menus: [DayMenu] = MenuParser.parse(sampleMarkdown)

    static let weeklyPlan: [DayPlan] = {
        let days = DayOfWeek.allCases
        return days.enumerated().map { index, day in
            let menu = index < menus.count ? menus[index] : nil
            return DayPlan(dayOfWeek: day, menu: menu)
        }
    }()

    static let familyMembers: [FamilyMember] = [
        FamilyMember(name: "Mom", emoji: "👩", dietaryNotes: "No shellfish"),
        FamilyMember(name: "Dad", emoji: "👨", dietaryNotes: ""),
        FamilyMember(name: "Emma", emoji: "👧", dietaryNotes: "Picky with veggies"),
        FamilyMember(name: "Liam", emoji: "👦", dietaryNotes: "Nut allergy"),
    ]

    static var groceryItems: [GroceryItem] {
        var items: [GroceryItem] = []
        var seen = Set<String>()
        for day in weeklyPlan {
            guard let menu = day.menu else { continue }
            for item in menu.items {
                let key = item.name.lowercased()
                if !seen.contains(key) {
                    seen.insert(key)
                    items.append(GroceryItem(name: item.name, fromMenu: "Menu #\(menu.id)"))
                }
            }
        }
        return items
    }
}
