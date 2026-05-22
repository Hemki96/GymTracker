# Codex-Implementierungs-Prompts

Diese Prompts sind so formuliert, dass sie nacheinander in Codex oder einem Coding-Agenten verwendet werden können. Jeder Prompt sollte zu einem eigenständigen, überprüfbaren Ergebnis führen.

## Prompt 1: Projektstruktur erstellen

```text
Du bist ein professioneller iOS-Entwickler. Erstelle eine native SwiftUI-App namens GymTracker mit sauberer Projektstruktur.

Anforderungen:
- SwiftUI App Lifecycle
- Ordner: App, Domain, Data, Features, DesignSystem, Tests
- MVVM-Struktur vorbereiten
- SwiftData vorbereiten, aber noch ohne komplexe Models
- leeres Dashboard als Startscreen
- README mit Build- und Testanleitung
- keine Businesslogik in SwiftUI Views
- alle neuen Dateien sinnvoll benennen

Erstelle zusätzlich eine kurze Architekturentscheidung als ADR.
```

## Prompt 2: Domain-Modelle implementieren

```text
Implementiere das Domain- und Persistenzmodell für GymTracker.

Entitäten:
- TrainingBlock
- TrainingWeek
- WorkoutPlan
- Exercise
- PlannedExercise
- SessionLog
- ExerciseLog
- SetLog

Anforderungen:
- SwiftData @Model verwenden
- UUID IDs
- createdAt/updatedAt dort, wo sinnvoll
- Planwerte und Ist-Werte strikt trennen
- Gewicht und Wiederholungen als Plantext speichern können
- Ist-Gewicht und Ist-Wiederholungen strukturiert speichern
- Enums für Statuswerte anlegen
- Unit Tests für Initialisierung und Beziehungen schreiben
```

## Prompt 3: Seed-Daten aus Trainingsplan anlegen

```text
Lege Seed-Daten für den Trainingsplan „Christian Hemker B1“ an.

Struktur:
- 6 Wochen
- 3 Trainingstage pro Woche
- Übungen und Planwerte aus der Dokumentation übernehmen
- Felder: Übung, Cueing, Tempo, Sätze, Wiederholungen, Gewicht, Ziel RIR, Schmerz Ziel, Notizen

Anforderungen:
- SeedDataService implementieren
- Daten nur einmal importieren
- Validierung: 6 Wochen, 18 Sessions, 108 Übungszeilen
- Unit Tests für den Import
- Seed-Daten als JSON oder Swift Fixture, klar wartbar
```

## Prompt 4: Plananzeige bauen

```text
Implementiere die Plananzeige.

Screens:
- PlanView
- WeekSelector
- WorkoutDayCard
- WorkoutDetailView
- ExercisePlanRow

Anforderungen:
- Wochen 1 bis 6 anzeigen
- pro Woche Tag 1 bis Tag 3 anzeigen
- Workout Details mit allen Übungen anzeigen
- Cueing, Tempo, Sätze, Wiederholungen, Gewicht, Ziel-RIR und Schmerz-Ziel sichtbar machen
- Status geplante/abgeschlossene Einheit anzeigen
- SwiftUI Previews mit Seed-Daten
```

## Prompt 5: Session starten

```text
Implementiere den Flow zum Starten einer Session.

Anforderungen:
- Aus WorkoutPlan wird SessionLog erzeugt
- PlannedExercise wird zu ExerciseLog
- geplante Sätze werden als SetLog vorbereitet
- SessionStatus active setzen
- Startzeit speichern
- aktive Session beim App-Neustart wiederfinden
- verhindern, dass zwei aktive Sessions gleichzeitig entstehen
- Unit Tests für Session-Erstellung
```

## Prompt 6: Aktive Session UI

```text
Implementiere die aktive Trainingssession.

Screens/Components:
- ActiveSessionView
- ExerciseTrackingView
- SetLogRow
- RIRPicker
- PainPicker
- ExerciseHeaderCard

Anforderungen:
- aktuelle Übung prominent anzeigen
- Planwerte anzeigen
- Satzdaten editierbar machen: Gewicht, Reps, RIR, Schmerz, Notiz
- Satz als erledigt markieren
- Satz hinzufügen/löschen
- nächste/vorherige Übung
- Auto-Save nach jeder Änderung
- große Touch-Ziele und Dark-Mode-taugliches Layout
```

## Prompt 7: Schmerz- und RIR-Logik

```text
Implementiere die Auswertungslogik für Schmerz und RIR.

Services:
- PainThresholdEvaluator
- RIRAnalyzer
- VolumeCalculator

Anforderungen:
- parse „max 3/10“
- parse RIR Bereiche wie „2-3“ und „3-4“
- Sonderfall „7RPE“ als Textstatus behandeln
- bei Schmerzüberschreitung Warnstatus liefern
- bei RIR außerhalb Zielbereich Status liefern
- vollständige Unit Tests mit Grenzfällen
```

## Prompt 8: Session abschließen und Zusammenfassung

```text
Implementiere Session-Abschluss und Zusammenfassung.

Anforderungen:
- Abschlusszeit speichern
- Dauer berechnen
- Gesamtvolumen berechnen
- durchschnittlichen RIR berechnen
- maximalen Schmerz berechnen
- Warnungen sammeln
- SessionSummaryView bauen
- Nutzer kann Session-Notiz erfassen
- abgeschlossene Session erscheint in Historie
```

## Prompt 9: Historie und Übungsdetails

```text
Implementiere Historie und Übungsdetails.

Screens:
- HistoryView
- SessionHistoryDetailView
- ExerciseProgressView

Anforderungen:
- abgeschlossene Sessions chronologisch anzeigen
- Sessiondetails vollständig öffnen
- Übungshistorie anzeigen
- letzte Werte und Notizen anzeigen
- Bestwerte und Verlauf pro Übung berechnen
```

## Prompt 10: Analyse mit Swift Charts

```text
Implementiere die Analyseansicht mit Swift Charts.

Charts:
- Wochenvolumen
- Schmerzverlauf
- RIR-Verlauf
- Gewichtsentwicklung pro Übung

Anforderungen:
- AnalyticsView
- ExerciseFilter
- ChartDataMapper
- leere Zustände sinnvoll anzeigen
- Werte aus gespeicherten SessionLogs berechnen
- Unit Tests für Aggregationen
```

## Prompt 11: Export

```text
Implementiere Markdown- und CSV-Export.

Anforderungen:
- Export einer Session als Markdown
- Export eines gesamten Blocks als CSV
- Planwerte und Ist-Werte enthalten
- Share Sheet verwenden
- Dateinamen mit Datum und Blockname
- Unit Tests für Exportformat
```

## Prompt 12: App polish und QA

```text
Führe ein umfassendes Refactoring und QA-Polishing durch.

Prüfe:
- keine Businesslogik in Views
- ViewModels testbar
- Domain Services getestet
- Dark Mode
- Dynamic Type
- Accessibility Labels
- leere Zustände
- Fehlerfälle
- aktive Session Recovery
- Seed-Datenvalidierung
- Exportvalidierung

Erstelle eine finale technische README mit Architektur, Setup, Tests und bekannten Einschränkungen.
```
