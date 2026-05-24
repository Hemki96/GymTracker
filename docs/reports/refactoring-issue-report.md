# Refactoring Issue Report

Datum: 2026-05-24
Projekt: GymTracker iOS

## Zusammenfassung

Die App ist als native SwiftUI-/SwiftData-Anwendung mit grober MVVM-Trennung aufgebaut. Die zentrale fachliche Logik liegt ueberwiegend in `Domain/Services`, SwiftData-Modelle liegen in `Data/SwiftDataModels`, Feature-Screens sind unter `Features/*` gruppiert, und Unit Tests decken Domain-, SeedData-, Session- und ViewModel-Logik ab.

Im Rahmen dieser Analyse wurden Build und Tests ausgefuehrt, ein regressionssicherer Bugfix in der Session-Bearbeitung umgesetzt und Plan-Praesentationslogik aus `PlanView.swift` extrahiert. Die Architektur ist damit an einer Stelle klarer, die groessten offenen Risiken liegen aber weiterhin in grossen SwiftUI-Dateien, fehlenden UI Tests, unvollstaendigen Repository-Abstraktionen und eingecheckten Build-Artefakten.

## Durchgefuehrte Refactorings und Fixes

### 1. Plan-Praesentationslogik ausgelagert

Dateien:

- `Features/Plan/PlanPresentation.swift`
- `Features/Plan/PlanView.swift`
- `GymTracker.xcodeproj/project.pbxproj`

`PlanOverviewViewModel` und die reinen Sortier-/Summary-Regeln fuer die Plan-Detailansicht wurden aus `PlanView.swift` in `PlanPresentation.swift` verschoben. Dadurch enthaelt `PlanView.swift` weniger fachliche Transformationslogik und bleibt staerker auf Navigation und UI-Zusammenbau fokussiert. Die bestehenden statischen Test-Einstiegspunkte in `PlanView` delegieren weiterhin, damit vorhandene Tests und Aufrufer stabil bleiben.

### 2. SessionEditingService uebernimmt Warm-up-Metadaten

Dateien:

- `Domain/Services/SessionCompletionService.swift`
- `Tests/SessionTests/SessionCompletionServiceTests.swift`

Beim manuellen Hinzufuegen eines Satzes in einer aktiven Session uebernahm `SessionEditingService.addSet` zwar geplante Wiederholungen, Gewicht und `plannedSet`, aber nicht den Warm-up-Status des passenden geplanten Satzes. Der neue Regressionstest `editingServiceUsesNextPlannedSetMetadataWhenAddingSet` reproduziert den Fehler. Die Implementierung setzt jetzt `isWarmup` aus `nextPlannedSet?.isWarmup`.

## Test- und Build-Status

Ausgefuehrte Verifikation:

- Baseline: `xcodebuild test -scheme GymTracker -project GymTracker.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'`
  - Ergebnis: erfolgreich
- Regression rot: `xcodebuild test ... -only-testing:GymTrackerTests/SessionCompletionServiceTests`
  - Ergebnis vor Fix: `editingServiceUsesNextPlannedSetMetadataWhenAddingSet` fehlgeschlagen
- Regression gruen: `xcodebuild test ... -only-testing:GymTrackerTests/SessionCompletionServiceTests`
  - Ergebnis nach Fix: erfolgreich
- Refactoring-Verifikation: `xcodebuild test ... -only-testing:GymTrackerTests/PlanViewPresentationTests -only-testing:GymTrackerTests/TrainingPlanEditorViewModelTests`
  - Ergebnis: erfolgreich

Hinweis: `xcodebuild` meldet bei der Destination eine Warnung, weil mehrere passende Architekturen fuer `iPhone 16, OS=18.6` existieren. Der Testlauf waehlt die erste passende Destination und laeuft stabil durch.

## Projektstruktur und Datenfluss

### App-Schicht

- `App/GymTrackerApp.swift` erstellt die App-Shell mit `TabView` und injiziert den SwiftData `ModelContainer`.
- `App/AppEnvironment.swift` kapselt aktuell nur `ModelContainer` und einen Dashboard-ViewModel-Factory-Closure.

### Domain-Schicht

- `Domain/Services` enthaelt testbare fachliche Services: Session-Start, Session-Abschluss, Volumen, RIR, Schmerzschwellen, Chart Mapping und Export.
- `Domain/Models` und `Domain/Enums` enthalten kleinere Typen wie `DashboardSummary` und Status-Enums.

