//
//  GroceryListView.swift
//  TableReady
//

import SwiftUI

struct GroceryListView: View {
    @Environment(MenuStore.self) private var store
    @State private var showAddItem = false

    private var purchasedCount: Int {
        store.groceryItems.filter(\.isPurchased).count
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.groceryItems.isEmpty {
                    ContentUnavailableView {
                        Label("No Items", systemImage: "cart")
                            .foregroundColor(AppTheme.chaiBrown)
                    } description: {
                        Text("Add items you need to buy")
                            .foregroundColor(AppTheme.chaiBrownMuted)
                    } actions: {
                        Button("Add Item") {
                            showAddItem = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.chaiBrown)
                    }
                } else {
                    List {
                        Section {
                            ProgressView(value: Double(purchasedCount), total: Double(store.groceryItems.count))
                                .tint(AppTheme.herbGreen)
                            Text("\(purchasedCount) of \(store.groceryItems.count) items purchased")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Section("To Buy") {
                            ForEach(store.groceryItems.filter { !$0.isPurchased }) { item in
                                GroceryRowView(item: item)
                            }
                            .onDelete { offsets in
                                let toBuy = store.groceryItems.filter { !$0.isPurchased }
                                for index in offsets {
                                    store.removeGroceryItem(toBuy[index])
                                }
                            }
                        }

                        Section("Purchased") {
                            ForEach(store.groceryItems.filter(\.isPurchased)) { item in
                                GroceryRowView(item: item)
                            }
                            .onDelete { offsets in
                                let purchased = store.groceryItems.filter(\.isPurchased)
                                for index in offsets {
                                    store.removeGroceryItem(purchased[index])
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.warmCream)
                }
            }
            .navigationTitle("Grocery List")
            .toolbar(content: {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Add Item", systemImage: "plus") {
                            showAddItem = true
                        }
                        Button("Uncheck All", systemImage: "arrow.counterclockwise") {
                            store.setAllGroceryItemsPurchased(false)
                        }
                        Button("Check All", systemImage: "checkmark.circle") {
                            store.setAllGroceryItemsPurchased(true)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("List Actions")
                }
            })
            .sheet(isPresented: $showAddItem) {
                AddGroceryItemView()
                    .environment(store)
            }
        }
    }
}

struct GroceryRowView: View {
    @Environment(MenuStore.self) private var store
    let item: GroceryItem

    var body: some View {
        Button {
            withAnimation {
                store.toggleGroceryItemPurchased(item)
            }
        } label: {
            HStack {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isPurchased ? AppTheme.herbGreen : .secondary)
                    .font(.title3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading) {
                    Text(item.name)
                        .strikethrough(item.isPurchased)
                        .foregroundColor(item.isPurchased ? .secondary : .primary)
                    if !item.fromMenu.isEmpty {
                        Text(item.fromMenu)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.name)
        .accessibilityValue(item.isPurchased ? "Purchased" : "Not purchased")
    }
}

// MARK: - Add Grocery Item

struct AddGroceryItemView: View {
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Name") {
                    TextField("e.g. Paneer", text: $name)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.warmCream)
            .navigationTitle("New Grocery Item")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        store.addGroceryItem(GroceryItem(name: trimmed))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Full Grocery List") {
    GroceryListView()
        .environment(MenuStore(sampleData: true))
}

#Preview("Empty Grocery List") {
    let store = MenuStore(sampleData: true)
    store.groceryItems = []
    return GroceryListView()
        .environment(store)
}

#Preview("Add Grocery Item") {
    AddGroceryItemView()
        .environment(MenuStore(sampleData: true))
}

#Preview("Grocery Row - Unpurchased") {
    GroceryRowView(item: GroceryItem(name: "Paneer", fromMenu: "Menu #3"))
        .padding()
        .environment(MenuStore(sampleData: true))
}

#Preview("Grocery Row - Purchased") {
    GroceryRowView(item: GroceryItem(name: "Chapathis", isPurchased: true, fromMenu: "Menu #7"))
        .padding()
        .environment(MenuStore(sampleData: true))
}
