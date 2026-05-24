# GymTracker Technical Developer Guide

## Zweck

Dieses Dokument gibt neuen Entwicklerinnen und Entwicklern einen schnellen technischen Einstieg in die iOS-App. Es ergänzt die Code-Kommentare und die vorhandenen Konzeptdokumente um konkrete Hinweise zu Architektur, Datenfluss und wichtigen Services.

## Architekturüberblick

GymTracker ist eine native SwiftUI-App mit SwiftData als lokaler Persistenzschicht. Die App ist bewusst in wenige, klare Bereiche geteilt:

- `App/`: App-Start, Environment-Erzeugung und Root-Navigation.
- `Data/`: SwiftData-Modelle, ModelContainer und Seed-/Demo-Datenimport.
- `Domain/`: reine Services für Session-Start, Session-Abschluss, Berechnungen, Analyse-Mapping und Export.
- `Features/`: SwiftUI-Screens und feature-nahe Orchestrierung.
- `DesignSystem/`: gemeinsame Tokens, Oberflächen und wiederverwendbare UI-Bausteine.
- `Tests/`: Unit-Tests für Domain-Services, Datenimport und ausgewählte ViewModels.

Die wichtigste Architekturregel: Views orchestrieren User-Flows, Domain-Services besitzen Business-Logik, und SwiftData-Modelle bleiben die gemeinsame persistente Wahrheit.

## Persistenzmodell

Die Planungsdaten bilden einen hierarchischen Graph:

`TrainingBlock -> TrainingWeek -> WorkoutPlan -> PlannedExercise -> PlannedSet`

Die Ausführungsdaten bilden den Trainingslog:

`SessionLog -> ExerciseLog -> SetLog`

Beim Start einer Session erzeugt `SessionStartService` einen Snapshot aus dem Plan. Dadurch bleibt eine aktive Session stabil, auch wenn der Trainingsplan später bearbeitet wird. Beim Abschluss berechnet `SessionCompletionService` zusammenfassende Werte wie Dauer, Volumen, durchschnittliche RIR, maximalen Schmerz und Warnungen und speichert sie direkt am `SessionLog`.

Enum-Zustände werden als Raw Strings gespeichert. Das ist SwiftData-freundlich und toleranter gegenüber zukünftigen Änderungen; die computed Properties fallen bei unbekannten Werten auf sinnvolle Defaults zurück.

## Zentrale Flows

### Plan erstellen/importieren

`PlanView` ruft `PlanActionService` auf. Der Service kapselt SwiftData-Mutationen, Demo-Import und JSON-Import. Seed-Daten werden über `SeedDataService` validiert, in SwiftData-Modelle gemappt und optional mit einem `PersistentTrainingMarker` gegen doppelte Bundle-Imports abgesichert.

### Workout starten

`WorkoutDetailView` ruft `SessionStartService.startOrResumeSession` auf. Der Service erlaubt global nur eine aktive Session. Für dasselbe Workout wird eine aktive Session fortgesetzt; für ein anderes Workout wird ein Fehler zurückgegeben, damit die UI den Konflikt sichtbar machen kann.

### Session bearbeiten

`ActiveSessionView`, `ExerciseTrackingView` und `SetLogRow` arbeiten direkt mit SwiftData-Objekten über `@Bindable` und `ModelContext`. Persistenz und Zusammenfassungs-Refresh laufen über `SessionEditingService` und `SessionCompletionService`, damit Dashboard, Historie, Analyse und Export dieselben Kennzahlen verwenden.

### Session abschließen

`SessionCompletionService.completeSession` ist die zentrale Abschlussgrenze. Dort werden Status, Dauer, Notizen, ExerciseLog-Zustände, Warnungen und Analytics-Caches zusammen gespeichert.

### Analyse und Export

`ChartDataMapper` formt abgeschlossene Sessions in Chart-DTOs. Fehlende Cache-Werte werden aus SetLogs rekonstruiert, damit ältere oder teilweise migrierte Sessions nicht aus Diagrammen verschwinden.

`TrainingExportService` erzeugt Markdown für einzelne Sessions und CSV für Trainingsblöcke. Exportdaten verwenden UTC-basierte Datumsformatierung und CSV-Escaping, damit Ergebnisse in Tests, Excel, Numbers und Google Sheets stabil bleiben.

## State Management und Navigation

Die App nutzt SwiftUI-State bewusst lokal:

- `@Query` liest SwiftData-Listen direkt in Feature-Screens.
- `@State` hält UI-Auswahl, Navigation-Pfade, Alerts und Share-URLs.
- `@Bindable` wird für editierbare SwiftData-Objekte verwendet.
- `NavigationStack(path:)` in `PlanView` speichert Plan-IDs statt Modellobjekte, damit SwiftData-Refreshes die Navigation nicht destabilisieren.

Die App verwendet keine globale Store-Schicht. Das hält die Oberfläche einfach, verlangt aber, dass mutationsreiche Flows ihre Business-Logik in Services kapseln.

## Fehlerbehandlung

User-sichtbare Fehler werden in Views als String-State angezeigt. Domain-Services werfen typisierte Fehler, wenn die UI unterschiedlich reagieren muss, zum Beispiel `SessionStartError.activeSessionAlreadyExists`.

Einige Export- und Preview-Pfade verwenden `try?`, weil dort ein fehlender Export-URL kein Datenverlust ist. Persistente Mutationen sollten hingegen Fehler sichtbar machen.

## Design System

`AppTheme` enthält Tokens und Surface-Modifier. Feature-Views sollen diese Modifier verwenden, statt eigene Schatten, Hintergründe oder Radiuswerte zu definieren. Die iOS-26-Liquid-Glass-Verfügbarkeit ist bewusst im Theme gekapselt, damit Feature-Code nicht mit Availability-Checks gefüllt wird.

## Wartungshinweise

- Neue SwiftData-Modelle immer in `GymTrackerModelContainer.makeSchema()` ergänzen.
- Wenn Set- oder Session-Kennzahlen geändert werden, zuerst `SessionCompletionService`, `SessionEditingService`, `ChartDataMapper` und `TrainingExportService` gemeinsam prüfen.
- Wenn Plan-Editor-Logik geändert wird, auf Denormalisierung in `TrainingPlanEditorViewModel.syncExercisePrescriptions` achten.
- Wenn Importfelder erweitert werden, `SeedTrainingFixture`, `SeedDataService.validate`, `makePlannedSets` und Tests synchron aktualisieren.
- Views sollten nur kurze Orchestrierung enthalten; wiederverwendbare Business-Regeln gehören in `Domain/Services`.
