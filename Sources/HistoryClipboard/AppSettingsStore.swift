import Foundation
import ServiceManagement

final class AppSettingsStore: ObservableObject {
    static let allowedRetentionDays = [1, 3, 5]

    @Published var retentionDays: Int {
        didSet {
            if !Self.allowedRetentionDays.contains(retentionDays) {
                retentionDays = oldValue
                return
            }

            defaults.set(retentionDays, forKey: Self.retentionDaysKey)
        }
    }

    @Published var isRecordingPaused: Bool {
        didSet {
            defaults.set(isRecordingPaused, forKey: Self.isRecordingPausedKey)
        }
    }

    @Published private(set) var launchAtLogin: Bool

    private static let retentionDaysKey = "retentionDays"
    private static let isRecordingPausedKey = "isRecordingPaused"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let savedValue = defaults.integer(forKey: Self.retentionDaysKey)
        self.retentionDays = Self.allowedRetentionDays.contains(savedValue) ? savedValue : 3
        self.isRecordingPaused = defaults.bool(forKey: Self.isRecordingPausedKey)
        self.launchAtLogin = Self.currentLaunchAtLoginStatus()
    }

    @discardableResult
    func setLaunchAtLogin(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }

            launchAtLogin = Self.currentLaunchAtLoginStatus()
            return launchAtLogin == enabled
        } catch {
            launchAtLogin = Self.currentLaunchAtLoginStatus()
            return false
        }
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLogin = Self.currentLaunchAtLoginStatus()
    }

    private static func currentLaunchAtLoginStatus() -> Bool {
        SMAppService.mainApp.status == .enabled
    }
}
