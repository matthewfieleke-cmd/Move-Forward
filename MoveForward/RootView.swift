import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if store.settings.hasCompletedOnboarding {
                TabView {
                    Tab("Timers", systemImage: "timer") {
                        TimersView()
                    }
                    Tab("Today", systemImage: "sun.horizon") {
                        TodayView()
                    }
                    Tab("Settings", systemImage: "gearshape") {
                        SettingsView()
                    }
                }
            } else {
                OnboardingView()
            }
        }
        .sheet(isPresented: $store.showChooser) {
            TemplateChooserSheet()
                .environmentObject(store)
        }
    }
}

struct TemplateChooserSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var templatePendingReplacement: VisitTemplate?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Choose a template to start. Nothing starts until you confirm.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }
                ForEach(store.sortedTemplates) { template in
                    Button {
                        start(template)
                    } label: {
                        TemplateRow(template: template, compact: true)
                    }
                    .disabled(!store.canStart(template))
                }
            }
            .navigationTitle("Start a visit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .confirmationDialog(
                "Replace the current visit?",
                isPresented: Binding(
                    get: { templatePendingReplacement != nil },
                    set: { if !$0 { templatePendingReplacement = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Start new visit", role: .destructive) {
                    if let template = templatePendingReplacement {
                        Task {
                            await store.startVisit(template, replacingExisting: true)
                            templatePendingReplacement = nil
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    templatePendingReplacement = nil
                }
            } message: {
                Text("The current timer will end without counting as a completed visit.")
            }
        }
        .presentationDetents([.large])
    }

    private func start(_ template: VisitTemplate) {
        if store.activeSession != nil {
            templatePendingReplacement = template
        } else {
            Task {
                await store.startVisit(template)
                dismiss()
            }
        }
    }
}
