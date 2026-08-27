//
//  MenuStore.swift
//  TableReady
//

import Foundation

struct MenuImportResult {
    let menusAdded: Int
    let menusSkipped: Int
    let dishesAdded: Int
}

@Observable
class MenuStore {

    // MARK: - State

    var menus: [DayMenu] = []
    var weeklyPlan: [DayPlan] = []
    var dishes: [Dish] = []
    var familyMembers: [FamilyMember] = []
    var groceryItems: [GroceryItem] = []

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
        var familyMembers: [FamilyMember]?
        var groceryItems: [GroceryItem]?
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
            familyMembers = SampleData.familyMembers
            groceryItems = SampleData.groceryItems
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
            familyMembers = stored.familyMembers ?? []
            groceryItems = stored.groceryItems ?? []
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
                let key = item.name.lowercased()
                if !item.name.isEmpty && !seen.contains(key) {
                    seen.insert(key)
                    dishes.append(Dish(name: item.name, category: item.category))
                }
            }
        }
    }

    // MARK: - Saving

    private func save() {
        let storeData = StoreData(menus: menus, weeklyPlan: weeklyPlan, dishes: dishes, familyMembers: familyMembers, groceryItems: groceryItems)
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
        } else if let autoDay = bestOpenDay(for: menu) {
            assignMenuByID(menu.id, toDay: autoDay)
        }
        save()
    }

    /// Picks the best open (unassigned) day for a newly created menu that
    /// wasn't explicitly assigned a day. Prefers a day whose immediate
    /// neighbors don't already carry the same effort level, so heavy-cooking
    /// days don't land back-to-back. Returns nil if the week is already full.
    private func bestOpenDay(for menu: DayMenu) -> DayOfWeek? {
        let emptyDays = weeklyPlan.filter { $0.menu == nil }.map(\.dayOfWeek)
        guard !emptyDays.isEmpty else { return nil }

        func hasSameEffortNeighbor(_ day: DayOfWeek) -> Bool {
            for rawNeighbor in [day.rawValue - 1, day.rawValue + 1] {
                guard let neighborDay = DayOfWeek(rawValue: rawNeighbor) else { continue }
                if let neighborMenu = weeklyPlan.first(where: { $0.dayOfWeek == neighborDay })?.menu,
                   neighborMenu.effort == menu.effort {
                    return true
                }
            }
            return false
        }

        return emptyDays.sorted { a, b in
            let aConflict = hasSameEffortNeighbor(a)
            let bConflict = hasSameEffortNeighbor(b)
            if aConflict != bConflict {
                return !aConflict && bConflict
            }
            return a.rawValue < b.rawValue
        }.first
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

    /// Parses a markdown-formatted menu set (same format as the bundled seed
    /// data — see `MenuParser`) and merges it into the existing library.
    /// Each new menu is auto-assigned to an open day exactly like a manually
    /// built menu (`addMenu`'s `bestOpenDay` logic), and any dish name that
    /// isn't already in the Dish Library gets added — so imported dishes
    /// show up in future menu building, not just buried inside one menu.
    /// A menu whose set of dish names exactly matches one already in the
    /// library is skipped rather than imported as a duplicate.
    func importMenus(from markdown: String) -> MenuImportResult {
        let parsed = MenuParser.parse(markdown)
        var existingItemSets = Set(menus.map { Set($0.items.map { $0.name.lowercased() }) })
        var dishNamesSeen = Set(dishes.map { $0.name.lowercased() })

        var menusAdded = 0
        var menusSkipped = 0
        var dishesAdded = 0

        for parsedMenu in parsed {
            let itemSet = Set(parsedMenu.items.map { $0.name.lowercased() })
            guard !itemSet.isEmpty, !existingItemSets.contains(itemSet) else {
                menusSkipped += 1
                continue
            }

            var menu = parsedMenu
            menu.id = nextMenuID
            addMenu(menu, assignToDay: nil)
            existingItemSets.insert(itemSet)
            menusAdded += 1

            for item in menu.items {
                let key = item.name.lowercased()
                guard !key.isEmpty, !dishNamesSeen.contains(key) else { continue }
                dishNamesSeen.insert(key)
                dishes.append(Dish(name: item.name, category: item.category))
                dishesAdded += 1
            }
        }

        if dishesAdded > 0 {
            save()
        }

        return MenuImportResult(menusAdded: menusAdded, menusSkipped: menusSkipped, dishesAdded: dishesAdded)
    }

    func buildCustomMenu(from items: [MenuItem], chaiCount: Int, assignToDay day: DayOfWeek? = nil) {
        let menu = DayMenu(
            id: nextMenuID,
            items: items,
            chaiCount: chaiCount
        )
        addMenu(menu, assignToDay: day)
    }

    /// Replaces just the dishes in one category for a specific day, leaving
    /// every other category untouched. Forks a brand-new menu into the
    /// library and assigns it to that day, rather than mutating the shared
    /// menu in place — so if another day happens to use the same menu, it
    /// isn't silently changed too.
    func replaceItems(_ newItems: [MenuItem], in category: DishCategory, forDay day: DayOfWeek) {
        guard let planIndex = weeklyPlan.firstIndex(where: { $0.dayOfWeek == day }),
              let currentMenu = weeklyPlan[planIndex].menu else { return }

        var updatedItems = currentMenu.items
        updatedItems.removeAll { $0.category == category }
        updatedItems.append(contentsOf: newItems)

        let forkedMenu = DayMenu(id: nextMenuID, items: updatedItems, chaiCount: currentMenu.chaiCount)
        menus.append(forkedMenu)
        weeklyPlan[planIndex].menu = forkedMenu
        save()
    }

    // MARK: - Family Member Operations

    func addFamilyMember(_ member: FamilyMember) {
        familyMembers.append(member)
        save()
    }

    func updateFamilyMember(_ member: FamilyMember) {
        guard let index = familyMembers.firstIndex(where: { $0.id == member.id }) else { return }
        familyMembers[index] = member
        save()
    }

    func removeFamilyMember(_ member: FamilyMember) {
        familyMembers.removeAll { $0.id == member.id }
        save()
    }

    // MARK: - Grocery Item Operations

    func addGroceryItem(_ item: GroceryItem) {
        groceryItems.append(item)
        save()
    }

    func removeGroceryItem(_ item: GroceryItem) {
        groceryItems.removeAll { $0.id == item.id }
        save()
    }

    func toggleGroceryItemPurchased(_ item: GroceryItem) {
        guard let index = groceryItems.firstIndex(where: { $0.id == item.id }) else { return }
        groceryItems[index].isPurchased.toggle()
        save()
    }

    func setAllGroceryItemsPurchased(_ purchased: Bool) {
        for index in groceryItems.indices {
            groceryItems[index].isPurchased = purchased
        }
        save()
    }
}
