//
//  GroceryListView.swift
//  TableReady
//

import SwiftUI

struct GroceryListView: View {
    @State var items: [GroceryItem]

    var purchasedCount: Int {
        items.filter(\.isPurchased).count
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView {
                        Label("No Items", systemImage: "cart")
                    } description: {
                        Text("Items from your weekly menus will appear here")
                    }
                } else {
                    List {
                        Section {
                            ProgressView(value: Double(purchasedCount), total: Double(items.count))
                                .tint(.green)
                            Text("\(purchasedCount) of \(items.count) items purchased")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Section("To Buy") {
                            ForEach($items.filter({ !$0.wrappedValue.isPurchased })) { $item in
                                GroceryRowView(item: $item)
                            }
                        }

                        Section("Purchased") {
                            ForEach($items.filter({ $0.wrappedValue.isPurchased })) { $item in
                                GroceryRowView(item: $item)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Grocery List")
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Uncheck All", systemImage: "arrow.counterclockwise") {
                            for i in items.indices {
                                items[i].isPurchased = false
                            }
                        }
                        Button("Check All", systemImage: "checkmark.circle") {
                            for i in items.indices {
                                items[i].isPurchased = true
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            })
        }
    }
}

struct GroceryRowView: View {
    @Binding var item: GroceryItem

    var body: some View {
        Button {
            withAnimation {
                item.isPurchased.toggle()
            }
        } label: {
            HStack {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isPurchased ? .green : .secondary)
                    .font(.title3)
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
    }
}

// MARK: - Previews

#Preview("Full Grocery List") {
    GroceryListView(items: SampleData.groceryItems)
}

#Preview("Empty Grocery List") {
    GroceryListView(items: [])
}

#Preview("All Purchased") {
    GroceryListView(items: SampleData.groceryItems.map { item in
        var purchased = item
        purchased.isPurchased = true
        return purchased
    })
}

#Preview("Grocery Row - Unpurchased") {
    GroceryRowView(item: .constant(GroceryItem(name: "Paneer", fromMenu: "Menu #3")))
        .padding()
}

#Preview("Grocery Row - Purchased") {
    GroceryRowView(item: .constant(GroceryItem(name: "Chapathis", isPurchased: true, fromMenu: "Menu #7")))
        .padding()
}
