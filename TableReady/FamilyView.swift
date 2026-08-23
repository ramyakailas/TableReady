//
//  FamilyView.swift
//  TableReady
//

import SwiftUI

struct FamilyView: View {
    var members: [FamilyMember]

    var body: some View {
        NavigationStack {
            List {
                ForEach(members) { member in
                    HStack(spacing: 14) {
                        Text(member.emoji)
                            .font(.largeTitle)
                            .frame(width: 50, height: 50)
                            .background(AppTheme.turmeric.opacity(0.15))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(member.name)
                                .font(.headline)
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
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.warmCream)
            .navigationTitle("Family")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Family Member")
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Family Members") {
    FamilyView(members: SampleData.familyMembers)
}

#Preview("Empty Family") {
    FamilyView(members: [])
}

#Preview("Single Member") {
    FamilyView(members: [SampleData.familyMembers[0]])
}
