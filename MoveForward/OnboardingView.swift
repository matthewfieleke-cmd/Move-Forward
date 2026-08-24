import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                onboardingPage(
                    symbol: "timer",
                    title: "Set the cadence first.",
                    bodyText: "Move Forward is a predetermined visit timer. Components run in the order you save. They do not wait for a tap, and they do not try to guess what you are doing."
                )
                onboardingPage(
                    symbol: "applewatch",
                    title: "Quiet cues on the wrist.",
                    bodyText: "Apple Watch buzzes at each component and at completion. Use Silent Mode with haptics enabled for a discreet clinic alert. Focus settings can still suppress notifications."
                )
                onboardingPage(
                    symbol: "door.left.hand.open",
                    title: "The visit continues after the room.",
                    bodyText: "Orders, ticklers, nurse handoff, and notes are part of the same visit. Mark one EXIT ROOM component so the watch can show when you leave and what remains."
                )
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                store.completeOnboarding()
            } label: {
                Text("Get started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(Palette.teal)
            .padding(24)
        }
        .background(Palette.cream.ignoresSafeArea())
    }

    private func onboardingPage(symbol: String, title: String, bodyText: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: symbol)
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(Palette.teal)
                .accessibilityHidden(true)
            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text(bodyText)
                .font(.body)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            Spacer()
        }
        .padding(28)
        .accessibilityElement(children: .combine)
    }
}
