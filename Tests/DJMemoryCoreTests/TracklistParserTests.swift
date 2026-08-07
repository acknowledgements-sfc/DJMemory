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

    func testSeratoHistoryParserReadsNameColumnAsTitleAndSkipsSessionSummary() throws {
        let csv = """
        "name","start time","end time","playtime","deck","notes","added","comment","","bitrate","location"
        "4/9/22","4/9/22, 7:55:45 PM PDT","4/10/22, 12:20:16 PM PDT","16:24:31","","","","","","",""
        "Dang! (feat. Anderson .Paak)","7:55:45 PM PDT","7:58:06 PM PDT","00:02:21","1","","","","","",""
        "TRACK UNO","7:56:15 PM PDT","8:01:15 PM PDT","00:05:00","2","","","","","",""
        """

        let tracks = try SeratoHistoryParser().parse(data: Data(csv.utf8), sourceName: "4-9-22.csv")

        XCTAssertEqual(tracks.count, 2)
        XCTAssertEqual(tracks.first?.artist, "")
        XCTAssertEqual(tracks.first?.title, "Dang! (feat. Anderson .Paak)")
        XCTAssertEqual(tracks.first?.startTime, "7:55:45 PM PDT")
    }

    func testDelimitedParserDecodesHtmlEntities() throws {
        let csv = """
        name,start time
        Big Pimpin&#39;,8:11:00 PM PDT
        """

        let tracks = try SeratoHistoryParser().parse(data: Data(csv.utf8), sourceName: "test.csv")

        XCTAssertEqual(tracks.first?.title, "Big Pimpin'")
    }

    func testRekordboxXMLParserReadsCollectionTracks() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <DJ_PLAYLISTS Version="1.0.0">
          <COLLECTION Entries="2">
            <TRACK TrackID="1" Name="Plastic Dreams" Artist="Jaydee" />
            <TRACK TrackID="2" Name="Deep Inside" Artist="Hardrive" />
          </COLLECTION>
        </DJ_PLAYLISTS>
        """

        let tracks = try RekordboxXMLParser().parse(data: Data(xml.utf8), sourceName: "rekordbox.xml")

        XCTAssertEqual(tracks.count, 2)
        XCTAssertEqual(tracks.first?.title, "Plastic Dreams")
        XCTAssertEqual(tracks.first?.artist, "Jaydee")
        XCTAssertEqual(tracks.first?.source, "rekordbox.xml")
    }
}
