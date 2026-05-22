# Technische Architektur iOS

## 1. Zielarchitektur

Die App wird als native iOS-App umgesetzt.

Empfohlener Stack:

| Bereich | Technologie |
|---|---|
| UI | SwiftUI |
| Persistenz | SwiftData |
| Diagramme | Swift Charts |
| Architektur | MVVM + Repository Pattern |
| Tests | XCTest / Swift Testing |
| Datenexport | Codable + FileExporter |
| Optional später | HealthKit, CloudKit/iCloud |

Apple beschreibt SwiftUI als Framework für deklarative Benutzeroberflächen, SwiftData als deklarativen Persistenzansatz mit Model-Makros und Swift Charts als SwiftUI-basiertes Framework für Datenvisualisierung. HealthKit ist nur optional sinnvoll, weil Apple Health-Daten als sensibel behandelt und explizite Berechtigungen verlangt.

## 2. Modulstruktur

```text
GymTracker/
├── App/
│   ├── GymTrackerApp.swift
│   └── AppEnvironment.swift
├── Domain/
│   ├── Models/
│   ├── Enums/
│   ├── ValueObjects/
│   └── Services/
├── Data/
│   ├── SwiftDataModels/
│   ├── Repositories/
│   ├── SeedData/
│   └── Export/
├── Features/
│   ├── Dashboard/
│   ├── Plan/
│   ├── ActiveSession/
│   ├── History/
│   ├── Analytics/
│   └── Settings/
├── DesignSystem/
│   ├── Components/
│   ├── Theme/
│   └── Formatters/
└── Tests/
    ├── DomainTests/
    ├── RepositoryTests/
    └── ViewModelTests/
```

## 3. Architekturprinzipien

### 3.1 Views sind leichtgewichtig

SwiftUI Views enthalten keine Businesslogik.

Nicht gut:

```swift
Button("Session abschließen") {
    // Volumen, RIR und Schmerz hier direkt berechnen
}
```

Besser:

```swift
Button("Session abschließen") {
    viewModel.completeSession()
}
```

### 3.2 Businesslogik in Services

Beispiele:

- `VolumeCalculator`
- `RIRAnalyzer`
- `PainThresholdEvaluator`
- `ProgressionAdvisor`
- `SessionSummaryBuilder`

### 3.3 Persistenz über Repositories kapseln

Views und ViewModels sprechen nicht direkt mit SwiftData, sondern über Repositories.

```swift
protocol SessionRepository {
    func activeSession() throws -> SessionLog?
    func save(_ session: SessionLog) throws
    func complete(_ session: SessionLog) throws
}
```

## 4. Schichten

```text
UI Layer
SwiftUI Views

Presentation Layer
ViewModels

Domain Layer
Entities, Value Objects, Services

Data Layer
SwiftData, SeedData, Export

Platform Layer
HealthKit, File System, Notifications
```

## 5. ViewModels

| ViewModel | Aufgabe |
|---|---|
| `DashboardViewModel` | aktive Woche, nächste Session, Fortschritt |
| `PlanViewModel` | Wochen-/Tagesübersicht |
| `WorkoutDetailViewModel` | Details eines geplanten Tages |
| `ActiveSessionViewModel` | Logging der aktuellen Session |
| `ExerciseTrackingViewModel` | Satzlogging einer Übung |
| `HistoryViewModel` | abgeschlossene Sessions |
| `AnalyticsViewModel` | Kennzahlen und Charts |
| `SettingsViewModel` | Export, Datenschutz, Einstellungen |

## 6. Services

### VolumeCalculator

```swift
struct VolumeCalculator {
    func setVolume(weightKg: Double?, reps: Int?) -> Double {
        guard let weightKg, let reps else { return 0 }
        return weightKg * Double(reps)
    }
}
```

### PainThresholdEvaluator

```swift
struct PainThresholdEvaluator {
    func evaluate(actualPain: Int?, targetText: String?) -> PainStatus {
        // parse "max 3/10"
        // compare with actualPain
    }
}
```

### RIRAnalyzer

```swift
struct RIRAnalyzer {
    func evaluate(actualRIR: Double?, targetText: String?) -> RIRStatus {
        // parse "2-3", "3-4", "7RPE"
    }
}
```

## 7. Persistenz

### Warum SwiftData?

SwiftData bietet deklarative Model-Definitionen und lokale Persistenz ohne eigene Datenbank-Infrastruktur. Für diese App passt das, weil der MVP offline-first ist und ein relationales Objektmodell aus Block, Woche, Session und Sets benötigt.

### Persistenzobjekte

- `TrainingBlock`
- `TrainingWeek`
- `WorkoutPlan`
- `Exercise`
- `PlannedExercise`
- `SessionLog`
- `ExerciseLog`
- `SetLog`

## 8. Seed Data

Die aus der Excel-Vorlage extrahierten Übungen und Wochenpläne sollten im MVP als Seed-Daten im Code oder als JSON-Datei eingebunden werden.

Empfohlen:

```text
Data/SeedData/christian_b1_plan.json
```

## 9. Export

### MVP

- Markdown-Export einer Session
- CSV-Export aller SetLogs

### Später

- Excel-Export
- PDF-Report
- JSON Backup/Restore

## 10. HealthKit

HealthKit sollte nicht im MVP erzwungen werden.

Sinnvolle spätere Integration:

- Körpergewicht lesen
- Workout als Krafttraining schreiben
- Herzfrequenzdaten lesen, falls vorhanden
- aktive Energie optional übernehmen

Wichtig: Vor jeder Nutzung muss die App prüfen, ob HealthKit auf dem Gerät verfügbar ist, und explizite Berechtigungen anfordern.

## 11. Technische Risiken

| Risiko | Gegenmaßnahme |
|---|---|
| Datenmodell wird zu starr | Planwerte als Text + Ist-Werte strukturiert speichern |
| Session-Logging zu langsam | UI auf schnelle Eingaben optimieren |
| HealthKit-Komplexität | aus MVP ausklammern |
| Planimport aus Excel aufwendig | zunächst Seed-Daten statisch |
| Businesslogik in Views | Services und ViewModels erzwingen |
| Datenverlust | automatische Speicherung nach jeder Eingabe |

## 12. Qualitätsregeln

- Jede Businessregel bekommt Unit Tests.
- Jede ViewModel-Funktion ist ohne UI testbar.
- Keine harte Kopplung von SwiftUI Views an SwiftData.
- Export muss reproduzierbar sein.
- Seed-Daten müssen validiert werden.

## Offizielle Apple-Referenzen

- SwiftUI: https://developer.apple.com/documentation/swiftui
- SwiftData: https://developer.apple.com/documentation/SwiftData
- Swift Charts: https://developer.apple.com/documentation/Charts
- HealthKit: https://developer.apple.com/documentation/healthkit
- HealthKit Setup: https://developer.apple.com/documentation/healthkit/setting_up_healthkit
- HealthKit Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/healthkit
