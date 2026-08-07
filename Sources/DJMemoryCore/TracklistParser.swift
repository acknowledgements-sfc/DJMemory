import Foundation

public enum TracklistParserError: Error, Equatable {
    case unreadableText
}

public protocol TracklistParser {
    func parse(data: Data, sourceName: String) throws -> [TrackPlay]
}

public struct DelimitedTracklistParser: TracklistParser {
    public init() {}

    public func parse(data: Data, sourceName: String) throws -> [TrackPlay] {
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .macOSRoman) else {
            throw TracklistParserError.unreadableText
        }

        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let firstLine = lines.first else {
            return []
        }

        let delimiter = detectDelimiter(in: firstLine)
        let rows = lines.map { parseLine($0, delimiter: delimiter) }
        let header = normalizedHeader(from: rows.first ?? [])
        let dataRows = header.isEmpty ? rows : Array(rows.dropFirst())

        return dataRows.compactMap { row in
            trackPlay(from: row, header: header, sourceName: sourceName)
        }
    }

    private func detectDelimiter(in line: String) -> Character {
        let candidates: [Character] = [",", "\t", ";"]
        return candidates.max { lhs, rhs in
            line.filter { $0 == lhs }.count < line.filter { $0 == rhs }.count
        } ?? ","
    }

    private func normalizedHeader(from row: [String]) -> [String: Int] {
        let normalized = row.map { $0.lowercased().replacingOccurrences(of: " ", with: "") }
        let knownHeaderTerms = ["artist", "title", "track", "song", "start", "time", "playedat", "name"]

        guard normalized.contains(where: { value in knownHeaderTerms.contains { value.contains($0) } }) else {
            return [:]
        }

        return Dictionary(uniqueKeysWithValues: normalized.enumerated().map { ($0.element, $0.offset) })
    }

    private func trackPlay(from row: [String], header: [String: Int], sourceName: String) -> TrackPlay? {
        let artist = value(from: row, header: header, keys: ["artist", "artists"]) ?? (header.isEmpty ? fallback(row: row, index: 0) : nil)
        let title = value(from: row, header: header, keys: ["title", "track", "song", "name"]) ?? fallback(row: row, index: header.isEmpty ? 1 : 0)
        let startTime = value(from: row, header: header, keys: ["starttime", "time", "playedat"]) ?? inferredStartTime(from: row)

        guard let title, !title.isEmpty else {
            return nil
        }

        return TrackPlay(
            title: StringDecoding.decodedEntities(title),
            artist: StringDecoding.decodedEntities(artist ?? ""),
            startTime: startTime,
            source: sourceName,
            confidence: header.isEmpty ? 0.55 : 0.85
        )
    }

    private func value(from row: [String], header: [String: Int], keys: [String]) -> String? {
        for key in keys {
            if let match = header.first(where: { $0.key.contains(key) }), row.indices.contains(match.value) {
                let value = row[match.value].trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty { return value }
            }
        }

        return nil
    }

    private func fallback(row: [String], index: Int) -> String? {
        guard row.indices.contains(index) else { return nil }
        let value = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func inferredStartTime(from row: [String]) -> String? {
        row.first { value in
            value.range(of: #"^\d{1,2}:\d{2}(:\d{2})?$"#, options: .regularExpression) != nil
        }
    }

    private func parseLine(_ line: String, delimiter: Character) -> [String] {
        var values: [String] = []
        var current = ""
        var isQuoted = false

        for character in line {
            if character == "\"" {
                isQuoted.toggle()
            } else if character == delimiter && !isQuoted {
                values.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            } else {
                current.append(character)
            }
        }

        values.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        return values
    }
}

public struct SeratoHistoryParser: TracklistParser {
    private let parser: DelimitedTracklistParser

    public init(parser: DelimitedTracklistParser = DelimitedTracklistParser()) {
        self.parser = parser
    }

    public func parse(data: Data, sourceName: String = "Serato History") throws -> [TrackPlay] {
        try parser.parse(data: data, sourceName: sourceName).filter { track in
            !isSessionSummaryRow(track)
        }
    }

    private func isSessionSummaryRow(_ track: TrackPlay) -> Bool {
        guard track.artist.isEmpty else { return false }

        let dateLikeTitle = track.title.range(
            of: #"^\d{1,2}/\d{1,2}/\d{2,4}$"#,
            options: .regularExpression
        ) != nil

        let dateLikeStart = track.startTime?.contains(",") == true

        return dateLikeTitle && dateLikeStart
    }
}

public final class RekordboxXMLParser: NSObject, TracklistParser, XMLParserDelegate {
    private var tracks: [TrackPlay] = []
    private var sourceName = "rekordbox XML"

    public override init() {}

    public func parse(data: Data, sourceName: String = "rekordbox XML") throws -> [TrackPlay] {
        self.tracks = []
        self.sourceName = sourceName

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        return tracks
    }

    public func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        guard elementName.uppercased() == "TRACK" else { return }

        let title = attributeDict["Name"] ?? attributeDict["TrackName"] ?? attributeDict["Title"]
        let artist = attributeDict["Artist"] ?? attributeDict["ArtistName"] ?? ""

        guard let title, !title.isEmpty else { return }

        tracks.append(
            TrackPlay(
                title: StringDecoding.decodedEntities(title),
                artist: StringDecoding.decodedEntities(artist),
                startTime: nil,
                source: sourceName,
                confidence: 0.8
            )
        )
    }
}
