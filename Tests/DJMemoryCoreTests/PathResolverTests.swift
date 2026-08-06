import XCTest
@testable import DJMemoryCore

final class PathResolverTests: XCTestCase {
    func testExpandedURLExpandsTilde() {
        let resolver = PathResolver()
        let url = resolver.expandedURL(for: "~/Music")

        XCTAssertFalse(url.path.contains("~"))
        XCTAssertTrue(url.path.hasSuffix("/Music"))
    }
}
