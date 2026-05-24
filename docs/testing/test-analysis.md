# Testanalyse und Teststrategie

Stand: 2026-05-24

## Executive Summary

Die App besitzt bereits eine solide Unit-Test-Basis mit Swift Testing, serialisierten SwiftData-Suites und In-Memory-`ModelContainer`-Fixtures. Aktuell sind 70 `@Test`-Faelle vorhanden. Der Schwerpunkt liegt auf Domain-Services, SwiftData-Modellen, Seed-/Demo-Daten, Session-Services, Plan-Aktionen und einigen ViewModel-/Presentation-Helfern.

Die wichtigsten Staerken sind reproduzierbare In-Memory-Persistenztests, klare Domain-Tests fuer RIR/Schmerz/Volumen und mehrere End-to-End-nahe Service-Tests fuer Session Start/Completion. Die wichtigsten Luecken liegen bei UI-Tests, Formular-/Navigation-Fehlerzustaenden, Import-Fehlerpfaden, Live-Persistenzfehlern, Accessibility/Dynamic Type und bei einer noch uneinheitlichen Test-Fixture-Struktur.

## Bestehende Teststruktur

Test-Target:

- `GymTrackerTests`

Gefundene Testbereiche:

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
- `Tests/PlanTests/PlanActionServiceTests.swift`
- `Tests/ViewModelTests/DashboardViewModelTests.swift`

Aktuelle Testanzahl nach Analyse-Ergaenzung:

- ViewModels/Presentation: 10 Tests
- Session: 13 Tests
- Plan Actions: 4 Tests
- Domain Models/Services: 32 Tests
- Seed/Demo Data: 11 Tests
- Gesamt: 70 Tests

## Abgedeckte Bereiche

### Business Logic

Gut abgedeckt:

- Volumenberechnung inklusive Warmup-Filter.
- RIR-Auswertung inklusive Grenzwerte, RPE-Textstatus und ungueltige Ziele.
- Schmerzschwellen inklusive fehlende Ziele, ungueltige Ist-Werte und Zielparser.
- Trainingsexport als Markdown/CSV inklusive Escaping und fehlendem Workout.
- Chart-Datenmapping fuer Wochenvolumen, Schmerz-/RIR-Trends, Gewichtsverlauf und Uebungsfilter.

Noch ausbaufaehig:

- Weitere Export-Edge-Cases mit Zeilenumbruechen in Notizen und Sonderzeichen in Dateinamen.
- Performance-Regressionen fuer grosse Trainingsbloecke.
- Kombinierte Warnlogik bei mehreren Uebungen/Saetzen.

### ViewModels und Presentation

Gut abgedeckt:

- `DashboardViewModel` Empty State.
- `TrainingPlanEditorViewModel` Validierung, Metadaten-Updates, Duplizieren, Verschieben und Loeschen von verschachtelten Planobjekten.
- `PlanOverviewViewModel` Gruppierung und Badges.
- `PlanView`/Presentation-Helfer fuer Wochen- und Workout-Sortierung.

Noch ausbaufaehig:

- `TrainingPlanEditorViewModelTests` liegen in `DashboardViewModelTests.swift`; das erschwert Navigation und Ownership.
- Formular-spezifische Fehlerzustaende in `PlanEditorForms` sind nicht direkt getestet.
- View-nahe UI-Zustaende wie Alerts, Dialoge, FileImporter-Fehler und Empty States sind nur indirekt abgedeckt.

### Services und State Management

Gut abgedeckt:

- `SessionStartService` erzeugt aktive Session-Graphs, nutzt geplante Sets, findet aktive Sessions nach Context-Neustart und verhindert parallele aktive Sessions.
- `SessionCompletionService` setzt Summary-Werte, Warnungen, Workout-Status und History-Fetchbarkeit.
- `SessionEditingService` deckt Hinzufuegen, Kopieren, Loeschen, Renummerieren und Summary-Refresh ab.
- `PlanActionService` deckt Create, Duplicate, Archive und Delete ab.

