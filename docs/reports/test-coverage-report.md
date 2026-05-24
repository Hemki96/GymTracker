# Test Coverage Report

Datum: 2026-05-24
Projekt: GymTracker iOS
Status: Abschnitt 4 noch nicht gestartet; bestehende Tests in Abschnitt 1 dokumentiert und verifiziert

## Bestehende Testabdeckung

Vorhandenes Test-Target:

- `GymTrackerTests`

Vorhandene Testbereiche:

- `Tests/DomainModelTests/VolumeCalculatorTests.swift`
- `Tests/DomainModelTests/PainThresholdEvaluatorTests.swift`
- `Tests/DomainModelTests/RIRAnalyzerTests.swift`
- `Tests/DomainModelTests/ChartDataMapperTests.swift`
- `Tests/DomainModelTests/TrainingExportServiceTests.swift`
- `Tests/DomainModelTests/TrainingModelTests.swift`
- `Tests/SeedDataTests/DemoDataServiceTests.swift`
- `Tests/SeedDataTests/SeedDataServiceTests.swift`
- `Tests/SessionTests/SessionStartServiceTests.swift`
- `Tests/SessionTests/SessionCompletionServiceTests.swift`
- `Tests/ViewModelTests/DashboardViewModelTests.swift`

## Aktueller Testlauf

Ausgefuehrter Befehl:

```text
xcodebuild test -scheme GymTracker -project GymTracker.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'
```

Ergebnis:

- `TEST SUCCEEDED`
- Xcode Result: `/Users/christian/Library/Developer/Xcode/DerivedData/GymTracker-cvgfjtxlfrvcxldhpjbonwcruhsg/Logs/Test/Test-GymTracker-2026.05.24_10-17-57-+0200.xcresult`
- Alle in der Ausgabe sichtbaren Test-Suites bestanden: `TrainingPlanEditorViewModelTests`, `SessionCompletionServiceTests`, `SeedDataServiceTests`, `VolumeCalculatorTests`, `DashboardViewModelTests`, `SessionStartServiceTests`, `DemoDataServiceTests`, `PlanViewPresentationTests`, `PainThresholdEvaluatorTests`, `TrainingModelTests`, `ChartDataMapperTests`, `RIRAnalyzerTests`, `TrainingExportServiceTests`.

Qualitative Abdeckung:

- Domain Services: gut abgedeckt.
- SwiftData-Modellgraph: teilweise abgedeckt.
- Seed-/Demo-Import: gut abgedeckt.
- Session Start/Completion/Editing: gut abgedeckt.
- Plan Presentation und Editor ViewModel: teilweise abgedeckt.
- SwiftUI Views: nicht direkt ueber UI Tests abgedeckt.
- Navigation: nicht ueber UI Tests abgedeckt.
- Accessibility, Dynamic Type, Rotation, Dark Mode: keine automatisierten Tests gefunden.

## Fehlende Tests

- UI Tests fuer kritische User Flows.
- Tests fuer Formularfehlerzustaende in Plan-Editor-Forms.
- Tests fuer Loading-/Error-State-Anzeige.
- Tests fuer Navigation zwischen Plan, Workout, aktiver Session, Summary und History.
- Tests fuer Empty States in History/Analytics.
- Tests fuer Offline-/Import-Fehlerfaelle.
- Tests fuer SwiftData-Container-Fehlerpfade.
- Tests fuer Accessibility Labels und Dynamic Type Layout.

## Kritische Risiken

- Kein `GymTrackerUITests` Target vorhanden.
- Tests fuer `TrainingPlanEditorViewModel` und `PlanViewPresentationTests` liegen in `DashboardViewModelTests.swift`, was Wartbarkeit senkt.
- Keine automatisierte Coverage-Auswertung im Repo dokumentiert.
- Keine Lint-/Format-Pruefung als Qualitaets-Gate gefunden.

## Flaky Tests

In der statischen Analyse wurden keine eindeutig instabilen Tests identifiziert. Potenzielle Flakiness-Quellen:

- Datum-/Sortierlogik mit `.now`, wenn Tests nicht fixierte Zeitpunkte verwenden.
- SwiftData In-Memory-Kontexte muessen weiter serialisiert bleiben, wenn ModelContainer parallel Probleme macht.
- UI Tests fehlen noch; Flakiness kann erst nach Einfuehrung bewertet werden.

## Testqualitaet

Staerken:

- Nutzung von Swift Testing.
- Viele Tests verwenden In-Memory-`ModelContainer`.
- Domain Services sind ohne UI testbar.
- Session- und SeedData-Tests pruefen relevante Edge Cases.

Verbesserungen:

- Testdateien nach getesteten Komponenten splitten.
- Gemeinsame Test-Fixtures fuer ModelContainer und Beispielplaene extrahieren.
- Force-Unwraps in Tests durch `#require` ersetzen.
- UI-Test-Target anlegen.
- Coverage mit `xcodebuild test -enableCodeCoverage YES` regelmaessig messen.

## Naechste Test-Schritte

1. In Abschnitt 4 Teststruktur detailliert analysieren.
2. Danach fehlende Unit Tests ergaenzen.
3. Danach UI-Test-Target und kritische Flows ergaenzen.
4. Coverage mit `-enableCodeCoverage YES` messen und dokumentieren.
