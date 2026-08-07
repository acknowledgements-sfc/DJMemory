import Foundation

public enum StringDecoding {
    public static func decodedEntities(_ value: String) -> String {
        guard value.contains("&") else { return value }

        let data = Data(value.utf8)
        let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )

        return attributed?.string ?? value
    }
}
