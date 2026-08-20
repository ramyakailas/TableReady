//
//  MealDetailView.swift
//  TableReady
//

import SwiftUI

struct MenuDetailView: View {
    let menu: DayMenu

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "list.clipboard")
                        .font(.title)
                        .foregroundColor(.accentColor)
                        .frame(width: 56, height: 56)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    Text("Menu #\(menu.id)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                )

                // Quick stats
                HStack(spacing: 0) {
                    StatBox(value: "\(menu.items.count)", label: "Items", icon: "list.bullet")
                    Divider().frame(height: 40)
                    StatBox(value: "\(menu.breadCount)", label: "Breads", icon: "birthday.cake")
                    Divider().frame(height: 40)
                    StatBox(value: "\(menu.chaiCount)", label: "Chai", icon: "cup.and.saucer.fill")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground))
                )

                // Items
                VStack(alignment: .leading, spacing: 8) {
                    Text("Items")
                        .font(.headline)

                    ForEach(Array(menu.items.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                                .frame(width: 24, height: 24)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(Circle())
                            Text(item)
                                .font(.body)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Menu Details")
        .navigationBarTitleDisplayMode(.inline)
    }

}

struct StatBox: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.accentColor)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#Preview("Light Menu") {
    NavigationStack {
        MenuDetailView(menu: SampleData.menus[0])
    }
}

#Preview("Heavy Menu") {
    NavigationStack {
        MenuDetailView(menu: SampleData.menus[1])
    }
}

#Preview("Medium Menu") {
    NavigationStack {
        MenuDetailView(menu: SampleData.menus[4])
    }
}
