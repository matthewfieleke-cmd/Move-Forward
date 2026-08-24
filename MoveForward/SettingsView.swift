import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var confirmRestore = false
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            List {
                Section("Move Forward") {
                    Text("A predetermined visit timer for clinic days. Components advance on their planned schedule. The visit continues after you leave the room.")
                        .foregroundStyle(.secondary)
                }

                Section("Apple Watch") {
                    LabeledContent("Status", value: store.watchStatus.title)
                    LabeledContent("Notifications", value: store.notificationStatus)
                    Text(store.watchStatus.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Enable notifications and haptics on Apple Watch. Silent Mode with haptics on keeps cues on the wrist without sound.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Focus modes can still suppress alerts. Move Forward uses normal system notifications and cannot override those settings.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Send test watch alert") {
                        store.sendTestWatchAlert()
                    }
                    if let result = store.testAlertStatus {
                        Text(result)
                            .font(.footnote)
                            .foregroundStyle(store.watchStatus.isReady ? Palette.tealDeep : Palette.amber)
                    }
                    if store.notificationsNeedSystemSettings {
                        Button("Open notification settings") { openSystemSettings() }
                    } else {
                        Button("Allow notifications") {
                            Task { await store.requestNotificationPermission() }
                        }
                    }
                    Text("Apple Watch has its own switch. On iPhone open Watch → Notifications → Move Forward and choose Custom → Allow Notifications.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("iPhone Live Activity") {
                    Toggle("Show Live Activity", isOn: liveActivityBinding)
                    Text("Adds the visit to the iPhone Lock Screen and Dynamic Island. Apple Watch also mirrors it as a card with an Open on iPhone button, which is why this is off by default. Your watch app and its wrist taps work either way.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Appearance") {
                    Picker("Appearance", selection: appearanceBinding) {
                        Text("System").tag(AppearancePreference.system)
                        Text("Light").tag(AppearancePreference.light)
                        Text("Dark").tag(AppearancePreference.dark)
                    }
                }

                Section("Templates") {
                    Button("Restore starter templates") { confirmRestore = true }
                    Button("Remove local app data", role: .destructive) { confirmReset = true }
                }

                Section("Privacy") {
                    Text("Move Forward stays on this iPhone and Apple Watch. It does not collect patient names, medical record numbers, location, HealthKit data, or analytics.")
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    LabeledContent("App", value: "Move Forward")
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    Text("A calm clinic companion for keeping visits on a planned cadence.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Restore starter templates?", isPresented: $confirmRestore, titleVisibility: .visible) {
                Button("Restore") { store.restoreStarterTemplates() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The four starter templates will be restored or reset. Your other templates remain.")
            }
            .confirmationDialog("Remove local app data?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Remove data", role: .destructive) {
                    Task { await store.resetAllData() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Templates, visit history, and the current timer will be cleared from this device.")
            }
        }
    }

    private func openSystemSettings() {
        #if canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #endif
    }

    private var liveActivityBinding: Binding<Bool> {
        Binding(
            get: { store.settings.livesActivityEnabled },
            set: { store.setShowsLiveActivity($0) }
        )
    }

    private var appearanceBinding: Binding<AppearancePreference> {
        Binding(
            get: { store.settings.appearance },
            set: { store.setAppearance($0) }
        )
    }
}
