//
//  AboutSheet.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 31/10/25.
//

import SwiftUI

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    private let githubURL = "https://github.com/ImaginativeShohag/ZeroDevCleaner"

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                // App Icon
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 128, height: 128)
                    .shadow(radius: 10)

                // App Name
                Text("ZeroDevCleaner")
                    .font(.system(size: 28, weight: .bold))

                // Tagline
                Text("A native macOS app to reclaim disk space")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("by cleaning build artifacts and developer caches")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // Version
                Text("Version \(appVersion) (\(appBuild))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 32)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)

            Divider()

            // Info Section
            VStack(spacing: 16) {
                // License
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.blue)
                        .frame(width: 20)
                    Text("License")
                        .fontWeight(.medium)
                    Spacer()
                    Text("MIT License")
                        .foregroundStyle(.secondary)
                }

                Divider()

                // GitHub
                HStack {
                    Image(systemName: "link")
                        .foregroundStyle(.blue)
                        .frame(width: 20)
                    Text("GitHub")
                        .fontWeight(.medium)
                    Spacer()
                    Button {
                        if let url = URL(string: githubURL) {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Text("View on GitHub")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(scale: 1.05, brightness: 0.1)
                }

                Divider()

                // Report Issue
                HStack {
                    Image(systemName: "exclamationmark.bubble")
                        .foregroundStyle(.blue)
                        .frame(width: 20)
                    Text("Support")
                        .fontWeight(.medium)
                    Spacer()
                    Button {
                        if let url = URL(string: "\(githubURL)/issues/new") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Text("Report an Issue")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(scale: 1.05, brightness: 0.1)
                }

                Divider()

                // Copyright
                HStack {
                    Image(systemName: "c.circle")
                        .foregroundStyle(.blue)
                        .frame(width: 20)
                    Text("Copyright")
                        .fontWeight(.medium)
                    Spacer()
                    Text("2025 Md. Mahmudul Hasan Shohag")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)

            Divider()

            // Footer
            VStack(spacing: 8) {
                Text("Made with ❤️ for developers who love clean disks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("Free and open source forever")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 16)

            Divider()

            // Close Button
            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .buttonHoverEffect()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
        }
        .frame(width: 500)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

#Preview {
    AboutSheet()
}
