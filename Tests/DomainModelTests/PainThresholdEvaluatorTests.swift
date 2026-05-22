import Testing
@testable import GymTracker

@Suite(.serialized)
struct PainThresholdEvaluatorTests {
    private let evaluator = PainThresholdEvaluator()

    @Test
    func parsesMaxPainTarget() {
        #expect(evaluator.parseMaxPain(from: "max 3/10") == 3)
        #expect(evaluator.parseMaxPain(from: "Max. 3 / 10") == 3)
        #expect(evaluator.parseMaxPain(from: "maximal 10/10") == 10)
        #expect(evaluator.parseMaxPain(from: "max 11/10") == nil)
        #expect(evaluator.parseMaxPain(from: "3/10") == nil)
    }

    @Test
    func returnsOkAtAndBelowThreshold() {
        #expect(evaluator.evaluate(actualPain: 2, targetText: "max 3/10") == .ok(actualPain: 2, maxPain: 3))
        #expect(evaluator.evaluate(actualPain: 3, targetText: "max 3/10") == .ok(actualPain: 3, maxPain: 3))
    }

    @Test
    func returnsWarningWhenPainExceedsThreshold() {
        #expect(evaluator.evaluate(actualPain: 4, targetText: "max 3/10") == .warning(actualPain: 4, maxPain: 3))
    }

    @Test
    func handlesMissingTargetAndMissingActualPain() {
        #expect(evaluator.evaluate(actualPain: 5, targetText: nil) == .noTarget)
        #expect(evaluator.evaluate(actualPain: 5, targetText: "") == .noTarget)
        #expect(evaluator.evaluate(actualPain: nil, targetText: "max 3/10") == .incomplete)
    }

    @Test
    func reportsInvalidTargets() {
        #expect(evaluator.evaluate(actualPain: 3, targetText: "3/10") == .invalidTarget("3/10"))
        #expect(evaluator.evaluate(actualPain: 3, targetText: "max 11/10") == .invalidTarget("max 11/10"))
    }

    @Test
    func reportsActualPainOutsideScaleAsInvalid() {
        #expect(evaluator.evaluate(actualPain: -1, targetText: "max 3/10") == .invalidActualPain(-1))
        #expect(evaluator.evaluate(actualPain: 11, targetText: "max 3/10") == .invalidActualPain(11))
    }
}
