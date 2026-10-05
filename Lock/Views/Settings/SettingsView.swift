import FamilyControls
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var isPickerPresented = false
    @State private var selection = FamilyActivitySelection()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $model.isBetaModeEnabled) {
                        SettingsRow(
                            icon: "slider.horizontal.3",
                            title: "Beta mode",
                            subtitle: "Practice without blocking apps."
                        )
                    }
                    .tint(.primary)
                } footer: {
                    Text("Turn this off when you want the real key and real app blocking.")
                }

                Section("Setup") {
                    Button {
                        isPickerPresented = true
                    } label: {
                        SettingsRow(
                            icon: "app.badge.checkmark",
                            title: "Blocked apps",
                            subtitle: "Choose what Lock can block."
                        )
                    }

                    Button {
                        Task { await model.registerTag() }
                    } label: {
                        SettingsRow(
                            icon: "wave.3.right",
                            title: "NFC key",
                            subtitle: model.hasRegisteredTag ? "Reconnect your physical key." : "Connect your physical key."
                        )
                    }

                    Button {
                        Task { await model.requestAuthorization() }
                    } label: {
                        SettingsRow(
                            icon: "hourglass.badge.checkmark",
                            title: "Screen Time access",
                            subtitle: "Ask iOS for permission again."
                        )
                    }
                }

                Section("Recovery") {
                    Button(role: .destructive) {
                        Task { await model.unlockWithoutNFCForRecovery() }
                    } label: {
                        SettingsRow(
                            icon: "lock.open",
                            title: "Unlock now",
                            subtitle: "Turn blocking off immediately."
                        )
                    }
                } footer: {
                    Text("Use this if you lose the key. Lock only reads the key while the app is open.")
                }

                Section("About") {
                    Text("One physical key for your digital distractions.")
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
            .onAppear {
                selection = model.blockingService.selection
            }
            .onChange(of: selection) { _, newValue in
                model.blockingService.selection = newValue
            }
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 21, weight: .semibold))
                .frame(width: 36, height: 36)
                .background(Color.primary.opacity(0.08), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .foregroundStyle(.primary)
        }
        .padding(.vertical, 7)
    }
}
