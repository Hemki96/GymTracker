# GymTracker

Native iOS-App zum Planen, Tracken, Auswerten und Exportieren von Gym-Sessions auf Basis eines strukturierten Trainingsblocks.

## Architektur

GymTracker ist als schlanke SwiftUI-App mit klarer Trennung zwischen UI, Domain und Persistenz aufgebaut.

```text
App/
  App-Lifecycle, SwiftData-Container, Seed-Import
Data/
  SwiftData-Modelle, Seed-Daten, Repository-Protokolle
Domain/
  Status-Enums, Summary-Modelle, Services fuer Session-, Analyse- und Exportlogik
Features/
  SwiftUI-Views und kleine ViewModels pro Feature
DesignSystem/
  Theme-Tokens fuer Spacing, Farben und wiederkehrende UI-Konventionen
Tests/
  Swift Testing Suites fuer Domain Services, SwiftData-Modelle, Seeds und ViewModels
```

Die Views sind fuer Darstellung, Navigation und SwiftUI-State verantwortlich. Fachlogik liegt in Services wie `SessionStartService`, `SessionCompletionService`, `SessionEditingService`, `ChartDataMapper`, `VolumeCalculator`, `PainThresholdEvaluator`, `RIRAnalyzer`, `TrainingExportService` und `SeedDataService`.

## Datenfluss

1. `GymTrackerApp` erzeugt `AppEnvironment.live()`.
2. `GymTrackerModelContainer.make()` stellt den SwiftData-Container bereit.
3. `SeedDataService` validiert und importiert den B1-Trainingsplan einmalig ueber einen persistenten Marker.
4. Views lesen Daten ueber `@Query` und delegieren Mutationen an Domain Services.
5. Session-Abschluss aktualisiert Status, Dauer, Volumen, RIR, Schmerz und Warnungen.
6. Exporte werden als Markdown pro Session und CSV pro Trainingsblock erzeugt.

## QA-Standards

- Businesslogik bleibt ausserhalb der Views; Session-Start, Recovery, Satzbearbeitung, Completion, Analyse und Export sind servicebasiert.
- ViewModels sind klein und ohne SwiftUI-Laufzeit testbar.
- Domain Services sind mit Swift Testing abgedeckt.
- Leere Zustaende nutzen `ContentUnavailableView`.
- Fehlerfaelle fuer Session-Start, Speichern, Abschluss und Export werden sichtbar behandelt oder getestet.
- Aktive Session Recovery ist ueber `SessionStartService.activeSession()` und `startOrResumeSession(from:)` abgedeckt.
- Seed-Daten werden vor Import auf 6 Wochen, 18 Sessions und 108 Uebungszeilen validiert.
- Exportvalidierung deckt Markdown, CSV-Escaping, Dateinamen und fehlende Workout-Zuordnung ab.
- Dark Mode und Dynamic Type stuetzen sich auf systemische SwiftUI-Farben, relative Fonts und flexible Grids.
- Accessibility Labels sind fuer icon-only oder mehrdeutige Controls gesetzt; weitere UI-Audit-Tiefe sollte mit VoiceOver-Smoke-Tests erfolgen.

## Setup

Voraussetzungen:

- Xcode 16 oder neuer
- iOS Simulator oder angeschlossenes iOS-Geraet
- Swift 6 Projektkonfiguration

Projekt oeffnen:

```bash
open GymTracker.xcodeproj
```

Build ohne Codesigning:

```bash
xcodebuild \
  -project GymTracker.xcodeproj \
  -scheme GymTracker \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Fuer Device-Builds in Xcode muss im Target `GymTracker` ein Development Team gesetzt werden.

## Tests

Simulator-Testlauf, angepasst an die lokal verfuegbare Destination:

```bash
xcodebuild test \
  -project GymTracker.xcodeproj \
  -scheme GymTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'
```

Wenn kein passender Simulator existiert, zuerst die verfuegbaren Ziele anzeigen:

```bash
xcodebuild -list -project GymTracker.xcodeproj
xcrun simctl list devices available
```

Die Tests nutzen Swift Testing. SwiftData-nahe Suites sind serialisiert, damit In-Memory-Container und Model-Schema-Zugriffe im Simulator stabil laufen.

## Bekannte Einschraenkungen

- Repository-Protokolle sind vorbereitet, aber noch nicht als echte Datenzugriffsschicht implementiert.
- UI-Snapshot-, VoiceOver- und Dynamic-Type-Automation fehlen noch; die aktuelle Absicherung ist strukturell und ueber Services/Domain-Tests.
- Exporte werden aktuell in ein temporaeres App-Verzeichnis geschrieben und per ShareLink geteilt.
- HealthKit, Cloud-Sync und Multi-User-Szenarien sind nicht implementiert.
- Seed-Import ist bewusst idempotent, aber nicht als Migrationssystem fuer spaetere Planversionen ausgebaut.
