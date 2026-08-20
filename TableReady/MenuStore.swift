//
//  MenuStore.swift
//  TableReady
//

import Foundation

@Observable
class MenuStore {

    // MARK: - State

    var menus: [DayMenu] = []
    var weeklyPlan: [DayPlan] = []

    // MARK: - Paths

    private let mdFilePath = "/Users/ramyakailas/Downloads/menus-editable.md"

    private var jsonFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("menuStore.json")
    }

    // MARK: - Persistence Model

    private struct StoreData: Codable {
        var menus: [DayMenu]
        var weeklyPlan: [DayPlan]
    }

    // MARK: - Initialization

    init() {
        loadData()
    }

    /// Convenience init for previews with sample data
    init(sampleData: Bool) {
        if sampleData {
            menus = SampleData.menus
            weeklyPlan = SampleData.weeklyPlan
        } else {
            loadData()
        }
    }

    // MARK: - Loading

    private func loadData() {
        if let data = try? Data(contentsOf: jsonFileURL),
           let stored = try? JSONDecoder().decode(StoreData.self, from: data) {
            menus = stored.menus
            weeklyPlan = stored.weeklyPlan
        } else {
            seedFromMarkdown()
        }
    }

    private func seedFromMarkdown() {
        let loaded = MenuParser.loadFromFile(at: mdFilePath)
        menus = loaded

        let days = DayOfWeek.allCases
        weeklyPlan = days.enumerated().map { index, day in
            let menu = index < loaded.count ? loaded[index] : nil
            return DayPlan(dayOfWeek: day, menu: menu)
        }
        save()
    }

    // MARK: - Saving

    private func save() {
        let storeData = StoreData(menus: menus, weeklyPlan: weeklyPlan)
        if let data = try? JSONEncoder().encode(storeData) {
            try? data.write(to: jsonFileURL, options: .atomic)
        }
    }

    // MARK: - Next Available ID

    var nextMenuID: Int {
        (menus.map(\.id).max() ?? 0) + 1
    }

    // MARK: - Menu Operations

    func addMenu(_ menu: DayMenu, assignToDay day: DayOfWeek? = nil) {
        menus.append(menu)
        if let day {
            assignMenuByID(menu.id, toDay: day)
        }
        save()
    }

    func assignMenu(_ menu: DayMenu, toDay day: DayOfWeek) {
        if let index = weeklyPlan.firstIndex(where: { $0.dayOfWeek == day }) {
            weeklyPlan[index].menu = menu
        }
        save()
    }

    func clearDay(_ day: DayOfWeek) {
        if let index = weeklyPlan.firstIndex(where: { $0.dayOfWeek == day }) {
            weeklyPlan[index].menu = nil
        }
        save()
    }

    private func assignMenuByID(_ menuID: Int, toDay day: DayOfWeek) {
        guard let menu = menus.first(where: { $0.id == menuID }) else { return }
        if let index = weeklyPlan.firstIndex(where: { $0.dayOfWeek == day }) {
            weeklyPlan[index].menu = menu
        }
    }

    // MARK: - Grocery Items (derived)

    var groceryItems: [GroceryItem] {
        var items: [GroceryItem] = []
        var seen = Set<String>()
        for day in weeklyPlan {
            guard let menu = day.menu else { continue }
            for item in menu.items {
                if !seen.contains(item) {
                    seen.insert(item)
                    items.append(GroceryItem(name: item, fromMenu: "Menu #\(menu.id)"))
                }
            }
        }
        return items
    }
}
