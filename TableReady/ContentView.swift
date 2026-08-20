//
//  ContentView.swift
//  TableReady
//
//  Created by Ramya Kailas on 8/19/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(MenuStore.self) private var store
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Menu", systemImage: "calendar", value: 0) {
                WeeklyMenuView()
            }

            Tab("Groceries", systemImage: "cart", value: 1) {
                GroceryListView(items: store.groceryItems)
            }

            Tab("Family", systemImage: "person.3", value: 2) {
                FamilyView(members: SampleData.familyMembers)
            }
        }
    }
}

// MARK: - Previews

#Preview("Full App") {
    ContentView()
        .environment(MenuStore(sampleData: true))
}

#Preview("Menu Tab") {
    WeeklyMenuView()
        .environment(MenuStore(sampleData: true))
}

#Preview("Groceries Tab") {
    GroceryListView(items: SampleData.groceryItems)
}

#Preview("Family Tab") {
    FamilyView(members: SampleData.familyMembers)
}
