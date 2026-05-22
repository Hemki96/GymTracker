import Foundation

enum RIRStatus: Equatable {
    case noTarget
    case incomplete
    case inTarget(actualRIR: Double, range: ClosedRange<Double>)
    case tooEasy(actualRIR: Double, range: ClosedRange<Double>)
    case tooHeavy(actualRIR: Double, range: ClosedRange<Double>)
    case textStatus(String)
    case invalidTarget(String)
}

struct RIRAnalyzer {
    func evaluate(actualRIR: Double?, targetText: String?) -> RIRStatus {
        guard let targetText = targetText?.trimmedNonEmpty else { return .noTarget }

        if isTextStatus(targetText) {
            return .textStatus(targetText)
        }

        guard let range = parseTargetRange(from: targetText) else {
            return .invalidTarget(targetText)
        }

        guard let actualRIR else { return .incomplete }

        if range.contains(actualRIR) {
            return .inTarget(actualRIR: actualRIR, range: range)
        }

        return actualRIR > range.upperBound
            ? .tooEasy(actualRIR: actualRIR, range: range)
            : .tooHeavy(actualRIR: actualRIR, range: range)
    }

    func parseTargetRange(from text: String?) -> ClosedRange<Double>? {
        guard let text = text?.trimmedNonEmpty else { return nil }
        let normalized = text
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")

        let rangePattern = #"^\s*(\d+(?:[.,]\d+)?)\s*-\s*(\d+(?:[.,]\d+)?)\s*$"#
        if let captures = normalized.regexCaptures(pattern: rangePattern), captures.count == 2 {
            guard let lower = Double(captures[0].replacingOccurrences(of: ",", with: ".")),
                  let upper = Double(captures[1].replacingOccurrences(of: ",", with: ".")),
                  lower <= upper else {
                return nil
            }
            return lower...upper
        }

        let singleValuePattern = #"^\s*(\d+(?:[.,]\d+)?)\s*$"#
        if let match = normalized.firstRegexCapture(pattern: singleValuePattern),
           let value = Double(match.replacingOccurrences(of: ",", with: ".")) {
            return value...value
        }

        return nil
    }

    private func isTextStatus(_ text: String) -> Bool {
        text.range(of: #"^\s*\d+(?:[.,]\d+)?\s*RPE\s*$"#, options: [.regularExpression, .caseInsensitive]) != nil
    }
}

extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func firstRegexCapture(pattern: String) -> String? {
        regexCaptures(pattern: pattern)?.first
    }

    func regexCaptures(pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(startIndex..., in: self)
        guard let match = regex.firstMatch(in: self, range: range) else { return nil }

        return (1..<match.numberOfRanges).compactMap { index in
            guard let captureRange = Range(match.range(at: index), in: self) else { return nil }
            return String(self[captureRange])
        }
    }
}
