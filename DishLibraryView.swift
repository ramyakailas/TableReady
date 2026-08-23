//
//  DishLibraryView.swift
//  TableReady
//

import SwiftUI

struct DishLibraryView: View {
    @Environment(MenuStore.self) private var store
    @State private var searchText = ""
    @State private var showAddDish = false

    private var filteredDishes: [Dish] {
        if searchText.isEmpty {
            return store.dishes
        }
        return store.dishes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func dishes(for category: DishCategory) -> [Dish] {
        filteredDishes.filter { $0.category == category }
    }

    private var activeCategories: [DishCategory] {
        DishCategory.allCases.filter { !dishes(for: $0).isEmpty }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(activeCategories) { category in
                    Section {
                        ForEach(dishes(for: category)) { dish in
                            DishRow(dish: dish)
                        }
                        .onDelete { offsets in
                            let categoryDishes = dishes(for: category)
                            for offset in offsets {
                                store.removeDish(categoryDishes[offset])
                            }
                        }
                    } header: {
                        Label(category.displayName, systemImage: category.icon)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.chaiBrown)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search dishes")
            .scrollContentBackground(.hidden)
            .background(AppTheme.warmCream)
            .navigationTitle("Dish Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddDish = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddDish) {
                AddDishView()
                    .environment(store)
            }
            .overlay {
                if store.dishes.isEmpty {
                    ContentUnavailableView {
                        Label("No Dishes", systemImage: "fork.knife")
                            .foregroundColor(AppTheme.turmeric)
                    } description: {
                        Text("Add dishes to build custom menus")
                            .foregroundColor(AppTheme.chaiBrown.opacity(0.7))
                    } actions: {
                        Button("Add Dish") {
                            showAddDish = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.turmeric)
                    }
                }
            }
        }
    }
}

// MARK: - Dish Row

struct DishRow: View {
    let dish: Dish

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.thumbnailColor(for: dish.name))
                    .frame(width: AppTheme.thumbnailSize, height: AppTheme.thumbnailSize)

                Image(systemName: AppTheme.foodIcon(for: dish.name))
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.chaiBrown.opacity(0.6))
            }

            Text(dish.name)
                .font(.body)
                .foregroundColor(AppTheme.chaiBrown)

            Spacer()

            Text(dish.category.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(AppTheme.chaiBrown.opacity(0.08))
                .foregroundColor(AppTheme.chaiBrown.opacity(0.6))
                .clipShape(Capsule())
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Add Dish View

struct AddDishView: View {
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: DishCategory = .curry

    var body: some View {
        NavigationStack {
            Form {
                Section("Dish Name") {
                    TextField("e.g. Palak Paneer", text: $name)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(DishCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.warmCream)
            .navigationTitle("New Dish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let dish = Dish(name: name.trimmingCharacters(in: .whitespaces), category: category)
                        store.addDish(dish)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: name) {
                category = DishCategory.categorize(name)
            }
        }
    }
}

// MARK: - Previews

#Preview("Dish Library") {
    DishLibraryView()
        .environment(MenuStore(sampleData: true))
}

#Preview("Add Dish") {
    AddDishView()
        .environment(MenuStore(sampleData: true))
}
