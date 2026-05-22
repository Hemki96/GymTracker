import Testing
@testable import GymTracker

struct RIRAnalyzerTests {
    private let analyzer = RIRAnalyzer()

    @Test
    func parsesTargetRangesAndSingleValues() throws {
        #expect(try #require(analyzer.parseTargetRange(from: "2-3")) == 2...3)
        #expect(try #require(analyzer.parseTargetRange(from: "3-4")) == 3...4)
        #expect(try #require(analyzer.parseTargetRange(from: "2–3")) == 2...3)
        #expect(try #require(analyzer.parseTargetRange(from: "2.5-3.5")) == 2.5...3.5)
        #expect(try #require(analyzer.parseTargetRange(from: "3")) == 3...3)
    }

    @Test
    func returnsInTargetForInclusiveBoundaries() {
        #expect(analyzer.evaluate(actualRIR: 2, targetText: "2-3") == .inTarget(actualRIR: 2, range: 2...3))
        #expect(analyzer.evaluate(actualRIR: 3, targetText: "2-3") == .inTarget(actualRIR: 3, range: 2...3))
    }

    @Test
    func returnsTooEasyWhenActualRIRIsAboveTargetRange() {
        #expect(analyzer.evaluate(actualRIR: 4, targetText: "2-3") == .tooEasy(actualRIR: 4, range: 2...3))
    }

    @Test
    func returnsTooHeavyWhenActualRIRIsBelowTargetRange() {
        #expect(analyzer.evaluate(actualRIR: 1, targetText: "2-3") == .tooHeavy(actualRIR: 1, range: 2...3))
    }

    @Test
    func returnsIncompleteWhenActualRIRIsMissing() {
        #expect(analyzer.evaluate(actualRIR: nil, targetText: "3-4") == .incomplete)
    }

    @Test
    func treatsRPEPrescriptionsAsTextStatus() {
        #expect(analyzer.evaluate(actualRIR: nil, targetText: "7RPE") == .textStatus("7RPE"))
        #expect(analyzer.evaluate(actualRIR: 2, targetText: "7RPE") == .textStatus("7RPE"))
        #expect(analyzer.evaluate(actualRIR: nil, targetText: "7 rpe") == .textStatus("7 rpe"))
    }

    @Test
    func handlesMissingAndInvalidTargets() {
        #expect(analyzer.evaluate(actualRIR: 2, targetText: nil) == .noTarget)
        #expect(analyzer.evaluate(actualRIR: 2, targetText: "") == .noTarget)
        #expect(analyzer.evaluate(actualRIR: 2, targetText: "leicht") == .invalidTarget("leicht"))
        #expect(analyzer.parseTargetRange(from: "4-3") == nil)
    }
}
