//
//  WeeklyMenuView.swift
//  TableReady
//

import SwiftUI

struct WeeklyMenuView: View {
    @Environment(MenuStore.self) private var store
    @State private var selectedDay: DayOfWeek = .sunday
    @State private var showWeeklyOverview = true
    @State private var showAddMenu = false
    @State private var showCustomBuilder = false
    @State private var dayForMenuPicker: DayOfWeek?

    var body: some View {
        NavigationStack {
            Group {
                if showWeeklyOverview {
                    WeeklyOverviewGrid(dayForMenuPicker: $dayForMenuPicker)
                } else {
                    DayDetailView(selectedDay: $selectedDay, dayForMenuPicker: $dayForMenuPicker)
                }
            }
            .navigationTitle(showWeeklyOverview ? "Weekly Overview" : "This Week")
            .toolbar(content: {
                ToolbarItem(placement: .navigation) {
                    Menu {
                        Button {
                            showAddMenu = true
                        } label: {
                            Label("Quick Menu", systemImage: "plus.circle")
                        }
                        Button {
                            showCustomBuilder = true
                        } label: {
                            Label("Build from Dishes", systemImage: "book")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Menu")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showWeeklyOverview.toggle()
                        }
                    } label: {
                        Image(systemName: showWeeklyOverview ? "calendar.day.timeline.left" : "calendar")
                    }
                    .accessibilityLabel(showWeeklyOverview ? "Switch to Day View" : "Switch to Weekly Overview")
                }
            })
            .sheet(isPresented: $showAddMenu) {
                AddMenuView()
                    .environment(store)
            }
            .sheet(isPresented: $showCustomBuilder) {
                CustomMenuBuilderView()
                    .environment(store)
            }
            .sheet(item: $dayForMenuPicker) { day in
                MenuPickerView(day: day)
                    .environment(store)
            }
        }
    }
}

// MARK: - Weekly Overview Grid

struct WeeklyOverviewGrid: View {
    @Environment(MenuStore.self) private var store
    @Binding var dayForMenuPicker: DayOfWeek?
    @State private var expandedDay: DayOfWeek?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(DayOfWeek.allCases) { day in
                    let dayPlan = store.weeklyPlan.first(where: { $0.dayOfWeek == day })
                    WeeklyDayCard(
                        day: day,
                        menu: dayPlan?.menu,
                        isExpanded: expandedDay == day,
                        onTapHeader: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                expandedDay = (expandedDay == day) ? nil : day
                            }
                        },
                        onAssignMenu: {
                            dayForMenuPicker = day
                        },
                        onClearDay: {
                            store.clearDay(day)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AppTheme.offWhiteBackground)
    }
}

struct WeeklyDayCard: View {
    let day: DayOfWeek
    let menu: DayMenu?
    var isExpanded: Bool = false
    var onTapHeader: (() -> Void)? = nil
    var onAssignMenu: (() -> Void)? = nil
    var onClearDay: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Day header row
            dayHeaderRow

            // Content: items with left bracket
            if let menu {
                dayContentWithBracket(menu: menu)
            } else {
                emptyDayContent
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.dayCardCornerRadius)
                .fill(AppTheme.flatCardWhite)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.dayCardCornerRadius))
    }

    // MARK: - Day Header

    private var dayHeaderRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.chaiBrown)

                if let menu {
                    Text("Menu #\(menu.id) \u{00B7} \(menu.items.count) items")
                        .font(.caption)
                        .foregroundColor(AppTheme.chaiBrownMuted)
                }
            }

            Spacer()

            Button {
                onAssignMenu?()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.chaiBrown.opacity(0.75))
                    .frame(width: 44, height: 44)
                    .background(AppTheme.chaiBrown.opacity(0.06))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Assign menu to \(day.name)")

            if menu != nil {
                Menu {
                    Button {
                        onAssignMenu?()
                    } label: {
                        Label("Change Menu", systemImage: "arrow.triangle.2.circlepath")
                    }

                    Button(role: .destructive) {
                        onClearDay?()
                    } label: {
                        Label("Clear Day", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.chaiBrown.opacity(0.75))
                        .frame(width: 44, height: 44)
                        .background(AppTheme.chaiBrown.opacity(0.06))
                        .clipShape(Circle())
                }
                .accessibilityLabel("More options for \(day.name)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            onTapHeader?()
        }
    }

    // MARK: - Content with Left Bracket

    private func dayContentWithBracket(menu: DayMenu) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Left bracket
            LeftBracket()
                .padding(.leading, 16)

            // Items list
            VStack(alignment: .leading, spacing: 0) {
                let itemsToShow = isExpanded ? menu.items : Array(menu.items.prefix(3))
                ForEach(Array(itemsToShow.enumerated()), id: \.offset) { _, item in
                    CroutonMenuItemRow(item: item)
                }

                if !isExpanded && menu.items.count > 3 {
                    Text("+ \(menu.items.count - 3) more")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.chaiBrown)
                        .padding(.leading, 12)
                        .padding(.vertical, 6)
                }

                // Bread & chai stats
                HStack(spacing: 12) {
                    Label("\(menu.breadCount) breads", systemImage: "circle.grid.cross.fill")
                        .font(.caption2)
                        .foregroundColor(AppTheme.chaiBrownMuted)
                    Label("\(menu.chaiCount) chai", systemImage: "cup.and.saucer.fill")
                        .font(.caption2)
                        .foregroundColor(AppTheme.chaiBrownMuted)
                }
                .padding(.leading, 12)
                .padding(.top, 4)
                .padding(.bottom, 14)
            }
        }
    }

    // MARK: - Empty Day Content

    private var emptyDayContent: some View {
        HStack {
            Text("No menu assigned")
                .font(.subheadline)
                .foregroundColor(AppTheme.chaiBrownMuted)
                .italic()
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }
}

