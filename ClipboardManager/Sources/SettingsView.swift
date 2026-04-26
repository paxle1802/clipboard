import KeyboardShortcuts
import ServiceManagement
import SwiftUI

// Settings panel with hotkey recorder, launch at login toggle, and max items slider
struct SettingsView: View {
    let store: ClipboardStore
    @State private var launchAtLogin = false
    @State private var maxItems: Double = 500

    var body: some View {
        Form {
            Section("Keyboard Shortcut") {
                KeyboardShortcuts.Recorder(
                    "Toggle Clipboard History:", name: .toggleClipboardHistory)
            }

            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                        }
                    }

                HStack {
                    Text("Max history items:")
                    Slider(value: $maxItems, in: 50...2000, step: 50)
                    Text("\(Int(maxItems))")
                        .frame(width: 40)
                        .monospacedDigit()
                }
                .onChange(of: maxItems) { _, newValue in
                    store.maxItems = Int(newValue)
                }
            }

            Section("Data") {
                HStack {
                    Text("Current items: \(store.items.count)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Clear All History") {
                        store.clear()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 400, height: 280)
        .onAppear {
            maxItems = Double(store.maxItems)
            launchAtLogin =
                SMAppService.mainApp.status == .enabled
        }
    }
}
