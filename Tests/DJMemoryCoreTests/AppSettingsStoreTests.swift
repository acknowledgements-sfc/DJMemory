import XCTest
@testable import DJMemoryCore

final class AppSettingsStoreTests: XCTestCase {
    private var tempRoot: URL!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("DJMemoryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
        tempRoot = nil
    }

    func testLoadReturnsDefaultWhenSettingsFileDoesNotExist() throws {
        let store = AppSettingsStore(storageURL: tempRoot.appendingPathComponent("settings.json"))

        XCTAssertEqual(try store.load(), .default)
    }

    func testSavePersistsSettings() throws {
        let store = AppSettingsStore(storageURL: tempRoot.appendingPathComponent("settings.json"))
        let settings = AppSettings(
            automaticScanningEnabled: false,
            scanIntervalSeconds: 300,
            archiveNamingTemplate: "{date} - {app} - {source}"
        )

        try store.save(settings)

        XCTAssertEqual(try store.load(), settings)
    }

    func testLoadLegacySettingsDefaultsArchiveNamingTemplate() throws {
        let store = AppSettingsStore(storageURL: tempRoot.appendingPathComponent("settings.json"))
        let json = """
        {
          "automaticScanningEnabled" : true,
          "scanIntervalSeconds" : 60
        }
        """
        try Data(json.utf8).write(to: store.storageURL)

        let settings = try store.load()

        XCTAssertEqual(settings.archiveNamingTemplate, AppSettings.defaultArchiveNamingTemplate)
    }
}
