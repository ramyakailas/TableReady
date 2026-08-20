//
//  AddMealView.swift
//  TableReady
//

import SwiftUI

struct AddMenuView: View {
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var items: [String]
    @State private var newItem: String = ""
    @State private var breadCount: Int
    @State private var chaiCount: Int
    @State private var selectedDay: DayOfWeek?

    private var computedEffort: MenuEffort {
        DayMenu(id: 0, breadCount: breadCount, items: items, chaiCount: 0).effort
    }

    init(menu: DayMenu? = nil, day: DayOfWeek? = nil) {
        _items = State(initialValue: menu?.items ?? [])
        _breadCount = State(initialValue: menu?.breadCount ?? 0)
        _chaiCount = State(initialValue: menu?.chaiCount ?? 2)
        _selectedDay = State(initialValue: day)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Menu Info") {
                    Stepper("Breads: \(breadCount)", value: $breadCount, in: 0...30)
                    Stepper("Chai: \(chaiCount)", value: $chaiCount, in: 0...10)
                    HStack {
                        Text("Effort")
                            .foregroundColor(.secondary)
                        Spacer()
                        EffortBadge(effort: computedEffort)
                    }
                }

                Section("Assign to Day") {
                    Picker("Day", selection: $selectedDay) {
                        Text("None").tag(DayOfWeek?.none)
                        ForEach(DayOfWeek.allCases) { day in
                            Text(day.name).tag(DayOfWeek?.some(day))
                        }
                    }
                }

                Section("Items") {
                    ForEach(items, id: \.self) { item in
                        Text(item)
                    }
                    .onDelete { indexSet in
                        items.remove(atOffsets: indexSet)
                    }
                    HStack {
                        TextField("Add item", text: $newItem)
                        Button(action: addItem) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                        .disabled(newItem.isEmpty)
                    }
                }
            }
            .navigationTitle("New Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMenu()
                    }
                    .disabled(items.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func addItem() {
        let trimmed = newItem.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            items.append(trimmed)
            newItem = ""
        }
    }

    private func saveMenu() {
        let menu = DayMenu(
            id: store.nextMenuID,
            breadCount: breadCount,
            items: items,
            chaiCount: chaiCount
        )
        store.addMenu(menu, assignToDay: selectedDay)
        dismiss()
    }
}

// MARK: - Previews

#Preview("New Menu") {
    AddMenuView()
        .environment(MenuStore(sampleData: true))
}

#Preview("New Menu for Wednesday") {
    AddMenuView(day: .wednesday)
        .environment(MenuStore(sampleData: true))
}
