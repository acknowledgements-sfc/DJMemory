import XCTest
@testable import DJMemoryCore

final class TracklistParserTests: XCTestCase {
    func testDelimitedParserReadsCsvWithHeader() throws {
        let csv = """
        artist,title,start time
        Inner City,Good Life,00:00
        Robin S,Show Me Love,04:12
        """

        let tracks = try DelimitedTracklistParser().parse(data: Data(csv.utf8), sourceName: "test.csv")

        XCTAssertEqual(tracks.count, 2)
        XCTAssertEqual(tracks.first?.artist, "Inner City")
        XCTAssertEqual(tracks.first?.title, "Good Life")
        XCTAssertEqual(tracks.first?.startTime, "00:00")
    }

    func testDelimitedParserReadsTabSeparatedText() throws {
        let text = """
        Artist\tTrack\tTime
        Moodymann\tShades of Jae\t12:01
        """

        let tracks = try DelimitedTracklistParser().parse(data: Data(text.utf8), sourceName: "test.txt")

        XCTAssertEqual(tracks.count, 1)
        XCTAssertEqual(tracks.first?.artist, "Moodymann")
        XCTAssertEqual(tracks.first?.title, "Shades of Jae")
    }

    func testSeratoHistoryParserUsesDelimitedParser() throws {
        let csv = """
        artist,title
        Stardust,Music Sounds Better With You
        """

        let tracks = try SeratoHistoryParser().parse(data: Data(csv.utf8))

        XCTAssertEqual(tracks.first?.source, "Serato History")
        XCTAssertEqual(tracks.first?.title, "Music Sounds Better With You")
    }
}
