import Foundation
import Testing
@testable import JPouch

@Suite("SymptomEntry — raw value storage")
struct SymptomEntryTests {

    @Test("Round-trips severity, types, and location through their raw values")
    func roundTripsEnums() {
        let entry = SymptomEntry(
            timestamp: testToday,
            severity: .moderate,
            types: [.cramping, .fatigue],
            location: .pouch
        )

        #expect(entry.severity == .moderate)
        #expect(entry.types == [.cramping, .fatigue])
        #expect(entry.location == .pouch)
    }

    /// The reason these are stored as strings: a device running a newer build can sync a
    /// symptom this build has never heard of. Dropping it is right — reporting it as the wrong
    /// symptom would put a word in someone's mouth in something they may hand to their GI.
    @Test("Drops symptom types this build doesn't recognise rather than defaulting them")
    func dropsUnknownTypes() {
        let entry = SymptomEntry()
        entry.typeRawValues = ["cramping", "teleportation", "fatigue"]

        #expect(entry.types == [.cramping, .fatigue])
    }

    @Test("Falls back to a safe value when severity or location is unrecognised")
    func fallsBackOnUnknownScalars() {
        let entry = SymptomEntry()
        entry.severityRawValue = "catastrophic"
        entry.locationRawValue = "left elbow"

        #expect(entry.severity == .mild)
        #expect(entry.location == .unspecified)
    }

    @Test("Setting types rewrites the stored raw values")
    func settingTypesRewritesRawValues() {
        let entry = SymptomEntry(types: [.nausea])
        entry.types = [.fever, .jointPain]

        #expect(entry.typeRawValues == ["fever", "jointPain"])
    }

    @Test("Summary line names the symptoms alongside the severity")
    func summaryLineListsSymptoms() {
        let entry = SymptomEntry(severity: .severe, types: [.fever, .jointPain])

        #expect(entry.summaryLine == "Severe · Fever or chills, Joint pain")
    }

    /// A check-in with no boxes ticked is legitimate — "today was rough" with nothing more
    /// specific — so the summary has to stay readable rather than trailing an empty list.
    @Test("Summary line stays readable when no symptom types were picked")
    func summaryLineWithoutTypes() {
        let entry = SymptomEntry(severity: .mild, types: [])

        #expect(entry.summaryLine == "Mild · Check-in")
    }
}