// MARK: - Day Detail View

struct DayDetailView: View {
    @Environment(MenuStore.self) private var store
    @Binding var selectedDay: DayOfWeek
    @Binding var dayForMenuPicker: DayOfWeek?

    var body: some View {
        VStack(spacing: 0) {
            // Day selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DayOfWeek.allCases) { day in
                        DayTab(
                            day: day,
                            isSelected: selectedDay == day,
                            hasMenu: store.weeklyPlan.first(where: { $0.dayOfWeek == day })?.menu != nil
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDay = day
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(AppTheme.warmCream)

            // Menu for selected day
            if let dayPlan = store.weeklyPlan.first(where: { $0.dayOfWeek == selectedDay }),
               let menu = dayPlan.menu {
                ScrollView {
                    VStack(spacing: 16) {
                        MenuHeaderView(menu: menu)
                        MenuItemsListView(day: selectedDay, menu: menu)

                        HStack(spacing: 12) {
                            Button {
                                dayForMenuPicker = selectedDay
                            } label: {
                                Label("Change Menu", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .buttonStyle(.bordered)

                            Button(role: .destructive) {
                                store.clearDay(selectedDay)
                            } label: {
                                Label("Clear Day", systemImage: "xmark")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView {
                    Label("No Menu Assigned", systemImage: "fork.knife")
                        .foregroundColor(AppTheme.chaiBrown)
                } description: {
                    Text("No menu is set for \(selectedDay.name)")
                        .foregroundColor(AppTheme.chaiBrownMuted)
                } actions: {
                    Button("Set Menu") {
                        dayForMenuPicker = selectedDay
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.chaiBrown)
                }
            }
        }
    }
}

// MARK: - Menu Picker

struct MenuPickerView: View {
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showCustomBuilder = false
    let day: DayOfWeek

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showCustomBuilder = true
                    } label: {
                        Label("Build Custom Menu", systemImage: "book")
                    }

                    Button(role: .destructive) {
                        store.clearDay(day)
                        dismiss()
                    } label: {
                        Label("Clear Menu", systemImage: "xmark.circle")
                    }
                }

                Section("Menu Library") {
                    ForEach(store.menus) { menu in
                        Button {
                            store.assignMenu(menu, toDay: day)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Menu #\(menu.id)")
                                        .font(.headline)
                                    Text(menu.items.prefix(2).map(\.name).joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Text("\(menu.breadCount) breads")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Menu for \(day.name)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showCustomBuilder) {
                CustomMenuBuilderView(assignDay: day)
                    .environment(store)
            }
        }
    }
}

// MARK: - Day Tab

struct DayTab: View {
    let day: DayOfWeek
    let isSelected: Bool
    var hasMenu: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(day.shortName)
                    .font(.caption)
                    .fontWeight(.medium)
                Circle()
                    .fill(isSelected ? Color.white : (hasMenu ? AppTheme.chaiBrown.opacity(0.3) : Color.clear))
                    .frame(width: 6, height: 6)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? AnyShapeStyle(AppTheme.tabSelectedGradient) : AnyShapeStyle(Color.clear))
                    .shadow(color: isSelected ? AppTheme.cardShadowColor : .clear, radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .white : AppTheme.chaiBrownMuted)
        .accessibilityLabel("\(day.name)\(hasMenu ? ", menu assigned" : ", no menu")")
    }
}

// MARK: - Crouton-Style Components

struct BracketShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let curveDepth: CGFloat = rect.width * 0.8
        let endInset: CGFloat = 6

        path.move(to: CGPoint(x: rect.maxX, y: rect.minY + endInset))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - curveDepth, y: midY),
            control: CGPoint(x: rect.maxX - curveDepth, y: rect.minY + endInset)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY - endInset),
            control: CGPoint(x: rect.maxX - curveDepth, y: rect.maxY - endInset)
        )

