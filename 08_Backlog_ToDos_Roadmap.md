# Backlog, To-dos und Roadmap

## 1. Roadmap

## Phase 0: Projektsetup

Ziel: lauffähige leere App mit Architekturgrundlage.

### To-dos

- Xcode-Projekt erstellen
- Bundle Identifier definieren
- Deployment Target festlegen
- SwiftUI App Lifecycle verwenden
- Ordnerstruktur anlegen
- SwiftData Container konfigurieren
- Basis-Theme erstellen
- Testtarget anlegen
- README im Repository erstellen
- ADR für Architekturentscheidung schreiben

### Ergebnis

Eine startbare App mit leerem Dashboard und funktionierendem Testtarget.

## Phase 1: Domain-Modell und Seed-Daten

Ziel: Trainingsplan aus der Vorlage als Datenmodell verfügbar machen.

### User Story 1.1: Trainingsblock speichern

**Als Nutzer** möchte ich einen Trainingsblock in der App sehen, **damit** ich meinen aktuellen Plan strukturiert verfolgen kann.

**Akzeptanzkriterien:**

- Blockname wird angezeigt.
- Ziel des Blocks wird angezeigt.
- Wochen 1–6 sind vorhanden.
- Jeder Woche sind drei Trainingstage zugeordnet.

### User Story 1.2: Übungen aus Vorlage hinterlegen

**Als Nutzer** möchte ich alle Übungen aus meiner Vorlage in der App sehen, **damit** ich nach meinem realen Plan trainieren kann.

**Akzeptanzkriterien:**

- Alle Übungen aus der Excel-Vorlage sind vorhanden.
- Übungen sind den richtigen Tagen zugeordnet.
- Cueing, Tempo, Sätze, Wiederholungen, Gewicht, Ziel-RIR, Schmerz-Ziel und Notizen werden übernommen.

### To-dos

- SwiftData Models erstellen
- Enums erstellen
- Seed-JSON erstellen
- Seed Import Service bauen
- Repository für Trainingsplan erstellen
- Unit Tests für Seed-Import schreiben
- Validierung: 6 Wochen, 18 Sessions, 108 Übungszeilen

## Phase 2: Plananzeige

Ziel: Nutzer kann Wochen, Tage und Übungen durchsuchen.

### User Story 2.1: Wochenübersicht anzeigen

**Als Nutzer** möchte ich meine Trainingswochen sehen, **damit** ich weiß, wo ich im Block stehe.

**Akzeptanzkriterien:**

- Woche 1–6 sind auswählbar.
- Jede Woche zeigt Tag 1–3.
- Abgeschlossene Einheiten sind markiert.

### User Story 2.2: Workout Details anzeigen

**Als Nutzer** möchte ich die Details eines Trainingstages sehen, **damit** ich mich auf die Session vorbereiten kann.

**Akzeptanzkriterien:**

- Alle Übungen des Tages werden angezeigt.
- Jede Übung zeigt Planwerte.
- Schmerz-Ziel ist bei relevanten Übungen sichtbar.

### To-dos

- PlanView erstellen
- WeekSelector bauen
- WorkoutDayCard bauen
- WorkoutDetailView bauen
- ExercisePlanRow bauen
- Preview-Daten erstellen
- Snapshot-ähnliche UI-Tests vorbereiten

## Phase 3: Session-Tracking

Ziel: Nutzer kann eine Session starten, tracken und abschließen.

### User Story 3.1: Session starten

**Als Nutzer** möchte ich eine geplante Session starten, **damit** ich während des Trainings geführt werde.

**Akzeptanzkriterien:**

- Button „Session starten“ legt SessionLog an.
- Übungen werden in ExerciseLogs kopiert.
- geplante Sätze werden initial angelegt.
- Session bleibt aktiv, wenn App geschlossen wird.

### User Story 3.2: Satzdaten erfassen

**Als Nutzer** möchte ich pro Satz Gewicht, Reps, RIR und Schmerz erfassen, **damit** ich meine Leistung dokumentiere.

**Akzeptanzkriterien:**

- Satzdaten können geändert werden.
- Eingaben werden automatisch gespeichert.
- Satz kann als erledigt markiert werden.
- weitere Sätze können ergänzt werden.

### User Story 3.3: Übung abschließen

**Als Nutzer** möchte ich eine Übung abschließen, **damit** ich strukturiert durch die Session geführt werde.

**Akzeptanzkriterien:**

- Übungsstatus wird gespeichert.
- nächste Übung wird angeboten.
- Abweichungen bleiben sichtbar.

### To-dos

- ActiveSessionView bauen
- ExerciseTrackingView bauen
- SetLogRow bauen
- RIR-Chips bauen
- Pain-Slider bauen
- Auto-Save Service bauen
- Active Session Recovery bauen
- Unit Tests für Session-Erstellung schreiben