### Data-Schicht

- `Data/SwiftDataModels/TrainingModels.swift` enthaelt die komplette SwiftData-Objektgrafik: Trainingsblock, Woche, Workout, geplante Uebung, geplante Saetze, Session Logs, Exercise Logs und Set Logs.
- `Data/SeedData` kapselt Demo-/Seed-Importe.
- `Data/Repositories/RepositoryProtocols.swift` ist derzeit nur ein leerer Platzhalter.

### Feature-Schicht

- `Features/Plan` enthaelt Planuebersicht, Detailansicht, Editor-Views, Preview-Daten und Zeilenkomponenten.
- `Features/Session` enthaelt aktive Session, Satztracking, Picker und Summary.
- `Features/History` und `Features/Analytics` enthalten eigene Query-, Transformations- und Darstellungsteile.

### Tests

- Unit Tests sind vorhanden fuer Domain Services, SwiftData-Modellgraph, Seed-/Demo-Daten, Session-Start/-Abschluss und einige ViewModel-/Praesentationsregeln.
- Ein expliziter UI-Test-Target ist im Xcode-Projekt nicht vorhanden. Das Projekt listet nur `GymTracker` und `GymTrackerTests`.

## Offene Issues

### P1 - Kein UI-Test-Target fuer kritische User Flows

Fundstelle: `GymTracker.xcodeproj/project.pbxproj`, Projekt-Target-Liste enthaelt nur `GymTracker` und `GymTrackerTests`.

Risiko: Kritische Flows wie Plan anlegen, Demo-Plan laden, Session starten, Satz erfassen, Session abschliessen und Historie oeffnen werden nicht end-to-end abgesichert. SwiftUI- und Navigation-Regressions koennen trotz gruenen Unit Tests unentdeckt bleiben.

Empfehlung: `GymTrackerUITests` hinzufuegen und mindestens Smoke Tests fuer diese Flows erstellen. Testdaten sollten ueber In-Memory-/Preview-Container oder kontrollierte Launch Arguments injiziert werden.

### P1 - Build-Artefakte sind versioniert

Fundstelle: `build/GymTracker.build/Release-iphoneos/...`

Risiko: Eingecheckte Derived-/Build-Dateien erzeugen grosse Diffs, Merge-Konflikte und koennen veraltete Build-Zustaende vortaeuschen. Sie verschlechtern Code Review und Repository-Hygiene.

Empfehlung: `build/` aus Git entfernen, `.gitignore` ergaenzen und nur reproduzierbare Quellen, Fixtures und Projektdateien versionieren.

### P2 - Sehr grosse SwiftUI-Dateien mit gemischten Verantwortlichkeiten

Fundstellen:

- `Features/History/HistoryView.swift` ca. 699 Zeilen
- `Features/Session/ActiveSessionView.swift` ca. 657 Zeilen
- `Features/Plan/PlanEditorForms.swift` ca. 560 Zeilen
- `Features/Plan/TrainingPlanEditorViewModel.swift` ca. 521 Zeilen

Risiko: Views enthalten UI, Query-Zugriff, Formatierung, lokale Interaktionslogik und teilweise fachliche Transformationen. Das erschwert isolierte Tests und erhoeht die Wahrscheinlichkeit, dass kleine UI-Aenderungen fachliche Regeln beruehren.

Empfehlung: Schrittweise in fokussierte Presentation-/Formatter-/Calculator-Typen und kleinere View-Komponenten extrahieren. Pro Extraktion vorhandene Tests erweitern oder neue Tests fuer reine Logik ergaenzen.

### P2 - Repository-Schicht ist nur ein Platzhalter

Fundstelle: `Data/Repositories/RepositoryProtocols.swift:1`

Risiko: Die Architektur deutet eine Repository-Schicht an, nutzt aber direkt `ModelContext` in Services und Views. Dadurch ist unklar, ob langfristig SwiftData direkt die App-Grenze sein soll oder eine Repository-Abstraktion geplant ist.

Empfehlung: Entweder Platzhalter entfernen und SwiftData-direkt als bewusste ADR dokumentieren, oder konkrete Protokolle fuer Plan-, Session- und History-Zugriffe einfuehren. Kein leeres Protokoll behalten.

