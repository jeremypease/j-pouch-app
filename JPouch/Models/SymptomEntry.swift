import Foundation
import SwiftData

/// How bad a symptom check-in felt overall.
enum SymptomSeverity: String, Codable, CaseIterable, Identifiable, Hashable {
    case mild, moderate, severe

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mild: "Mild"
        case .moderate: "Moderate"
        case .severe: "Severe"
        }
    }

    /// What this means in practice, so "moderate" isn't left to interpretation drifting over
    /// time — the whole point of the log is that today is comparable to last month.
    var summary: String {
        switch self {
        case .mild: "Noticeable, but not getting in the way."
        case .moderate: "Affecting what you can do today."
        case .severe: "Hard to carry on as normal."
        }
    }
}

/// The symptoms a check-in can record.
///
/// A fixed list rather than free text, because the point is comparing today with last month —
/// free text can't be counted. The notes field is there for everything this list misses.
enum SymptomType: String, Codable, CaseIterable, Identifiable, Hashable {
    case cramping
    case bloating
    case nausea
    case fatigue
    case jointPain
    case skinIrritation
    case fever
    case incontinence

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cramping: "Cramping"
        case .bloating: "Bloating"
        case .nausea: "Nausea"
        case .fatigue: "Fatigue"
        case .jointPain: "Joint pain"
        case .skinIrritation: "Skin irritation"
        case .fever: "Fever or chills"
        case .incontinence: "Leakage"
        }
    }
}

/// Where discomfort was felt. Kept coarse on purpose — finer anatomy would invite people to
/// self-localise in ways the app can't act on and a GI wouldn't take at face value anyway.
enum SymptomLocation: String, Codable, CaseIterable, Identifiable, Hashable {
    case unspecified
    case lowerAbdomen
    case upperAbdomen
    case pouch
    case rectal
    case wholeBody

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .unspecified: "Not sure"
        case .lowerAbdomen: "Lower abdomen"
        case .upperAbdomen: "Upper abdomen"
        case .pouch: "Pouch area"
        case .rectal: "Rectal"
        case .wholeBody: "All over"
        }
    }
}

/// A point-in-time symptom check-in, separate from an output entry.
///
/// Symptoms that matter for pouchitis — joint pain, fever, fatigue — often show up on days with
/// unremarkable output, so hanging them off `OutputEntry` would systematically miss them.
@Model
final class SymptomEntry {
    var timestamp: Date = Date.now

    /// Stored as raw strings rather than enums so the CloudKit-backed store stays migratable:
    /// adding a case to any of these enums can't invalidate rows already synced from another
    /// device running an older build.
    var severityRawValue: String = SymptomSeverity.mild.rawValue
    var typeRawValues: [String] = []
    var locationRawValue: String = SymptomLocation.unspecified.rawValue
    var notes: String?

    var severity: SymptomSeverity {
        get { SymptomSeverity(rawValue: severityRawValue) ?? .mild }
        set { severityRawValue = newValue.rawValue }
    }

    /// Unknown raw values are dropped rather than defaulted: a symptom this build doesn't
    /// recognise is better absent than silently reported as the wrong one.
    var types: [SymptomType] {
        get { typeRawValues.compactMap(SymptomType.init(rawValue:)) }
        set { typeRawValues = newValue.map(\.rawValue) }
    }

    var location: SymptomLocation {
        get { SymptomLocation(rawValue: locationRawValue) ?? .unspecified }
        set { locationRawValue = newValue.rawValue }
    }

    init(
        timestamp: Date = .now,
        severity: SymptomSeverity = .mild,
        types: [SymptomType] = [],
        location: SymptomLocation = .unspecified,
        notes: String? = nil
    ) {
        self.timestamp = timestamp
        self.severityRawValue = severity.rawValue
        self.typeRawValues = types.map(\.rawValue)
        self.locationRawValue = location.rawValue
        self.notes = notes
    }

    /// A one-line summary for lists and the GI report.
    var summaryLine: String {
        let names = types.map(\.displayName)
        let symptoms = names.isEmpty ? "Check-in" : names.joined(separator: ", ")
        return "\(severity.displayName) · \(symptoms)"
    }
}