Neue Ergaenzungen:

- Fallback auf genau einen Draft-Set bei nicht numerischer oder `0`-Set-Prescription.
- Completion ohne abgeschlossene Saetze mit leerer Summary und Warnung.
- Negative Dauer wird auf `0` geklemmt.
- Set-Updates synchronisieren Parent-Prescriptions aus getrimmten, eindeutigen Werten.

Noch ausbaufaehig:

- `PlanActionService.importPlan` fuer leere URL-Ergebnisse, fehlerhaftes JSON und Security-Scoped-URL-Verhalten.
- Fehlerpfade bei `context.save()` sind nicht isoliert mockbar, weil Services direkt `ModelContext` verwenden.
- Es gibt keine separaten Repository-/Store-Abstraktionen, deshalb sind einige Services eher Integrationstests gegen SwiftData als reine Unit Tests.

### Networking und Offline-Verhalten

Aktueller Befund:

- Es wurde keine aktive Networking-Schicht gefunden (`URLSession`, HTTP-Clients oder API-Services sind nicht vorhanden).
- Die App arbeitet primaer offline/local-first ueber SwiftData und gebuendelte JSON-Seeddaten.

Abdeckung:

- Offline-nahe Kernpfade sind ueber In-Memory-SwiftData-Tests und Bundle-/Importtests teilweise abgedeckt.
- Fehlende Resource-Dateien, korruptes externes JSON und persistente Store-Fehler sollten noch explizit getestet werden.

### Async/Await

Aktueller Befund:

- Keine relevante Async/Await-Service-Schicht gefunden.
- `@MainActor` wird fuer Plan-Actions und Editor-ViewModels genutzt und in Tests korrekt markiert.

Empfehlung:

- Sobald echte Async-Flows entstehen, Testmuster mit kontrollierbaren Clock-/Client-Dependencies einfuehren.
- Keine Sleeps in Tests; stattdessen async APIs deterministisch injizieren.

## Instabilitaetsrisiken

Keine eindeutig flaky Tests wurden in der statischen Analyse gefunden. Potenzielle Risiken:

- Tests mit `.now` koennen bei enger Zeitlogik instabil werden. Viele kritische Tests nutzen bereits feste `Date(timeIntervalSince1970:)`-Werte.
- SwiftData-Tests sind korrekt serialisiert; diese Konvention sollte beibehalten werden.
- Simulator-Destinationen sind umgebungsabhaengig. Ein Baseline-Lauf mit `name=iPhone 16` ohne OS scheiterte, weil lokal kein `OS:latest` fuer dieses Geraet aufloesbar war.
- Die Test-Fixtures duplizieren ModelContainer-Schemas in mehreren Dateien. Schema-Drift wuerde mehrere Tests gleichzeitig brechen.

## Mock- und Fixture-Struktur

Aktuelle Struktur:

- In-Memory-`ModelContainer` wird je Testdatei lokal aufgebaut.
- Domain-Tests erzeugen Modelle direkt.
- Es gibt keine zentralen Test-Builder fuer `TrainingBlock`, `WorkoutPlan`, `SessionLog`, `ExerciseLog` und `SetLog`.

Empfohlene Struktur:

- `Tests/Support/ModelContainerFactory.swift`
- `Tests/Support/TrainingFixtures.swift`
- `Tests/Support/DateFixtures.swift`
- `Tests/Support/Assertions.swift`

Ziele:

- Weniger Schema-Duplikation.
- Lesbarere Testabsichten.
- Einfachere Edge-Case-Erzeugung.
- Stabilere Migration bei Model-Aenderungen.

## Fehlende Tests nach Prioritaet

### P0: Kritische Unit-/Service-Tests

- `PlanActionService.importPlan`:
  - leeres FileImporter-Ergebnis gibt `nil` zurueck.
  - ungueltige JSON-Datei propagiert Decode-Fehler.
  - importierter Plan wird als neuester Plan zurueckgegeben.
