# Refactoring Issue Report

Datum: 2026-05-24
Projekt: GymTracker iOS
Status: Abschnitt 1 Projektanalyse abgeschlossen und verifiziert; Refactoring noch nicht gestartet

## Executive Summary

GymTracker ist als native SwiftUI-/SwiftData-App mit einer groben Feature-/Domain-/Data-Struktur aufgebaut. Die bestehende Richtung passt zur vorhandenen ADR `docs/adr/0001-native-swiftui-mvvm-swiftdata.md`: SwiftUI, MVVM, SwiftData, Domain Services und testbare fachliche Logik.

Die Analyse zeigt aber klare Wartbarkeitsrisiken: mehrere SwiftUI-Dateien sind sehr gross, `PlanView` kapselt noch UI, SwiftData-Zugriff, Import, Demo-Load, Navigation und Fehlerzustand in einem Typ, `TrainingPlanEditorViewModel` ist eher ein grosser Editor-Service als ein fokussiertes ViewModel, und die geplante Repository-Schicht ist aktuell nur ein Platzhalter. Ein UI-Test-Target fehlt, Build-Artefakte sind versioniert, und es gibt keine Lint-/Format-Konfiguration.

## Erledigte Analysepunkte

- [x] 1.1 Projektstruktur analysiert
- [x] 1.1 Module identifiziert
- [x] 1.1 Architektur identifiziert
- [x] 1.1 Datenfluss analysiert
- [x] 1.1 Abhaengigkeiten analysiert
- [x] 1.1 Externe Libraries dokumentiert
- [x] 1.1 Dead Code identifiziert
- [x] 1.1 Ungenutzte Dateien identifiziert
- [x] 1.2 Architektur Review durchgefuehrt
- [x] 1.3 Code Quality Analyse durchgefuehrt

## Projektstruktur

Top-Level-Struktur:

- `App/`: App Root und `AppEnvironment`
- `Features/`: SwiftUI Feature Screens und feature-nahe Presentation/ViewModel-Typen
- `Domain/`: fachliche Services, Enums und kleine Domain Models
- `Data/`: SwiftData-Modelle, Seed-/Demo-Daten, Repository-Platzhalter
- `DesignSystem/`: Theme-Modifier und Design Tokens
- `Tests/`: Unit Tests fuer Domain, SeedData, Sessions und ViewModels
- `docs/`: Produkt-, Architektur-, QA- und Report-Dokumentation
- `build/`: versionierte Xcode-Build-Artefakte

## Abhaengigkeiten

Interne Frameworks und Apple APIs:

- SwiftUI
- SwiftData
- Foundation
- UniformTypeIdentifiers
- Swift Testing (`import Testing`)

Externe Libraries:

- Keine externen Swift Package Dependencies im Xcode-Projekt gefunden.
- Kein `Package.resolved` gefunden.
- Keine SwiftLint-/SwiftFormat-Konfiguration gefunden.

## Datenfluss

1. `GymTrackerApp` erstellt eine `TabView` und injiziert den SwiftData `ModelContainer`.
2. Feature Views lesen SwiftData ueber `@Query` und `@Environment(\.modelContext)`.
3. Domain Services wie `SessionStartService`, `SessionCompletionService`, `VolumeCalculator`, `RIRAnalyzer`, `PainThresholdEvaluator`, `ChartDataMapper` und `TrainingExportService` kapseln fachliche Regeln.
4. SwiftData-Modelle bilden Trainingsplaene, Wochen, Workouts, geplante Uebungen, geplante Saetze, Session Logs, Exercise Logs und Set Logs ab.
5. Tests nutzen In-Memory-`ModelContainer`, um Domain- und ViewModel-Verhalten zu pruefen.

## Issues

### P1 - Kein UI-Test-Target fuer kritische User Flows

Fundstelle: `GymTracker.xcodeproj/project.pbxproj`, Target-Liste enthaelt nur `GymTracker` und `GymTrackerTests`.

Risiko: Navigation, Formularvalidierung, Loading-/Error-States, Listen, Detailansichten und kritische User Flows werden nicht end-to-end abgesichert.

Empfehlung: `GymTrackerUITests` anlegen und Smoke Tests fuer Plan anlegen, Demo-Plan laden, Session starten, Satz erfassen, Session abschliessen und Historie pruefen.

### P1 - Build-Artefakte sind versioniert

Fundstelle: `build/GymTracker.build/Release-iphoneos/...`

Risiko: Veraltete Derived-/Build-Dateien koennen Merge-Konflikte, irrefuehrende Diffs und falsche Build-Sicherheit erzeugen.

Empfehlung: `build/` aus Git entfernen, `.gitignore` ergaenzen und nur reproduzierbare Quellen, Fixtures und Projektdateien versionieren.

### P2 - Grosse SwiftUI-Dateien mit gemischten Verantwortlichkeiten

Fundstellen:

- `Features/History/HistoryView.swift`: 699 Zeilen
- `Features/Session/ActiveSessionView.swift`: 657 Zeilen
- `Features/Plan/PlanView.swift`: 601 Zeilen
- `Features/Plan/PlanEditorForms.swift`: 560 Zeilen
- `Features/Analytics/AnalyticsView.swift`: 282 Zeilen

Risiko: UI, Query-Zugriff, Formatierung, Navigation, lokale Mutationen und Side Effects liegen teilweise zusammen. Das erhoeht Aenderungsrisiko und senkt Testbarkeit.

Empfehlung: Reine Presentation-/Formatter-/Mapper-Typen und kleine SwiftUI-Komponenten extrahieren. Pro Extraktion Build und Tests laufen lassen.

### P2 - `PlanView` fuehrt Side Effects direkt aus

Fundstelle: `Features/Plan/PlanView.swift:163`

