import SwiftUI
import AppKit

struct OnboardingView: View {
    var onComplete: () -> Void
    @State private var currentPage = 0

    private let totalPages = 4

    var body: some View {
        VStack(spacing: 0) {
            // Page content
            Group {
                switch currentPage {
                case 0: welcomePage
                case 1: featuresPage
                case 2: permissionsPage
                case 3: getStartedPage
                default: welcomePage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Navigation footer
            HStack {
                if currentPage > 0 {
                    Button("Previous") {
                        currentPage -= 1
                    }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                } else {
                    Spacer()
                        .frame(width: 80)
                }

                Spacer()

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.4))
                            .frame(width: 7, height: 7)
                    }
                }

                Spacer()

                if currentPage < totalPages - 1 {
                    Button("Next") {
                        currentPage += 1
                    }
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        onComplete()
                        NSApp.keyWindow?.close()
                    }
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 480, height: 360)
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 80, height: 80)

            Text("Welcome to Beacon")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Beacon helps you find your cursor with crosshair overlays, spotlight mode, and ping.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
        }
        .padding(.top, 32)
    }

    // MARK: - Page 2: Features Overview

    private var featuresPage: some View {
        VStack(spacing: 24) {
            Text("What Beacon Does")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 16) {
                featureRow(
                    symbol: "scope",
                    title: "Crosshair",
                    description: "A crosshair follows your cursor across all screens"
                )
                featureRow(
                    symbol: "circle.dashed",
                    title: "Spotlight",
                    description: "Spotlight mode dims everything except around your cursor"
                )
                featureRow(
                    symbol: "target",
                    title: "Ping",
                    description: "Press \u{2318}0 to center your cursor and show a ripple animation"
                )
            }
            .padding(.horizontal, 32)
        }
        .padding(.top, 24)
    }

    private func featureRow(symbol: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Page 3: Accessibility Permission

    private var permissionsPage: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text("Accessibility Access")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Beacon needs Accessibility access for the Ping feature to center your cursor. Without it, Ping will show the ripple animation but won't move your cursor.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Button("Open Accessibility Settings") {
                NSWorkspace.shared.open(
                    URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                )
            }
            .buttonStyle(.bordered)

            Text("If Beacon isn't listed, click the + button to add it.\nYou can skip this — Ping will still show the ripple animation.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 16)
    }

    // MARK: - Page 4: Get Started

    private var getStartedPage: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.green)

            Text("You're all set!")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 8) {
                tipRow(symbol: "menubar.dock.rectangle", text: "Beacon lives in your menu bar — look for the \u{2318} scope icon")
                tipRow(symbol: "target", text: "Press \u{2318}0 anytime to find your cursor")
                tipRow(symbol: "slider.horizontal.3", text: "Open Settings to customize colors, thickness, and more")
            }
            .padding(.horizontal, 32)
        }
        .padding(.top, 24)
    }

    private func tipRow(symbol: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
