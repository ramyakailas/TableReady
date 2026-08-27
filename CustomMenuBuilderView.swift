//
//  CustomMenuBuilderView.swift
//  TableReady
//

import SwiftUI

struct CustomMenuBuilderView: View {
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItems: [MenuItem] = []
    @State private var chaiCount = 2
    @State private var searchText = ""
    @State private var selectedDay: DayOfWeek?
    @State private var showAddDish = false

    /// Optional pre-selected day (passed from MenuPickerView)
    var assignDay: DayOfWeek?

    private var computedEffort: MenuEffort {
        DayMenu(id: 0, items: selectedItems, chaiCount: 0).effort
    }

    private func isSelected(_ dish: Dish) -> Bool {
        selectedItems.contains { $0.name.lowercased() == dish.name.lowercased() }
    }

    private var availableDishes: [Dish] {
        // Newest-added dishes first, so a dish you just added shows up
        // right away instead of being buried under older ones.
        let available = store.dishes.reversed().filter { !isSelected($0) }
        if searchText.isEmpty {
            return available
        }
        return available.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func availableDishes(for category: DishCategory) -> [Dish] {
        availableDishes.filter { $0.category == category }
    }

    private var activeCategories: [DishCategory] {
        DishCategory.allCases.filter { !availableDishes(for: $0).isEmpty }
    }

    init(assignDay: DayOfWeek? = nil) {
        self.assignDay = assignDay
        _selectedDay = State(initialValue: assignDay)
    }

    var body: some View {
        NavigationStack {
            List {
                // Selected items section
                Section {
                    if selectedItems.isEmpty {
                        Text("Tap dishes below to add them")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.chaiBrown.opacity(0.4))
                            .italic()
                    } else {
                        ForEach($selectedItems) { $item in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.thumbnailColor(for: item.name))
                                        .frame(width: 30, height: 30)

                                    Image(systemName: AppTheme.foodIcon(for: item.name))
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.chaiBrown.opacity(0.6))
                                }

                                Text(item.name)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.chaiBrown)

                                Spacer()

                                if item.category == .bread {
                                    Stepper(value: Binding(
                                        get: { item.quantity ?? 1 },
                                        set: { item.quantity = $0 }
                                    ), in: 1...30) {
                                        Text("\u{00D7}\(item.quantity ?? 1)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .fixedSize()
                                }

                                Button {
                                    withAnimation {
                                        selectedItems.removeAll { $0.id == item.id }
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(AppTheme.spiceRed.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Your Menu")
                        Spacer()
                        if !selectedItems.isEmpty {
                            EffortBadge(effort: computedEffort)
                        }
                    }
                }

                // Settings
                Section("Settings") {
                    Stepper("Chai: \(chaiCount)", value: $chaiCount, in: 0...10)

                    if assignDay == nil {
                        Picker("Assign to Day", selection: $selectedDay) {
                            Text("None").tag(DayOfWeek?.none)
                            ForEach(DayOfWeek.allCases) { day in
                                Text(day.name).tag(DayOfWeek?.some(day))
                            }
                        }
                    }
                }

                // Available dishes
                Section {
                    ForEach(activeCategories) { category in
                        DisclosureGroup {
                            ForEach(availableDishes(for: category)) { dish in
                                Button {
                                    withAnimation {
                                        selectedItems.append(MenuItem(
                                            name: dish.name,
                                            category: dish.category,
                                            quantity: dish.category == .bread ? 1 : nil
                                        ))
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(AppTheme.thumbnailColor(for: dish.name))
                                                .frame(width: 30, height: 30)

                                            Image(systemName: AppTheme.foodIcon(for: dish.name))
                                                .font(.system(size: 12))
                                                .foregroundColor(AppTheme.chaiBrown.opacity(0.6))
                                        }

                                        Text(dish.name)
                                            .font(.subheadline)
                                            .foregroundColor(AppTheme.chaiBrown)

                                        Spacer()

                                        Image(systemName: "plus.circle")
                                            .foregroundColor(AppTheme.turmeric)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        } label: {
                            Label(category.displayName, systemImage: category.icon)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.chaiBrown)
                        }
                    }
                    Button {
                        showAddDish = true
                    } label: {
                        Label("New Dish", systemImage: "plus.circle")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.turmeric)
                    }
                } header: {
                    Text("Dish Library")
                }
            }
            .searchable(text: $searchText, prompt: "Search dishes")
            .scrollContentBackground(.hidden)
            .background(AppTheme.warmCream)
            .navigationTitle("Build Menu")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.buildCustomMenu(
                            from: selectedItems,
                            chaiCount: chaiCount,
                            assignToDay: selectedDay
                        )
                        dismiss()
                    }
                    .disabled(selectedItems.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showAddDish) {
                AddDishView()
                    .environment(store)
            }
        }
    }
}

// MARK: - Previews

#Preview("Custom Menu Builder") {
    CustomMenuBuilderView()
        .environment(MenuStore(sampleData: true))
}

#Preview("Builder for Wednesday") {
    CustomMenuBuilderView(assignDay: .wednesday)
        .environment(MenuStore(sampleData: true))
}
