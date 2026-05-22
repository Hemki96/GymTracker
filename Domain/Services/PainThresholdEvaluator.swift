import Foundation

enum PainStatus: Equatable {
    case noTarget
    case incomplete
    case ok(actualPain: Int, maxPain: Int)
    case warning(actualPain: Int, maxPain: Int)
    case invalidActualPain(Int)
    case invalidTarget(String)
}

struct PainThresholdEvaluator {
    func evaluate(actualPain: Int?, targetText: String?) -> PainStatus {
        guard let targetText = targetText?.trimmedNonEmpty else { return .noTarget }
        guard let maxPain = parseMaxPain(from: targetText) else { return .invalidTarget(targetText) }
        guard let actualPain else { return .incomplete }
        guard (0...10).contains(actualPain) else { return .invalidActualPain(actualPain) }

        return actualPain <= maxPain
            ? .ok(actualPain: actualPain, maxPain: maxPain)
            : .warning(actualPain: actualPain, maxPain: maxPain)
    }

    func parseMaxPain(from text: String?) -> Int? {
        guard let text = text?.trimmedNonEmpty else { return nil }
        let pattern = #"(?i)\bmax(?:\.|imal)?\s*(\d{1,2})\s*/\s*10\b"#
        guard let match = text.firstRegexCapture(pattern: pattern) else { return nil }
        guard let value = Int(match), (0...10).contains(value) else { return nil }
        return value
    }
}
