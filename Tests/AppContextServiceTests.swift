import Foundation

@main
struct AppContextServiceTests {
    static func main() {
        testWakeCommandIncludesPreviousTextAndScreenContext()
        testResponseFencesAreStripped()
        TranscriptTidierTests.run()
        DictionaryStoreTests.run()
        WakePhraseMatcherTests.run()
        print("MegaphoneTests passed")
    }

    private static func testWakeCommandIncludesPreviousTextAndScreenContext() {
        let prompt = AppleFoundationModelsPostProcessor.commandPrompt(
            command: "make that formal",
            appName: "Mail",
            windowTitle: "Draft — Project update",
            contextSummary: "The user is composing an email reply.",
            selectedText: "Earlier text selected in the draft.",
            previousText: "hey, can you send this over by friday?",
            vocabulary: ["Megaphone"]
        )

        expect(prompt.contains("RECENT TEXT INSERTED BY THE USER:"), "Previous-text label missing")
        expect(prompt.contains("hey, can you send this over by friday?"), "Previous dictation missing")
        expect(prompt.contains("Destination app: Mail"), "Destination app context missing")
        expect(prompt.contains("Window: Draft — Project update"), "Window context missing")
        expect(prompt.contains("Context: The user is composing an email reply."), "Screen context missing")
        expect(prompt.contains("Current selected text: Earlier text selected in the draft."), "Selected screen text missing")
        expect(prompt.contains("make that formal"), "Spoken follow-up missing")
    }

    private static func testResponseFencesAreStripped() {
        let fullyWrapped = """
        <transcript>
        Let's ship this tomorrow.
        </transcript>
        """
        expectEqual(
            AppleFoundationModelsPostProcessor.stripResponseFences(fullyWrapped),
            "Let's ship this tomorrow."
        )

        // Only a trailing close tag leaked.
        expectEqual(
            AppleFoundationModelsPostProcessor.stripResponseFences("Fix the auth bug.</transcript>"),
            "Fix the auth bug."
        )

        // Sibling fences from the selection/command prompts.
        expectEqual(
            AppleFoundationModelsPostProcessor.stripResponseFences("<selected_text>Hello there</selected_text>"),
            "Hello there"
        )

        // Text with no fence is returned unchanged (aside from trimming).
        expectEqual(
            AppleFoundationModelsPostProcessor.stripResponseFences("Just plain output."),
            "Just plain output."
        )

        // A real angle bracket inside the text must survive.
        expectEqual(
            AppleFoundationModelsPostProcessor.stripResponseFences("Use a < b to compare."),
            "Use a < b to compare."
        )
    }

    private static func expectEqual(_ actual: String?, _ expected: String, file: StaticString = #file, line: UInt = #line) {
        expect(actual == expected, "Expected \(expected.debugDescription), got \((actual ?? "nil").debugDescription)", file: file, line: line)
    }

    private static func expect(_ condition: Bool, _ message: String, file: StaticString = #file, line: UInt = #line) {
        if !condition {
            fatalError("\(file):\(line): \(message)")
        }
    }
}