### P2 - AppEnvironment enthaelt ungenutzte Dashboard-Factory

Fundstelle: `App/AppEnvironment.swift:5`

Risiko: `makeDashboardViewModel` wird im aktuellen App-Root nicht genutzt; `DashboardView` ist nicht in der Tab-Struktur verdrahtet. Das erzeugt Unklarheit, ob Dashboard ein altes Feature, ein geplantes Feature oder ein vergessenes Tab ist.

Empfehlung: Dashboard bewusst integrieren, entfernen oder als geplantes Feature im Backlog markieren. Falls Environment-Injection ausgebaut werden soll, sollten auch Services/Repositories dort konfiguriert werden.

### P2 - Editor-Views erzeugen ViewModels mehrfach lokal

Fundstellen:

- `Features/Plan/PlanEditorForms.swift:18`
- `Features/Plan/PlanEditorForms.swift:185`
- `Features/Plan/PlanEditorForms.swift:274`
- `Features/Plan/PlanEditorForms.swift:368`
- `Features/Plan/PlanEditorForms.swift:480`

Risiko: Jeder Editor-Subscreen erstellt aus `modelContext` ein neues `TrainingPlanEditorViewModel`. Aktuell ist der ViewModel zustandslos, aber das Muster erschwert spaetere Abhaengigkeiten, Logging, Validation State oder Undo/Redo.

Empfehlung: Einen gemeinsamen Editor-Store oder eine kleine Environment-/Factory-Loesung fuer Editor-Aktionen einfuehren. Alternativ den Typ in `TrainingPlanEditorService` umbenennen, wenn er bewusst zustandslos bleiben soll.

### P2 - Runtime-`fatalError` bei ModelContainer-Erstellung

Fundstellen:

- `Data/SwiftDataModels/GymTrackerModelContainer.swift:29`
- `Features/Plan/PlanPreviewData.swift:28`
- `Features/Plan/PlanPreviewData.swift:37`

Risiko: Bei Container-Initialisierungsfehlern beendet die App sofort. Fuer Preview-Code ist das vertretbarer, fuer die Live-App sollte ein kontrollierter Fehlerzustand oder zumindest eine zentral sichtbare Diagnose existieren.

Empfehlung: Live-Container-Erstellung in eine fallible Factory verschieben und im App-Root einen Fehlerbildschirm oder Recovery-Hinweis anzeigen. Preview-`fatalError` kann bleiben, sollte aber klar als Preview-only eingegrenzt sein.

### P3 - Tests sind fachlich gut, aber stark target-intern gebuendelt

Fundstelle: `Tests/ViewModelTests/DashboardViewModelTests.swift` enthaelt neben Dashboard auch `TrainingPlanEditorViewModelTests` und `PlanViewPresentationTests`.

Risiko: Testdateinamen spiegeln ihren Inhalt nicht mehr wider. Neue Entwickler finden relevante Tests schlechter, und selektive Testlaeufe werden unuebersichtlicher.

Empfehlung: Tests in `TrainingPlanEditorViewModelTests.swift` und `PlanViewPresentationTests.swift` splitten und im Xcode-Projekt referenzieren.

### P3 - Keine explizite Lint-/Format-Konfiguration gefunden

Fundstelle: keine `swiftlint`, `SwiftFormat` oder vergleichbare Konfiguration im Repository gefunden.

Risiko: Stilfragen bleiben manuell, und grosse SwiftUI-Dateien koennen weiter wachsen, ohne automatisierte Warnung zu Komplexitaet, Dateilaenge oder Force-Unwraps zu geben.

Empfehlung: SwiftFormat und optional SwiftLint einfuehren. Fuer dieses Projekt waeren Regeln zu Dateilaenge, Typ-Laenge und `fatal_error_message` besonders nuetzlich.

## Naechste empfohlene Schritte

1. `build/` aus der Versionskontrolle entfernen und `.gitignore` ergaenzen.
2. UI-Test-Target anlegen und einen stabilen Smoke Flow fuer Plan -> Workout -> Session -> History implementieren.
3. `HistoryView.swift` und `ActiveSessionView.swift` analog zu `PlanPresentation.swift` schrittweise um reine Presentation-/Formatter-Logik erleichtern.
4. Entscheidung zur Repository-Schicht treffen: entfernen oder konkretisieren.
5. Testdateien nach getesteter Komponente splitten.