## Phase 4: Session-Zusammenfassung

Ziel: Nach dem Training erhält der Nutzer Feedback.

### User Story 4.1: Session abschließen

**Als Nutzer** möchte ich eine Session abschließen, **damit** meine Ergebnisse gespeichert und ausgewertet werden.

**Akzeptanzkriterien:**

- Abschlusszeit wird gespeichert.
- Dauer wird berechnet.
- Volumen wird berechnet.
- maximaler Schmerz wird berechnet.
- durchschnittlicher RIR wird berechnet.

### User Story 4.2: Warnungen anzeigen

**Als Nutzer** möchte ich sehen, ob Schmerz- oder RIR-Ziele verfehlt wurden, **damit** ich mein Training anpassen kann.

**Akzeptanzkriterien:**

- Schmerzüberschreitungen werden angezeigt.
- RIR-Abweichungen werden angezeigt.
- Warnungen sind textlich verständlich.

### To-dos

- SessionSummaryView bauen
- VolumeCalculator implementieren
- PainThresholdEvaluator implementieren
- RIRAnalyzer implementieren
- SessionSummaryBuilder implementieren
- Tests für Auswertung schreiben

## Phase 5: Historie und Analyse

Ziel: Nutzer erkennt Entwicklung über die Zeit.

### User Story 5.1: Trainingshistorie anzeigen

**Als Nutzer** möchte ich abgeschlossene Sessions sehen, **damit** ich frühere Einheiten nachvollziehen kann.

**Akzeptanzkriterien:**

- Sessions sind chronologisch sortiert.
- Sessiondetails können geöffnet werden.
- Notizen sind sichtbar.

### User Story 5.2: Übungsfortschritt anzeigen

**Als Nutzer** möchte ich den Fortschritt je Übung sehen, **damit** ich Progression bewerten kann.

**Akzeptanzkriterien:**

- Gewichtsentwicklung wird angezeigt.
- Volumenentwicklung wird angezeigt.
- Schmerzverlauf wird angezeigt.
- RIR-Verlauf wird angezeigt.

### To-dos

- HistoryView bauen
- SessionHistoryDetailView bauen
- AnalyticsView bauen
- ExerciseProgressView bauen
- Swift Charts integrieren
- Datenaggregationen implementieren
- Tests für Aggregationen schreiben

## Phase 6: Export und Einstellungen

Ziel: Daten können gesichert und weiterverwendet werden.

### User Story 6.1: Session exportieren

**Als Nutzer** möchte ich eine Session exportieren, **damit** ich sie dokumentieren oder teilen kann.

**Akzeptanzkriterien:**

- Markdown-Export möglich.
- CSV-Export möglich.
- Export enthält Plan- und Ist-Werte.

### To-dos

- ExportService implementieren
- MarkdownFormatter bauen
- CSVFormatter bauen
- ShareSheet anbinden
- Datenschutzseite erstellen
- App-Einstellungen erstellen

## 2. MVP-Epics

| Epic | Priorität | Beschreibung |
|---|---|---|
| EPIC-01 Projektsetup | Hoch | Grundstruktur und Architektur |
| EPIC-02 Planmodell | Hoch | Datenmodell und Seed-Plan |
| EPIC-03 Plananzeige | Hoch | Wochen und Tage anzeigen |
| EPIC-04 Session Tracking | Sehr hoch | Kernfunktion der App |
| EPIC-05 Auswertung | Hoch | Session Summary, RIR, Schmerz, Volumen |
| EPIC-06 Historie | Mittel | Vergangene Sessions |
| EPIC-07 Analyse | Mittel | Charts und Trends |
| EPIC-08 Export | Mittel | Markdown/CSV Export |
| EPIC-09 HealthKit | Niedrig | später optional |

## 3. Priorisierte MVP-Liste

1. Datenmodell
2. Seed-Import des Plans
3. Plananzeige
4. Session starten
5. Satzdaten loggen
6. Session abschließen
7. Zusammenfassung
8. Historie
9. Analyse-Basis
10. Export

## 4. Definition of Ready für User Stories

Eine User Story ist bereit, wenn:

- Zielgruppe klar ist
- Nutzen formuliert ist
- Akzeptanzkriterien vorhanden sind
- betroffene Entitäten bekannt sind
- UI-Screen grob bekannt ist
- Testidee vorhanden ist

## 5. Definition of Done

Eine Story ist erledigt, wenn:

- Funktion implementiert ist
- Unit Tests vorhanden sind
- Fehlerfälle behandelt sind
- UI im Light und Dark Mode nutzbar ist
- keine offensichtlichen Accessibility-Probleme bestehen
- Daten persistiert werden
- Code reviewed/refaktoriert ist