- `TrainingExportService`:
  - CSV-Escaping fuer Zeilenumbrueche in Notizen.
  - Slug-Erzeugung fuer Umlaute/Sonderzeichen im Export-Dateinamen.
- `SessionCompletionService`:
  - Warnungen bleiben nach `save(setLog:)` konsistent.
  - mehrere Uebungen werden sortiert und deterministisch gewarnt.

### P1: ViewModel- und Presentation-Tests

- `TrainingPlanEditorViewModel`:
  - Invalid duration wirft `validationFailed`.
  - Move am ersten/letzten Element bleibt stabil.
  - Delete renummeriert auch bei unsortierter Ausgangsliste korrekt.
- `PlanOverviewViewModel`:
  - Completed Plans erscheinen in aktiven Plaenen.
  - gleiche `createdAt`-Werte werden alphabetisch sortiert.
- `PlanDetailPresentation`:
  - `nil` week ergibt leere Workout-Liste.
  - gleiche `sortOrder` sortiert nach `dayNumber`.

### P2: Integration, UI und Accessibility

- UI-Test-Target `GymTrackerUITests` anlegen.
- Kritische Flows:
  - Demo-Plan laden.
  - Workout starten.
  - Set erfassen.
  - Session abschliessen.
  - History/Summary pruefen.
- Accessibility-Smoke-Tests fuer icon-only Controls und zentrale Navigation.
- Dynamic-Type-/Layout-Smoke fuer Dashboard, Plan, Active Session und Summary.

### P3: Performance-kritische Bereiche

- `ChartDataMapper.weeklyVolume` mit vielen Sessions/Sets messen.
- `TrainingExportService.csv(for:)` mit grossem Block messen.
- `SeedDataService.importSeedPlan` mit grossem Fixture messen.

Performance-Tests sollten Zielbudgets enthalten und nur fuer algorithmisch kritische Kernpfade laufen, nicht fuer jedes UI-Detail.

## Professionelle Teststrategie

### Testpyramide

- Viele schnelle Unit Tests fuer pure Domain-Logik.
- Mittelviele SwiftData-nahe Integrationstests fuer Services und Persistenz.
- Wenige, stabile UI Tests fuer kritische User Journeys.
- Manuelle Explorations-Checks fuer visuelle Qualitaet, Health-/Datenschutzthemen und Geraetevarianten.

### Namenskonvention

Tests sollen Verhalten beschreiben:

- Gut: `completeSessionWithNoCompletedSetsStoresEmptySummaryAndWarning`
- Gut: `importPlanReturnsNilForEmptyPickerResult`
- Schlecht: `testImport`

### Stabilitaetsregeln

- Feste Daten statt `.now`, ausser das Verhalten selbst ist Zeitaktualisierung.
- Kein Zugriff auf Live-Dateisystem ausser temporaere Testdateien.
- Keine Netzwerkanforderungen in Unit Tests.
- Keine Sleeps, keine Timer-Abhaengigkeit.
- SwiftData-Suites serialisiert halten.
- Pro Test eigener In-Memory-Container.

### Mocking-Regeln

- Pure Domain-Logik ohne Mocks testen.
- Services mit SwiftData-In-Memory testen, solange der Persistenzvertrag relevant ist.
- Fuer import-/dateibasierte Services kleine temporaere Dateien nutzen.
- Bei zukuenftigen Network-Services ein Protokoll wie `HTTPClient` injizieren und mit deterministischen Fakes testen.

## Empfohlene naechste Umsetzung

1. Test-Support-Folder einfuehren und Container-/Fixture-Duplikation reduzieren.
2. `DashboardViewModelTests.swift` in thematisch passende Dateien splitten.
3. P0-Luecken fuer Import, Export und Session-Warnungen schliessen.
4. UI-Test-Target mit einem einzigen Happy Path einfuehren.
5. Coverage-Bericht regelmaessig aus `xcodebuild test -enableCodeCoverage YES` ableiten.

