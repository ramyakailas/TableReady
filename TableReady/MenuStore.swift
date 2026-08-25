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
    var dishes: [Dish] = []

    // MARK: - Paths

    private var jsonFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("menuStore.json")
    }

    // MARK: - Persistence Model

    private struct StoreData: Codable {
        var menus: [DayMenu]
        var weeklyPlan: [DayPlan]
        var dishes: [Dish]?
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
            seedDishesFromMenus()
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
            dishes = stored.dishes ?? []
            if dishes.isEmpty {
                seedDishesFromMenus()
            } else {
                cleanUpDishNames()
            }
        } else {
            seedFromMarkdown()
        }
    }

    /// One-time migration for installs that seeded dishes before
    /// quantity-stripping existed (e.g. "5 parathas" -> "parathas").
    private func cleanUpDishNames() {
        var seen = Set<String>()
        var deduped: [Dish] = []
        for dish in dishes {
            let cleaned = Dish.cleanedName(from: dish.name)
            guard !cleaned.isEmpty, !seen.contains(cleaned.lowercased()) else { continue }
            seen.insert(cleaned.lowercased())
            var updated = dish
            updated.name = cleaned
            deduped.append(updated)
        }
        if deduped != dishes {
            dishes = deduped
            save()
        }
    }

    private func seedFromMarkdown() {
        let loaded = MenuParser.parse(SampleData.sampleMarkdown)
        menus = loaded

        let days = DayOfWeek.allCases
        weeklyPlan = days.enumerated().map { index, day in
            let menu = index < loaded.count ? loaded[index] : nil
            return DayPlan(dayOfWeek: day, menu: menu)
        }
        seedDishesFromMenus()
        save()
    }

    private func seedDishesFromMenus() {
        var seen = Set<String>()
        for menu in menus {
            for item in menu.items {
                let cleaned = Dish.cleanedName(from: item)
                if !cleaned.isEmpty && !seen.contains(cleaned.lowercased()) {
                    seen.insert(cleaned.lowercased())
                    dishes.append(Dish(name: cleaned))
                }
            }
        }
    }

    // MARK: - Saving

    private func save() {
        let storeData = StoreData(menus: menus, weeklyPlan: weeklyPlan, dishes: dishes)
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

    // MARK: - Dish Operations

    func addDish(_ dish: Dish) {
        dishes.append(dish)
        save()
    }

    func removeDish(_ dish: Dish) {
        dishes.removeAll { $0.id == dish.id }
        save()
    }

    func buildCustomMenu(from selectedDishes: [Dish], breadCount: Int, chaiCount: Int, assignToDay day: DayOfWeek? = nil) {
        let menu = DayMenu(
            id: nextMenuID,
            breadCount: breadCount,
            items: selectedDishes.map(\.name),
            chaiCount: chaiCount
        )
        addMenu(menu, assignToDay: day)
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
