# Domain-Modell und Datenmodell

## 1. Domain-Übersicht

Die App basiert auf einem hierarchischen Trainingsmodell:

```text
TrainingBlock
├── TrainingWeek
│   ├── WorkoutPlan
│   │   ├── PlannedExercise
│   │   │   └── PlannedSet
│   │   └── SessionLog
│   │       ├── ExerciseLog
│   │       │   └── SetLog
│   │       └── SessionSummary
└── ExerciseLibrary
```

## 2. Zentrale Entitäten

## 2.1 TrainingBlock

Ein Trainingsblock beschreibt einen zusammenhängenden Plan, z. B. „Wettkampfvorbereitung bis 20.06.2026“.

| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | UUID | eindeutige ID |
| `name` | String | Name des Blocks |
| `athleteName` | String? | optionaler Athletenname |
| `goal` | String | Ziel des Blocks |
| `startDate` | Date? | optionaler Start |
| `endDate` | Date? | optionales Ende |
| `status` | BlockStatus | planned, active, completed, archived |
| `createdAt` | Date | Erstellungsdatum |
| `updatedAt` | Date | Änderungsdatum |

## 2.2 TrainingWeek

| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | UUID | eindeutige ID |
| `blockId` | UUID | Referenz auf TrainingBlock |
| `weekNumber` | Int | Woche 1–6 |
| `title` | String | z. B. Woche 1 |
| `focus` | String? | optionaler Fokus |
| `notes` | String? | Wochenhinweise |

## 2.3 WorkoutPlan

Ein WorkoutPlan entspricht einem Trainingstag innerhalb einer Woche.

| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | UUID | eindeutige ID |
| `weekId` | UUID | Referenz auf TrainingWeek |
| `dayNumber` | Int | Tag 1–3 |
| `title` | String | z. B. Tag 1 |
| `plannedDate` | Date? | optional geplanter Termin |
| `status` | WorkoutStatus | planned, active, completed, skipped |
| `sortOrder` | Int | Reihenfolge |

## 2.4 Exercise

Stammdaten einer Übung.

| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | UUID | eindeutige ID |
| `name` | String | Übungsname |
| `category` | ExerciseCategory | lowerBody, upperBody, core, pull, push, hinge, squat |
| `defaultCueing` | String? | Standard-Cue |
| `defaultTempo` | String? | Standard-Tempo |
| `isUnilateral` | Bool | z. B. Split Squats |
| `usesBodyweight` | Bool | z. B. Klimmzüge |
| `createdAt` | Date | Erstellungsdatum |

## 2.5 PlannedExercise

Konkrete Übung innerhalb eines WorkoutPlans.

| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | UUID | eindeutige ID |
| `workoutPlanId` | UUID | Referenz auf WorkoutPlan |
| `exerciseId` | UUID | Referenz auf Exercise |
| `sortOrder` | Int | Reihenfolge im Training |
| `cueing` | String? | Plan-Cue |
| `tempo` | String? | Plan-Tempo |
| `setsPrescription` | String | z. B. 5 |
| `repsPrescription` | String | z. B. 6–10, AMRAP |
| `plannedWeightText` | String? | Originalwert aus Plan |
| `targetRIRText` | String? | z. B. 2–3 |
| `painTargetText` | String? | z. B. max 3/10 |
| `notes` | String? | Planhinweise |

## 2.6 SessionLog

Tatsächlich absolvierte Einheit.

| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | UUID | eindeutige ID |
| `workoutPlanId` | UUID | geplanter Tag |
| `startedAt` | Date | Startzeit |
| `completedAt` | Date? | Endzeit |
| `durationSeconds` | Int? | Dauer |
| `status` | SessionStatus | active, completed, cancelled |
| `overallNotes` | String? | Session-Notiz |
| `maxPain` | Int? | Maximaler Schmerz |
| `averageRIR` | Double? | Durchschnittliches RIR |
| `totalVolumeKg` | Double? | Gesamtvolumen |

## 2.7 ExerciseLog

Logging einer geplanten Übung.

| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | UUID | eindeutige ID |
| `sessionLogId` | UUID | Referenz auf SessionLog |
| `plannedExerciseId` | UUID | Referenz auf PlannedExercise |
| `startedAt` | Date? | Beginn |
| `completedAt` | Date? | Ende |
| `actualRIR` | Double? | falls nur auf Übungsebene erfasst |
| `actualPain` | Int? | falls nur auf Übungsebene erfasst |
| `notes` | String? | Übungsnotiz |
| `isCompleted` | Bool | erledigt ja/nein |

## 2.8 SetLog

Logging pro Satz.

| Feld | Typ | Beschreibung |
|---|---|---|
| `id` | UUID | eindeutige ID |
| `exerciseLogId` | UUID | Referenz auf ExerciseLog |
| `setNumber` | Int | Satznummer |
| `plannedRepsText` | String? | Vorgabe |
| `loggedReps` | Int? | tatsächliche Reps |
| `plannedWeightText` | String? | Vorgabe |
| `loggedWeightKg` | Double? | tatsächliches Gewicht |
| `rir` | Double? | Ist-RIR |
| `pain` | Int? | Schmerz 0–10 |
| `notes` | String? | Satznotiz |
| `isWarmup` | Bool | Aufwärmsatz ja/nein |
| `isCompleted` | Bool | erledigt ja/nein |

## 3. Enums

```swift
enum BlockStatus: String, Codable {
    case planned
    case active
    case completed
    case archived
}

enum WorkoutStatus: String, Codable {
    case planned
    case active
    case completed
    case skipped
}

enum SessionStatus: String, Codable {
    case active
    case completed
    case cancelled
}

enum ExerciseCategory: String, Codable {
    case squat
    case hinge
    case pull
    case push
    case core
    case isolation
    case mobility
    case unknown
}
```

## 4. SwiftData-Skizze

```swift
import Foundation
import SwiftData

@Model
final class TrainingBlock {
    @Attribute(.unique) var id: UUID
    var name: String
    var athleteName: String?
    var goal: String
    var statusRaw: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var weeks: [TrainingWeek]

    init(
        id: UUID = UUID(),
        name: String,
        athleteName: String? = nil,
        goal: String,
        status: BlockStatus = .planned,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        weeks: [TrainingWeek] = []
    ) {
        self.id = id
        self.name = name
        self.athleteName = athleteName
        self.goal = goal
        self.statusRaw = status.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.weeks = weeks
    }
}
```

## 5. Datenmodell-Entscheidungen

### Entscheidung 1: Planwerte und Ist-Werte trennen

Planwerte dürfen nicht überschrieben werden, wenn der Nutzer in der Session abweicht.

### Entscheidung 2: Gewicht und Wiederholungen teilweise als Text speichern

Die Excel-Vorlage enthält nicht nur numerische Werte. Deshalb werden Originalplanwerte als Text übernommen und Ist-Werte strukturiert erfasst.

### Entscheidung 3: Satzdaten optional granular

Für schnelles Logging kann RIR/Schmerz auf Übungsebene erfasst werden. Für präzises Tracking kann die App zusätzlich Satzdaten speichern.

### Entscheidung 4: Versionierung vorbereiten

Planänderungen sollen später versioniert werden. Im MVP reicht ein `updatedAt` plus Änderungshistorie im Log.

## 6. Seed-Daten aus der Vorlage

Die Übungsbibliothek im MVP sollte initial folgende Übungen enthalten:

| Übung |
| --- |
| Ab Wheel |
| Beinbeuger |
| Beinstrecker |
| Bulgarian Split Squats |
| Hollow Body Hold |
| Hyperextensions mit Glute Fokus |
| Klimmzüge (mit Zusatzgewicht) |
| Kniebeugen |
| Kreuzheben mit Trapbar |
| Kurzhantel über Kopf drücken, stehend |
| Latziehen |
| Lu Raises |
| Pallof Rotations |
| Rudern mit V-Griff |
| Superman Hold |
| Überzüge mit Kurzhantel |
