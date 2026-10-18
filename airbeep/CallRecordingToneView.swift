import SwiftUI
import UIKit

struct AirBeepRootView: View {
    @StateObject private var service = CallRecordingToneService.shared
    @State private var showingAbout = false
    @State private var showingAirliftSetup = false

    var body: some View {
        // لێرەدا TabView زیادکرا
        TabView {
            // تاب ١: شاشەی سەرەکی (کۆدی پێشوو)
            NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        header
                        if let busyMessage = service.busyMessage {
                            busyWarning(message: busyMessage)
                        }
                        if service.needsAirliftSetup {
                            airliftSetupCard
                        }
                        toneActions
                        details
                    }
                    .padding(20)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("AirBeep")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAbout = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        .accessibilityLabel("About")
                    }
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .onAppear {
                service.refresh()
            }
            .sheet(isPresented: $showingAbout) {
                AirBeepAboutView()
            }
            .sheet(isPresented: $showingAirliftSetup, onDismiss: {
                service.refresh()
            }) {
                AirBeepAirliftSetupView()
            }
            .alert(
                "Operation Failed",
                isPresented: Binding(
                    get: { service.lastError != nil },
                    set: { presented in
                        if !presented { service.clearError() }
                    }
                )
            ) {
                Button("OK") { service.clearError() }
            } message: {
                Text(service.lastError ?? "")
            }
            .alert(
                "Done",
                isPresented: Binding(
                    get: { service.successMessage != nil },
                    set: { presented in
                        if !presented { service.clearSuccess() }
                    }
                )
            ) {
                Button("OK") { service.clearSuccess() }
            } message: {
                Text(service.successMessage ?? "")
            }
            
            // ✅ تاب ٢: شاشەی فایلەکان کە زیادمان کرد
            FilesView()
                .tabItem {
                    Label("Files", systemImage: "folder.fill")
                }
        }
    }

    // --- بەشەکانی خوارەوە هەمان کۆدی پێشوون و دەستکاری نەکراون ---

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.orange.gradient)
                    .frame(width: 88, height: 88)
                Image(systemName: "waveform.badge.mic")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("Call Recording Tone")
                .font(.title2.bold())
            Text("Back up the original disclosure tones so you can restore them at any time.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(verbatim: versionLine)
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var versionLine: String {
        let system = ProcessInfo.processInfo.operatingSystemVersion
        let platform = UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS" : "iOS"
        let systemText = "\(platform) \(system.majorVersion).\(system.minorVersion).\(system.patchVersion)"
        return "\(systemText)  AirBeep v\(appVersion)"
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        guard !version.isEmpty else { return build }
        guard !build.isEmpty else { return version }
        return "\(version) (\(build))"
    }

    private var toneActions: some View {
        VStack(spacing: 14) {
            if service.backupReady {
                Button {
                    Task { await service.restoreSystemTone() }
                } label: {
                    Label("Restore original tone", systemImage: "arrow.uturn.backward.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(service.isBusy)
            } else {
                Button {
                    Task { await service.backupOriginalTones() }
                } label: {
                    Label("Back Up Original Tones", systemImage: "square.and.arrow.down.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(service.isBusy)

                Text("Original tones are backed up before the first change.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if service.isBusy {
                ProgressView()
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
    }

    private func busyWarning(message: String) -> some View {
        Label {
            Text(message)
                .font(.headline)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.red.opacity(0.12), in: .rect(cornerRadius: 16))
    }

    private var airliftSetupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Airlift Setup Required", systemImage: "link.badge.plus")
                .font(.headline)

            Text("Pair this iPhone and connect LocalDevVPN to allow AirBeep to access the recording tone files.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                showingAirliftSetup = true
            } label: {
                Label("Open Airlift Setup", systemImage: "gearshape")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("This build only backs up and restores the original disclosure tones; it does not silence them.", systemImage: "checkmark.shield")
            Label("Changing the system language will force the original tones back.", systemImage: "globe")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AirBeepRootView()
}
