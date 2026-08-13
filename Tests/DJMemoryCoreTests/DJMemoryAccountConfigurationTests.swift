import XCTest
@testable import DJMemoryCore

final class DJMemoryAccountConfigurationTests: XCTestCase {
    func testDefaultAccountBaseURLIsProductionHost() {
        XCTAssertEqual(DJMemoryAccountConfiguration.baseURLString, "https://beatrevival.com")
    }

    func testClerkPublishableKeyIsOptionalByDefault() {
        XCTAssertNil(DJMemoryAccountConfiguration.clerkPublishableKey)
    }
}