        return path
    }
}

struct LeftBracket: View {
    var body: some View {
        BracketShape()
            .stroke(AppTheme.bracketColor, lineWidth: AppTheme.bracketLineWidth)
            .frame(width: 8)
            .padding(.vertical, 6)
    }
}

struct CroutonMenuItemRow: View {
    let item: MenuItem

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppTheme.thumbnailColor(for: item.name))
                    .frame(width: AppTheme.thumbnailSize, height: AppTheme.thumbnailSize)

                Image(systemName: AppTheme.foodIcon(for: item.name))
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.chaiBrown.opacity(0.6))
            }

            Text(item.quantity.map { "\($0) \(item.name)" } ?? item.name)
                .font(.subheadline)
                .foregroundColor(AppTheme.chaiBrown)
                .lineLimit(2)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

// MARK: - Menu Header

struct MenuHeaderView: View {
    let menu: DayMenu

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Menu #\(menu.id)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.chaiBrown)

            HStack(spacing: 16) {
                Label("\(menu.breadCount) breads", systemImage: "birthday.cake")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.chaiBrownMuted)
                Label("\(menu.chaiCount) chai", systemImage: "cup.and.saucer.fill")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.chaiBrownMuted)
                Label("\(menu.items.count) items", systemImage: "list.bullet")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.chaiBrownMuted)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.flatCardWhite)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Effort Badge

struct EffortBadge: View {
    let effort: MenuEffort

    var badgeColor: Color {
        AppTheme.effortColor(for: effort)
    }

    var body: some View {
        Label(effort.rawValue, systemImage: effort.icon)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.25))
            .foregroundColor(AppTheme.effortTextColor(for: effort))
            .clipShape(Capsule())
    }
}

// MARK: - Menu Items List

struct MenuItemsListView: View {
    @Environment(MenuStore.self) private var store
    let day: DayOfWeek
    let menu: DayMenu
    @State private var editingCategory: DishCategory?

    private var activeCategories: [DishCategory] {
        DishCategory.allCases.filter { !menu.items(in: $0).isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(activeCategories) { category in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(category.displayName, systemImage: category.icon)
                            .font(.headline)
                            .foregroundColor(AppTheme.chaiBrown)
                        Spacer()
                        Button("Edit") {
                            editingCategory = category
                        }
                        .font(.subheadline)
                        .foregroundColor(AppTheme.chaiBrown)
                    }

                    ForEach(menu.items(in: category)) { item in
                        MenuItemRow(item: item)
                    }
                }
            }

            if activeCategories.isEmpty {
                Text("No items yet")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.chaiBrownMuted)
                    .italic()
            }
        }
        .sheet(item: $editingCategory) { category in
            CategoryItemPickerView(day: day, category: category, currentItems: menu.items(in: category))
                .environment(store)
        }
    }
}

struct MenuItemRow: View {
    let item: MenuItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.thumbnailColor(for: item.name))
                    .frame(width: AppTheme.thumbnailSize, height: AppTheme.thumbnailSize)

                Image(systemName: AppTheme.foodIcon(for: item.name))
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.chaiBrown.opacity(0.6))
            }

            Text(item.name)
                .font(.body)

            Spacer()

            if let quantity = item.quantity {
                Text("\u{00D7}\(quantity)")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.chaiBrownMuted)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
    }
}

// MARK: - Category Item Picker (per-category day editing)

struct CategoryItemPickerView: View {
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let day: DayOfWeek
    let category: DishCategory
    @State private var selected: [MenuItem]

    init(day: DayOfWeek, category: DishCategory, currentItems: [MenuItem]) {
        self.day = day
        self.category = category
        _selected = State(initialValue: currentItems)
    }

    private var availableDishes: [Dish] {
        store.dishes.filter { $0.category == category }
    }

