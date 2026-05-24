# Refactoring Issue Report

Datum: 2026-05-24
Projekt: GymTracker iOS
Status: Abschnitt 2 Refactoring gestartet; Struktur-Hygiene und erste PlanView-Entkopplung abgeschlossen

## Executive Summary

GymTracker ist als native SwiftUI-/SwiftData-App mit einer groben Feature-/Domain-/Data-Struktur aufgebaut. Die bestehende Richtung passt zur vorhandenen ADR `docs/adr/0001-native-swiftui-mvvm-swiftdata.md`: SwiftUI, MVVM, SwiftData, Domain Services und testbare fachliche Logik.

Die Analyse zeigt aber klare Wartbarkeitsrisiken: mehrere SwiftUI-Dateien sind sehr gross, `PlanView` kapselt weiterhin viel UI, Navigation und Fehlerzustand in einem Typ, die direkten Plan-Side-Effects wurden aber in Abschnitt 2.2/2.3 in `PlanActionService` verschoben und unit-getestet. `TrainingPlanEditorViewModel` ist eher ein grosser Editor-Service als ein fokussiertes ViewModel. Ein UI-Test-Target fehlt, und es gibt keine Lint-/Format-Konfiguration.

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
- `Data/`: SwiftData-Modelle, Seed-/Demo-Daten
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

Status: Behoben in Abschnitt 2.1.

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

Beobachtung: `PlanView` erstellte Plaene, lud Demo-Daten, importierte JSON, duplizierte, archivierte und loeschte direkt ueber `modelContext`.

Risiko: Die View ist schwer isoliert testbar und mischt UI mit Persistenz-/Importlogik.

Empfehlung: Plan-Aktionen in einen Plan-Service oder Store auslagern und nur UI-State in der View halten.

Status: Teilweise behoben in Abschnitt 2.2/2.3. Die genannten Side Effects liegen jetzt in `PlanActionService` und sind mit Unit Tests abgesichert. Weitere View-Aufteilung bleibt offen.

### P2 - `TrainingPlanEditorViewModel` ist zu gross und service-artig

Fundstelle: `Features/Plan/TrainingPlanEditorViewModel.swift`, 521 Zeilen

Beobachtung: Der Typ validiert, mutiert, dupliziert, loescht, verschiebt, renummeriert, klont und synchronisiert Plan-, Wochen-, Session-, Exercise- und Set-Daten.

Risiko: Eine Aenderung an einem Unterbereich kann andere Editor-Regeln brechen. Der Name `ViewModel` passt nur teilweise, weil kein beobachtbarer UI-State gehalten wird.

Empfehlung: In fokussierte Editor-Services oder Commands teilen: Validation, Clone/Duplicate, Reordering/Renumbering, Prescription Sync.

### P2 - Repository-Schicht ist leer

Fundstelle: `Data/Repositories/RepositoryProtocols.swift`

Risiko: Die Architektur deutet eine Repository-Schicht an, waehrend Views und Services SwiftData direkt nutzen. Das ist als bewusste Architektur moeglich, aber aktuell inkonsistent dokumentiert.

Empfehlung: Platzhalter entfernen oder konkrete Protokolle fuer Plan-/Session-/History-Zugriffe einfuehren.

Status: Behoben in Abschnitt 2.1 durch Entfernen des leeren Platzhalters. Eine spaetere Store-/Repository-Entscheidung bleibt offen, aber es gibt keinen toten Protokolltyp mehr.

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

### 2.1 Struktur-Hygiene: Build-Artefakte entfernt

Dateien:

- `.gitignore`
- `build/GymTracker.build/...` aus Git entfernt

Begruendung:

- `build/` enthielt 22 getrackte Xcode-Build-Artefakte.
- Build-Ergebnisse gehoeren nicht in die Versionskontrolle.

Ergebnis:

- `git ls-files build | wc -l` ergibt `0`.
- Lokaler `build/`-Ordner wurde entfernt.
- Zukuenftige Build-, DerivedData-, xcresult-, xcuserstate- und DS_Store-Artefakte werden ignoriert.

### 2.1 Dead Code: Leeres Repository-Protokoll entfernt

Dateien:

- `Data/Repositories/RepositoryProtocols.swift`
- `GymTracker.xcodeproj/project.pbxproj`

Begruendung:

- Der Typ `TrainingRepository` hatte keine Anforderungen und keine Referenzen.
- Ein leerer Repository-Platzhalter ist keine nutzbare Abstraktion und verschleiert die echte Architekturentscheidung.

Ergebnis:

- Datei geloescht.
- Xcode-Projekt bereinigt.
- `rg "RepositoryProtocols|TrainingRepository|Repositories"` findet keine Referenzen mehr.
- Build erfolgreich.
- Tests erfolgreich.

### 2.2/2.3 SwiftUI/ViewModel: Plan-Aktionen aus `PlanView` extrahiert

Dateien:

- `Features/Plan/PlanActionService.swift`
- `Features/Plan/PlanView.swift`
- `Tests/PlanTests/PlanActionServiceTests.swift`
- `GymTracker.xcodeproj/project.pbxproj`

Begruendung:

- Direkte SwiftData-Mutationen und Import-/Demo-Side-Effects in `PlanView` erschwerten Unit Tests und vergroesserten die View.
- Ein kleiner Service reduziert die UI-Verantwortung und schafft eine testbare Grenze fuer Plan-Aktionen.

Ergebnis:

- `PlanActionService` kapselt Create, Demo-Load, Import, Duplicate, Archive und Delete.
- `PlanView` delegiert diese Aktionen und bleibt fuer UI-State, Navigation und Alerts verantwortlich.
- Vier neue Unit Tests decken Create, Archive, Delete und Duplicate ab.
- RED/GREEN-Nachweis wurde dokumentiert.
- Build erfolgreich.
- Tests erfolgreich.

## Build- und Teststatus

Build:

- Befehl: `xcodebuild build -scheme GymTracker -project GymTracker.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'`
- Ergebnis: `BUILD SUCCEEDED`

Tests:

- Befehl: `xcodebuild test -scheme GymTracker -project GymTracker.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'`
- Ergebnis: `TEST SUCCEEDED`
- Letzter Testlauf nach Refactoring 2.2/2.3: `Test-GymTracker-2026.05.24_13-32-29-+0200.xcresult`

Dokumentierte Warnungen:

- Xcode meldet mehrere passende Simulator-Destinations fuer `iPhone 16, OS=18.6` und nutzt die erste.
- AppIntents-Metadatenextraktion wird uebersprungen, weil keine `AppIntents.framework`-Abhaengigkeit vorhanden ist.

## Risiken

- Grosse View-Dateien sind das wichtigste Wartbarkeitsrisiko.
- Fehlendes UI-Test-Target ist das wichtigste QA-Risiko.
- Versionierte Build-Artefakte waren das wichtigste Repository-Hygiene-Risiko und sind in Abschnitt 2.1 behoben.
- Direkter SwiftData-Zugriff in Views ist reduziert, aber weiter ein mittleres Architektur-Risiko, solange die Store-/Repository-Strategie unentschieden ist.

## Priorisierung

1. UI-Test-Target und Smoke Tests ergaenzen.
2. `PlanView`, `ActiveSessionView` und `HistoryView` schrittweise aufteilen.
3. `TrainingPlanEditorViewModel` in kleinere Services splitten.
4. Store-/Repository-/SwiftData-Direktzugriff per ADR entscheiden.
5. Testdateien splitten und Lint-/Format-Automation einfuehren.
