//
//  ImportMenuView.swift
//  TableReady
//

import SwiftUI

struct ImportMenuView: View {
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var markdownText: String = ""
    @State private var result: MenuImportResult?

    private var isEmpty: Bool {
        markdownText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $markdownText)
                        .frame(minHeight: 220)
                        .font(.system(.body, design: .monospaced))
                        .disabled(result != nil)
                } header: {
                    Text("Paste Menu Set")
                } footer: {
                    Text("""
                    One menu per block:

                    ## 1 | light — 5 breads
                    - Dish name
                    - 5 parathas
                    - 2 chais

                    Each new menu is auto-assigned to an open day and its dishes are added to the Dish Library. Menus that exactly match one already saved are skipped.
                    """)
                }

                if let result {
                    Section("Import Result") {
                        Label("\(result.menusAdded) menu\(result.menusAdded == 1 ? "" : "s") added", systemImage: "checkmark.circle")
                            .foregroundColor(AppTheme.herbGreen)
                        if result.dishesAdded > 0 {
                            Label("\(result.dishesAdded) new dish\(result.dishesAdded == 1 ? "" : "es") added to library", systemImage: "fork.knife")
                        }
                        if result.menusSkipped > 0 {
                            Label("\(result.menusSkipped) duplicate\(result.menusSkipped == 1 ? "" : "s") skipped", systemImage: "arrow.triangle.2.circlepath")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.warmCream)
            .navigationTitle("Import Menus")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(result == nil ? "Cancel" : "Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if result == nil {
                        Button("Import") {
                            result = store.importMenus(from: markdownText)
                        }
                        .disabled(isEmpty)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Import Menus") {
    ImportMenuView()
        .environment(MenuStore(sampleData: true))
}