    private func isSelected(_ dish: Dish) -> Bool {
        selected.contains { $0.name.lowercased() == dish.name.lowercased() }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Selected") {
                    if selected.isEmpty {
                        Text("None — pick from below")
                            .foregroundColor(.secondary)
                    }
                    ForEach($selected) { $item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            if category == .bread {
                                Stepper(value: Binding(
                                    get: { item.quantity ?? 1 },
                                    set: { item.quantity = $0 }
                                ), in: 1...30) {
                                    Text("\u{00D7}\(item.quantity ?? 1)")
                                }
                            }
                        }
                    }
                    .onDelete { offsets in
                        selected.remove(atOffsets: offsets)
                    }
                }

                Section("\(category.displayName) Dishes") {
                    ForEach(availableDishes) { dish in
                        Button {
                            if isSelected(dish) {
                                selected.removeAll { $0.name.lowercased() == dish.name.lowercased() }
                            } else {
                                selected.append(MenuItem(
                                    name: dish.name,
                                    category: category,
                                    quantity: category == .bread ? 1 : nil
                                ))
                            }
                        } label: {
                            HStack {
                                Text(dish.name)
                                Spacer()
                                if isSelected(dish) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppTheme.herbGreen)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Edit \(category.displayName)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.replaceItems(selected, in: category, forDay: day)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Day View") {
    WeeklyMenuView()
        .environment(MenuStore(sampleData: true))
}

#Preview("Weekly Overview") {
    NavigationStack {
        WeeklyOverviewGrid(dayForMenuPicker: .constant(nil))
            .navigationTitle("Weekly Overview")
    }
    .environment(MenuStore(sampleData: true))
}

#Preview("Menu Picker") {
    MenuPickerView(day: .monday)
        .environment(MenuStore(sampleData: true))
}

#Preview("Day Card - Expanded") {
    WeeklyDayCard(
        day: .sunday,
        menu: SampleData.menus[0],
        isExpanded: true
    )
    .padding()
    .background(AppTheme.offWhiteBackground)
}

#Preview("Day Card - Collapsed") {
    WeeklyDayCard(
        day: .monday,
        menu: SampleData.menus[1],
        isExpanded: false
    )
    .padding()
    .background(AppTheme.offWhiteBackground)
}

#Preview("Day Card - No Menu") {
    WeeklyDayCard(day: .saturday, menu: nil)
        .padding()
        .background(AppTheme.offWhiteBackground)
}

#Preview("Crouton Item Rows") {
    VStack(spacing: 0) {
        CroutonMenuItemRow(item: MenuItem(name: "Dal khichdi with garlic / ginger and pepper"))
        CroutonMenuItemRow(item: MenuItem(name: "Gobi manchurian / Street side fried rice"))
        CroutonMenuItemRow(item: MenuItem(name: "chapathis palak paneer for dinner", category: .bread, quantity: 10))
        CroutonMenuItemRow(item: MenuItem(name: "parathas", category: .bread, quantity: 5))
    }
    .padding()
}

#Preview("Effort Badges") {
    HStack(spacing: 12) {
        EffortBadge(effort: .light)
        EffortBadge(effort: .medium)
        EffortBadge(effort: .heavy)
    }
    .padding()
}
#Preview("Empty Day Selected") {
    let store = MenuStore(sampleData: true)
    // Clear Saturday so it shows the empty state
    let _ = store.clearDay(.saturday)
    DayDetailView(selectedDay: .constant(.saturday), dayForMenuPicker: .constant(nil))
        .environment(store)
}

#Preview("Heavy Menu Detail") {
    MenuDetailPreview(
        menu: DayMenu(
            id: 99,
            items: [
                MenuItem(name: "Dal khichdi with garlic / ginger and pepper"),
                MenuItem(name: "Rice bowl using black, pinto, 1/2 cup rice, avocado, jalapeño"),
                MenuItem(name: "chapathis", category: .bread, quantity: 10),
                MenuItem(name: "parathas", category: .bread, quantity: 5)
            ],
            chaiCount: 2
        ),
        title: "Sunday"
    )
}

private struct MenuDetailPreview: View {
    let menu: DayMenu
    var title: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    MenuHeaderView(menu: menu)
                    MenuItemsListView(day: .sunday, menu: menu)
                }
                .padding()
            }
            .navigationTitle(title)
        }
        .environment(MenuStore(sampleData: true))
    }
}

#Preview("Light Menu Detail") {
    MenuDetailPreview(
        menu: DayMenu(
            id: 9,
            items: [
                MenuItem(name: "Tofu chilly"),
                MenuItem(name: "Egg fried rice"),
                MenuItem(name: "3 veg sandwiches")
            ],
            chaiCount: 2
        ),
        title: "Wednesday"
    )
}

