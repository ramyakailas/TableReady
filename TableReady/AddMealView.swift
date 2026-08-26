//
//  AddMealView.swift
//  TableReady
//

import SwiftUI

struct AddMenuView: View {
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var items: [MenuItem]
    @State private var newItem: String = ""
    @State private var chaiCount: Int
    @State private var selectedDay: DayOfWeek?

    private var computedEffort: MenuEffort {
        DayMenu(id: 0, items: items, chaiCount: 0).effort
    }

    init(menu: DayMenu? = nil, day: DayOfWeek? = nil) {
        _items = State(initialValue: menu?.items ?? [])
        _chaiCount = State(initialValue: menu?.chaiCount ?? 2)
        _selectedDay = State(initialValue: day)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Menu Info") {
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

                Section {
                    ForEach(items) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            if let quantity = item.quantity {
                                Text("\u{00D7}\(quantity)")
                                    .foregroundColor(.secondary)
                            }
                            Text(item.category.displayName)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppTheme.chaiBrown.opacity(0.08))
                                .foregroundColor(AppTheme.chaiBrown.opacity(0.6))
                                .clipShape(Capsule())
                        }
                    }
                    .onDelete { indexSet in
                        items.remove(atOffsets: indexSet)
                    }
                    HStack {
                        TextField("e.g. 5 parathas, Palak Paneer", text: $newItem)
                            .onSubmit(addItem)
                        Button(action: addItem) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AppTheme.chaiBrown)
                                .font(.title2)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(.borderless)
                        .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityLabel("Confirm Add Item")
                    }
                } header: {
                    Text("Items")
                } footer: {
                    Text("Category and quantity are detected automatically (e.g. \"5 parathas\" becomes a Bread item, quantity 5).")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.warmCream)
            .navigationTitle("New Menu")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
        guard !trimmed.isEmpty else { return }
        items.append(contentsOf: MenuItem.parseItems(from: trimmed))
        newItem = ""
    }

    private func saveMenu() {
        let menu = DayMenu(
            id: store.nextMenuID,
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
