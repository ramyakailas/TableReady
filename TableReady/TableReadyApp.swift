//
//  TableReadyApp.swift
//  TableReady
//
//  Created by Ramya Kailas on 8/19/26.
//

import SwiftUI

@main
struct TableReadyApp: App {
    @State private var store = MenuStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .accentColor(AppTheme.turmeric)
        }
    }
}
