import Foundation

enum LanguageCatalog {
    static let all: [Language] = [
        Language(code: "af", name: "Afrikaans", flag: "🇿🇦"),
        Language(code: "am", name: "Amharic", flag: "🇪🇹"),
        Language(code: "ar", name: "Arabic", flag: "🇸🇦"),
        Language(code: "az", name: "Azerbaijani", flag: "🇦🇿"),
        Language(code: "be", name: "Belarusian", flag: "🇧🇾"),
        Language(code: "bg", name: "Bulgarian", flag: "🇧🇬"),
        Language(code: "bn", name: "Bengali", flag: "🇧🇩"),
        Language(code: "bs", name: "Bosnian", flag: "🇧🇦"),
        Language(code: "ca", name: "Catalan", flag: "🇦🇩"),
        Language(code: "cs", name: "Czech", flag: "🇨🇿"),
        Language(code: "cy", name: "Welsh", flag: "🏴󠁧󠁢󠁷󠁬󠁳󠁿"),
        Language(code: "da", name: "Danish", flag: "🇩🇰"),
        Language(code: "de", name: "German", flag: "🇩🇪"),
        Language(code: "el", name: "Greek", flag: "🇬🇷"),
        Language(code: "en", name: "English", flag: "🇬🇧"),
        Language(code: "es", name: "Spanish", flag: "🇪🇸"),
        Language(code: "et", name: "Estonian", flag: "🇪🇪"),
        Language(code: "eu", name: "Basque", flag: "🇪🇸"),
        Language(code: "fa", name: "Persian", flag: "🇮🇷"),
        Language(code: "fi", name: "Finnish", flag: "🇫🇮"),
        Language(code: "fil", name: "Filipino", flag: "🇵🇭"),
        Language(code: "fr", name: "French", flag: "🇫🇷"),
        Language(code: "ga", name: "Irish", flag: "🇮🇪"),
        Language(code: "gl", name: "Galician", flag: "🇪🇸"),
        Language(code: "gu", name: "Gujarati", flag: "🇮🇳"),
        Language(code: "he", name: "Hebrew", flag: "🇮🇱"),
        Language(code: "hi", name: "Hindi", flag: "🇮🇳"),
        Language(code: "hr", name: "Croatian", flag: "🇭🇷"),
        Language(code: "hu", name: "Hungarian", flag: "🇭🇺"),
        Language(code: "hy", name: "Armenian", flag: "🇦🇲"),
        Language(code: "id", name: "Indonesian", flag: "🇮🇩"),
        Language(code: "is", name: "Icelandic", flag: "🇮🇸"),
        Language(code: "it", name: "Italian", flag: "🇮🇹"),
        Language(code: "ja", name: "Japanese", flag: "🇯🇵"),
        Language(code: "ka", name: "Georgian", flag: "🇬🇪"),
        Language(code: "kk", name: "Kazakh", flag: "🇰🇿"),
        Language(code: "km", name: "Khmer", flag: "🇰🇭"),
        Language(code: "kn", name: "Kannada", flag: "🇮🇳"),
        Language(code: "ko", name: "Korean", flag: "🇰🇷"),
        Language(code: "lo", name: "Lao", flag: "🇱🇦"),
        Language(code: "lt", name: "Lithuanian", flag: "🇱🇹"),
        Language(code: "lv", name: "Latvian", flag: "🇱🇻"),
        Language(code: "mk", name: "Macedonian", flag: "🇲🇰"),
        Language(code: "ml", name: "Malayalam", flag: "🇮🇳"),
        Language(code: "mn", name: "Mongolian", flag: "🇲🇳"),
        Language(code: "mr", name: "Marathi", flag: "🇮🇳"),
        Language(code: "ms", name: "Malay", flag: "🇲🇾"),
        Language(code: "my", name: "Myanmar (Burmese)", flag: "🇲🇲"),
        Language(code: "ne", name: "Nepali", flag: "🇳🇵"),
        Language(code: "nl", name: "Dutch", flag: "🇳🇱"),
        Language(code: "no", name: "Norwegian", flag: "🇳🇴"),
        Language(code: "pa", name: "Punjabi", flag: "🇮🇳"),
        Language(code: "pl", name: "Polish", flag: "🇵🇱"),
        Language(code: "pt", name: "Portuguese", flag: "🇵🇹"),
        Language(code: "ro", name: "Romanian", flag: "🇷🇴"),
        Language(code: "ru", name: "Russian", flag: "🇷🇺"),
        Language(code: "si", name: "Sinhala", flag: "🇱🇰"),
        Language(code: "sk", name: "Slovak", flag: "🇸🇰"),
        Language(code: "sl", name: "Slovenian", flag: "🇸🇮"),
        Language(code: "sq", name: "Albanian", flag: "🇦🇱"),
        Language(code: "sr", name: "Serbian", flag: "🇷🇸"),
        Language(code: "sv", name: "Swedish", flag: "🇸🇪"),
        Language(code: "sw", name: "Swahili", flag: "🇰🇪"),
        Language(code: "ta", name: "Tamil", flag: "🇮🇳"),
        Language(code: "te", name: "Telugu", flag: "🇮🇳"),
        Language(code: "th", name: "Thai", flag: "🇹🇭"),
        Language(code: "tr", name: "Turkish", flag: "🇹🇷"),
        Language(code: "uk", name: "Ukrainian", flag: "🇺🇦"),
        Language(code: "ur", name: "Urdu", flag: "🇵🇰"),
        Language(code: "uz", name: "Uzbek", flag: "🇺🇿"),
        Language(code: "vi", name: "Vietnamese", flag: "🇻🇳"),
        Language(code: "zh", name: "Chinese (Simplified)", flag: "🇨🇳"),
        Language(code: "zh-TW", name: "Chinese (Traditional)", flag: "🇹🇼"),
        Language(code: "zu", name: "Zulu", flag: "🇿🇦")
    ]

    static let sourceLanguages: [Language] = [Language.autoDetect] + all
    static let targetLanguages: [Language] = all

    static let `default` = all.first(where: { $0.code == "en" })!

    static func language(forCode code: String) -> Language {
        if code == Language.autoDetect.code || code.isEmpty {
            return Language.autoDetect
        }
        return all.first(where: { $0.code.caseInsensitiveCompare(code) == .orderedSame })
            ?? Language(code: code, name: code.uppercased(), flag: "🏳️")
    }

    static func guessLanguage(for text: String) -> Language {
        if text.unicodeScalars.contains(where: { (0x0B80...0x0BFF).contains($0.value) }) {
            return language(forCode: "ta")
        }
        if text.unicodeScalars.contains(where: { (0x3040...0x30FF).contains($0.value) || (0x31F0...0x31FF).contains($0.value) }) {
            return language(forCode: "ja")
        }
        if text.unicodeScalars.contains(where: { (0xAC00...0xD7AF).contains($0.value) }) {
            return language(forCode: "ko")
        }
        if text.unicodeScalars.contains(where: { (0x4E00...0x9FFF).contains($0.value) }) {
            return language(forCode: "zh")
        }
        if text.unicodeScalars.contains(where: { (0x0400...0x04FF).contains($0.value) }) {
            return language(forCode: "ru")
        }
        if text.unicodeScalars.contains(where: { (0x0600...0x06FF).contains($0.value) }) {
            return language(forCode: "ar")
        }
        if text.range(of: "[ÅÄÖåäö]", options: .regularExpression) != nil {
            return language(forCode: "sv")
        }
        return Language.autoDetect
    }
}
