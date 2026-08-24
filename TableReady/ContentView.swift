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
            WeeklyMenuView()
                .tabItem {
                    Label("Menu", systemImage: "calendar")
                }
                .tag(0)

            GroceryListView(items: store.groceryItems)
                .tabItem {
                    Label("Groceries", systemImage: "cart")
                }
                .tag(1)

            DishLibraryView()
                .tabItem {
                    Label("Dishes", systemImage: "book")
                }
                .tag(2)

            FamilyView(members: SampleData.familyMembers)
                .tabItem {
                    Label("Family", systemImage: "person.3")
                }
                .tag(3)
        }
        .tint(AppTheme.chaiBrown)
        #if os(iOS)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor(AppTheme.warmCream)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        #endif
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