Beobachtung: `PlanView` erstellt Plaene, laedt Demo-Daten, importiert JSON, dupliziert, archiviert und loescht direkt ueber `modelContext`.

Risiko: Die View ist schwer isoliert testbar und mischt UI mit Persistenz-/Importlogik.

Empfehlung: Plan-Aktionen in einen Plan-Service oder Store auslagern und nur UI-State in der View halten.

### P2 - `TrainingPlanEditorViewModel` ist zu gross und service-artig

Fundstelle: `Features/Plan/TrainingPlanEditorViewModel.swift`, 521 Zeilen

Beobachtung: Der Typ validiert, mutiert, dupliziert, loescht, verschiebt, renummeriert, klont und synchronisiert Plan-, Wochen-, Session-, Exercise- und Set-Daten.

Risiko: Eine Aenderung an einem Unterbereich kann andere Editor-Regeln brechen. Der Name `ViewModel` passt nur teilweise, weil kein beobachtbarer UI-State gehalten wird.

Empfehlung: In fokussierte Editor-Services oder Commands teilen: Validation, Clone/Duplicate, Reordering/Renumbering, Prescription Sync.

### P2 - Repository-Schicht ist leer

Fundstelle: `Data/Repositories/RepositoryProtocols.swift`

Risiko: Die Architektur deutet eine Repository-Schicht an, waehrend Views und Services SwiftData direkt nutzen. Das ist als bewusste Architektur moeglich, aber aktuell inkonsistent dokumentiert.

Empfehlung: Platzhalter entfernen oder konkrete Protokolle fuer Plan-/Session-/History-Zugriffe einfuehren.

### P2 - AppEnvironment wird kaum genutzt

Fundstelle: `App/AppEnvironment.swift`

Beobachtung: `AppEnvironment` kapselt `ModelContainer` und `makeDashboardViewModel`, aber `DashboardView` ist nicht in der App-Tab-Struktur verdrahtet.

Risiko: Dependency Injection ist begonnen, aber nicht konsequent. Unklar bleibt, ob Dashboard aktiv, geplant oder veraltet ist.

Empfehlung: Dashboard-Entscheidung treffen und Environment entweder ausbauen oder vereinfachen.

### P2 - Runtime-`fatalError` bei SwiftData-Container-Erstellung

Fundstelle: `Data/SwiftDataModels/GymTrackerModelContainer.swift`

Risiko: Ein Container-Initialisierungsfehler beendet die App hart. Fuer Live-App-Start ist ein kontrollierter Fehlerzustand robuster.

Empfehlung: Fallible Factory oder App-Root-Fehlerzustand einfuehren; Preview-`fatalError` separat bewerten.

### P3 - Tests sind teilweise in unpassenden Dateien gebuendelt

Fundstelle: `Tests/ViewModelTests/DashboardViewModelTests.swift`

Beobachtung: Die Datei enthaelt `DashboardViewModelTests`, `TrainingPlanEditorViewModelTests` und `PlanViewPresentationTests`.

Risiko: Testnavigation und selektive Testausfuehrung werden unuebersichtlicher.

Empfehlung: In getrennte Testdateien splitten und Xcode-Projekt referenzieren.

### P3 - Keine Lint-/Format-Automation

Fundstelle: keine `.swiftlint.yml`, keine `.swiftformat`.

Risiko: Dateilaenge, Typ-Laenge, Namenskonventionen und Force-Unwraps bleiben manuell.

Empfehlung: SwiftFormat und optional SwiftLint einfuehren; Regeln fuer Dateilaenge, Typ-Laenge, Force-Unwraps und `fatalError` pruefen.

### P3 - Force-Unwraps in Tests

Fundstelle: `Tests/DomainModelTests/ChartDataMapperTests.swift`

Risiko: In Tests akzeptabel, aber `TimeZone(secondsFromGMT: 0)!` und `components.date!` koennen bei spaeterer Anpassung unschoene Crashs erzeugen.

Empfehlung: Mit `#require` oder explizitem Guard stabilisieren.

## Refactorings

Noch nicht gestartet in diesem Durchlauf. Abschnitt 2 wird erst begonnen, nachdem Abschnitt 1 dokumentiert, Build und Tests erfolgreich verifiziert sind.

## Build- und Teststatus

Build:

- Befehl: `xcodebuild build -scheme GymTracker -project GymTracker.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'`
- Ergebnis: `BUILD SUCCEEDED`

Tests:

- Befehl: `xcodebuild test -scheme GymTracker -project GymTracker.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'`
- Ergebnis: `TEST SUCCEEDED`

Dokumentierte Warnungen:

- Xcode meldet mehrere passende Simulator-Destinations fuer `iPhone 16, OS=18.6` und nutzt die erste.
- AppIntents-Metadatenextraktion wird uebersprungen, weil keine `AppIntents.framework`-Abhaengigkeit vorhanden ist.

## Risiken

- Grosse View-Dateien sind das wichtigste Wartbarkeitsrisiko.
- Fehlendes UI-Test-Target ist das wichtigste QA-Risiko.
- Versionierte Build-Artefakte sind das wichtigste Repository-Hygiene-Risiko.
- Direkter SwiftData-Zugriff in Views ist ein mittleres Architektur-Risiko, solange die Repository-Strategie unentschieden ist.

## Priorisierung

1. UI-Test-Target und Smoke Tests ergaenzen.
2. `build/` aus Git entfernen und `.gitignore` einfuehren.
3. `PlanView`, `ActiveSessionView` und `HistoryView` schrittweise aufteilen.
4. `TrainingPlanEditorViewModel` in kleinere Services splitten.
5. Repository-/SwiftData-Direktzugriff per ADR entscheiden.
6. Testdateien splitten und Lint-/Format-Automation einfuehren.
