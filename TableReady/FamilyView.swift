//
//  FamilyView.swift
//  TableReady
//

import SwiftUI

struct FamilyView: View {
    @Environment(MenuStore.self) private var store
    @State private var showAddMember = false
    @State private var editingMember: FamilyMember?

    var body: some View {
        NavigationStack {
            Group {
                if store.familyMembers.isEmpty {
                    ContentUnavailableView {
                        Label("No Family Members", systemImage: "person.3")
                            .foregroundColor(AppTheme.chaiBrown)
                    } description: {
                        Text("Add the people you're planning meals for")
                            .foregroundColor(AppTheme.chaiBrownMuted)
                    } actions: {
                        Button("Add Family Member") {
                            showAddMember = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.chaiBrown)
                    }
                } else {
                    List {
                        ForEach(store.familyMembers) { member in
                            Button {
                                editingMember = member
                            } label: {
                                HStack(spacing: 14) {
                                    Text(member.emoji)
                                        .font(.largeTitle)
                                        .frame(width: 50, height: 50)
                                        .background(AppTheme.turmeric.opacity(0.15))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(member.name)
                                            .font(.headline)
                                            .foregroundColor(AppTheme.chaiBrown)
                                        if !member.dietaryNotes.isEmpty {
                                            Label(member.dietaryNotes, systemImage: "exclamationmark.triangle")
                                                .font(.caption)
                                                .foregroundColor(AppTheme.saffronText)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .accessibilityHidden(true)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                store.removeFamilyMember(store.familyMembers[index])
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.warmCream)
                }
            }
            .navigationTitle("Family")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddMember = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Family Member")
                }
            }
            .sheet(isPresented: $showAddMember) {
                FamilyMemberEditorView()
                    .environment(store)
            }
            .sheet(item: $editingMember) { member in
                FamilyMemberEditorView(member: member)
                    .environment(store)
            }
        }
    }
}

// MARK: - Family Member Editor

struct FamilyMemberEditorView: View {
    @Environment(MenuStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var emoji: String
    @State private var dietaryNotes: String
    private let existingID: UUID?

    init(member: FamilyMember? = nil) {
        _name = State(initialValue: member?.name ?? "")
        _emoji = State(initialValue: member?.emoji ?? "🧑")
        _dietaryNotes = State(initialValue: member?.dietaryNotes ?? "")
        existingID = member?.id
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Mom", text: $name)
                }
                Section("Emoji") {
                    TextField("🧑", text: $emoji)
                }
                Section("Dietary Notes") {
                    TextField("e.g. No shellfish (optional)", text: $dietaryNotes)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.warmCream)
            .navigationTitle(existingID == nil ? "New Family Member" : "Edit Family Member")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespaces)
                        let member = FamilyMember(
                            id: existingID ?? UUID(),
                            name: trimmedName,
                            emoji: trimmedEmoji.isEmpty ? "🧑" : trimmedEmoji,
                            dietaryNotes: dietaryNotes.trimmingCharacters(in: .whitespaces)
                        )
                        if existingID != nil {
                            store.updateFamilyMember(member)
                        } else {
                            store.addFamilyMember(member)
                        }
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Family Members") {
    FamilyView()
        .environment(MenuStore(sampleData: true))
}

#Preview("Empty Family") {
    let store = MenuStore(sampleData: true)
    store.familyMembers = []
    return FamilyView()
        .environment(store)
}

#Preview("Add Family Member") {
    FamilyMemberEditorView()
        .environment(MenuStore(sampleData: true))
}

#Preview("Edit Family Member") {
    FamilyMemberEditorView(member: SampleData.familyMembers[0])
        .environment(MenuStore(sampleData: true))
}
