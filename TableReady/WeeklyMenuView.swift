//
//  WeeklyMenuView.swift
//  TableReady
//

import SwiftUI

struct WeeklyMenuView: View {
    @Environment(MenuStore.self) private var store
    @State private var selectedDay: DayOfWeek = .sunday
    @State private var showWeeklyOverview = false
    @State private var showAddMenu = false
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showAddMenu = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showWeeklyOverview.toggle()
                        }
                    } label: {
                        Image(systemName: showWeeklyOverview ? "calendar.day.timeline.left" : "calendar")
                    }
                }
            })
            .sheet(isPresented: $showAddMenu) {
                AddMenuView()
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

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(DayOfWeek.allCases) { day in
                    let dayPlan = store.weeklyPlan.first(where: { $0.dayOfWeek == day })
                    WeeklyDayCard(day: day, menu: dayPlan?.menu)
                        .onTapGesture {
                            dayForMenuPicker = day
                        }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct WeeklyDayCard: View {
    let day: DayOfWeek
    let menu: DayMenu?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(day.name)
                    .font(.headline)
                Spacer()
                if let menu {
                    EffortBadge(effort: menu.effort)
                }
            }

            if let menu {
                HStack(spacing: 14) {
                    Label("Menu #\(menu.id)", systemImage: "list.clipboard")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    Label("\(menu.breadCount) breads", systemImage: "birthday.cake")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Label("\(menu.chaiCount) chai", systemImage: "cup.and.saucer.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                let preview = menu.items.prefix(3)
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(preview.enumerated()), id: \.offset) { _, item in
                        Text("• \(item)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    if menu.items.count > 3 {
                        Text("+ \(menu.items.count - 3) more")
                            .font(.caption2)
                            .foregroundColor(.accentColor)
                    }
                }
            } else {
                Text("Tap to assign a menu")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
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
            .background(Color(.systemGroupedBackground))

            // Menu for selected day
            if let dayPlan = store.weeklyPlan.first(where: { $0.dayOfWeek == selectedDay }),
               let menu = dayPlan.menu {
                ScrollView {
                    VStack(spacing: 16) {
                        MenuHeaderView(menu: menu)
                        MenuItemsListView(menu: menu)

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
                } description: {
                    Text("No menu is set for \(selectedDay.name)")
                } actions: {
                    Button("Set Menu") {
                        dayForMenuPicker = selectedDay
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

// MARK: - Menu Picker

struct MenuPickerView: View {
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let day: DayOfWeek

    var body: some View {
        NavigationStack {
            List {
                Section {
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
                                    Text(menu.items.prefix(2).joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    EffortBadge(effort: menu.effort)
                                    Text("\(menu.breadCount) breads")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Menu for \(day.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
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
                    .fill(isSelected ? Color.accentColor : (hasMenu ? Color.secondary.opacity(0.3) : Color.clear))
                    .frame(width: 6, height: 6)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .accentColor : .secondary)
    }
}

// MARK: - Menu Header

struct MenuHeaderView: View {
    let menu: DayMenu

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Menu #\(menu.id)")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                EffortBadge(effort: menu.effort)
            }

            HStack(spacing: 16) {
                Label("\(menu.breadCount) breads", systemImage: "birthday.cake")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Label("\(menu.chaiCount) chai", systemImage: "cup.and.saucer.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Label("\(menu.items.count) items", systemImage: "list.bullet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Effort Badge

struct EffortBadge: View {
    let effort: MenuEffort

    var badgeColor: Color {
        switch effort {
        case .light: return .green
        case .medium: return .orange
        case .heavy: return .red
        }
    }

    var body: some View {
        Label(effort.rawValue, systemImage: effort.icon)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.15))
            .foregroundColor(badgeColor)
            .clipShape(Capsule())
    }
}

// MARK: - Menu Items List

struct MenuItemsListView: View {
    let menu: DayMenu

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Items")
                .font(.headline)
                .foregroundColor(.secondary)

            ForEach(Array(menu.items.enumerated()), id: \.offset) { index, item in
                MenuItemRow(item: item, index: index + 1)
            }
        }
    }
}

struct MenuItemRow: View {
    let item: String
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
                .frame(width: 24, height: 24)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Circle())

            Text(item)
                .font(.body)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
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

#Preview("Weekly Day Card - With Menu") {
    WeeklyDayCard(day: .sunday, menu: SampleData.menus[0])
        .padding()
}

#Preview("Weekly Day Card - No Menu") {
    WeeklyDayCard(day: .saturday, menu: nil)
        .padding()
}

#Preview("Empty Week") {
    WeeklyMenuView()
        .environment(MenuStore(sampleData: true))
}

#Preview("Effort Badge") {
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
            breadCount: 15,
            items: [
                "Dal khichdi with garlic / ginger and pepper",
                "Rice bowl using black, pinto, 1/2 cup rice, avocado, jalapeño",
                "10 chapathis palak paneer for dinner",
                "5 parathas"
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
                    MenuItemsListView(menu: menu)
                }
                .padding()
            }
            .navigationTitle(title)
        }
    }
}

#Preview("Light Menu Detail") {
    MenuDetailPreview(
        menu: DayMenu(
            id: 9,
            breadCount: 0,
            items: [
                "Tofu chilly",
                "Egg fried rice",
                "3 veg sandwiches"
            ],
            chaiCount: 2
        ),
        title: "Wednesday"
    )
}

