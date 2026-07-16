import Foundation
import Security

/// One-shot removal of cloud credentials left behind by older FreeFlow /
/// Megaphone builds. Megaphone is on-device only and never uses these values,
/// but earlier versions persisted a Groq API key — first in the Keychain, then
/// (via a migration) as plaintext JSON in Application Support. We proactively
/// erase both on every launch so a stale secret cannot linger on disk.
enum LegacyCredentialCleanup {
    /// Accounts that older builds may have written.
    private static let legacyAccounts = ["groq_api_key", "api_base_url"]

    static func purge() {
        removePlaintextSettingsFile()
        removeKeychainItems()
    }

    /// The old `AppSettingsStorage` wrote a `.settings` JSON file that only ever
    /// held cloud credentials plus a migration marker, so removing the whole
    /// file is safe.
    private static func removePlaintextSettingsFile() {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return }

        let settingsURL = appSupport
            .appendingPathComponent(AppName.displayName, isDirectory: true)
            .appendingPathComponent(".settings")

        if FileManager.default.fileExists(atPath: settingsURL.path) {
            try? FileManager.default.removeItem(at: settingsURL)
        }
    }

    private static func removeKeychainItems() {
        let service = Bundle.main.bundleIdentifier ?? "com.kuberwastaken.megaphone"
        for account in legacyAccounts {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            SecItemDelete(query as CFDictionary)
        }
    }
}
