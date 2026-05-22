# GymTracker – Weitere Codex-Prompts

Diese Datei enthält die nächsten sinnvollen Prompts für die Weiterentwicklung von **GymTracker**.

Ziel der Prompt-Kette:
- GymTracker von einer planbasierten Demo-App zu einer allgemeinen Gym-Tracking-App weiterentwickeln
- Christian B1 nur noch als Demo-/Seed-Datensatz verwenden
- generische Trainingspläne, Sessions, Übungen und Sätze ermöglichen
- App technisch stabilisieren
- Tests, Import/Export und MVP-Readiness verbessern

---

## Prompt 1: Analyse der aktuellen Kopplung an Christian B1

```markdown
Analysiere das gesamte GymTracker-Projekt darauf, wo die App noch fest oder indirekt an den Trainingsplan „Christian B1“ gekoppelt ist.

Ziel:
GymTracker soll eine allgemeine Gym-Tracking-App werden. Der Plan „Christian B1“ darf nur noch Demo-/Seed-Daten sein.

Bitte prüfe insbesondere:
- hardcodierte Plan-Namen
- feste Wochenanzahlen
- feste Session-Strukturen
- feste Übungen
- UI-Texte mit Bezug auf Christian B1
- Tests, die nur mit Christian B1 funktionieren
- Seed-Daten, die mit App-Logik vermischt sind
- Datenmodell-Annahmen aus dem konkreten Plan
- Dashboard- oder Progressionslogik, die auf den Demo-Plan zugeschnitten ist

Erstelle:
1. Eine Liste aller gefundenen Kopplungen
2. Betroffene Dateien und Klassen
3. Risiko je Kopplung
4. Einen priorisierten Refactoring-Plan
5. Noch keine Code-Änderungen
```

---

## Prompt 2: Datenmodell generisch machen

```markdown
Überarbeite das Datenmodell von GymTracker so, dass es vollständig generisch für beliebige Trainingspläne funktioniert.

Ziel:
Der Trainingsplan „Christian B1“ darf nicht mehr strukturell vorausgesetzt werden. Alle Werte müssen aus den jeweiligen Trainingsplandaten kommen.

Bitte implementiere oder prüfe generische Modelle für:
- TrainingPlan
- TrainingWeek
- TrainingSession
- Exercise
- PlannedSet
- CompletedSession
- CompletedExercise
- CompletedSet

Wichtig:
- Keine feste Annahme zu 6 Wochen
- Keine feste Annahme zu 3 Trainingstagen pro Woche
- Keine feste Annahme zu bestimmten Übungen
- Keine feste Annahme zu bestimmten RIR- oder Schmerz-Werten
- Stabile IDs für alle Entitäten
- klare Trennung zwischen geplanten Daten und tatsächlich getrackten Daten

Bitte liefere:
1. Code-Anpassungen am Datenmodell
2. notwendige Migrationen oder Hinweise zu SwiftData
3. Anpassung betroffener Services
4. Unit Tests für das generische Datenmodell
5. kurze technische Dokumentation
```

---

## Prompt 3: Demo-Daten sauber auslagern

```markdown
Lagere den bisherigen Trainingsplan „Christian B1“ in GymTracker sauber als Demo-/Seed-Daten aus.

Ziel:
Der Demo-Plan ist nur ein Beispieldatensatz und keine fachliche Grundlage der App.

Bitte implementiere:
- DemoDataService
- klare Kennzeichnung von Demo-Plänen
- Laden des Demo-Plans auf Wunsch
- Löschen des Demo-Plans
- Duplizieren des Demo-Plans als bearbeitbarer eigener Plan
- keine automatische Pflichtabhängigkeit vom Demo-Plan
- keine Demo-Plan-Logik in Views, ViewModels oder Domain-Services

Bitte stelle sicher:
- Die App startet auch ohne Demo-Plan.
- Der Demo-Plan wird nur geladen, wenn der Nutzer dies auswählt.
- Der Demo-Plan kann als Vorlage genutzt, aber anschließend vollständig bearbeitet werden.
- Tests und Previews verwenden eigene Testdaten und nicht zwingend den Demo-Plan.

Bitte liefere:
1. Code-Änderungen
2. Tests
3. aktualisierte Preview-Daten
4. kurze Dokumentation der Demo-Daten-Strategie
```

---

## Prompt 4: Empty State und Planübersicht

```markdown
Überarbeite den App-Start und die Planübersicht von GymTracker.

Ziel:
Die App soll wie eine allgemeine Gym-Tracking-App starten und nicht voraussetzen, dass bereits ein Trainingsplan existiert.

Bitte implementiere folgende Zustände:

## Kein Trainingsplan vorhanden
Zeige einen Empty State mit drei Optionen:
- Neuen Trainingsplan erstellen
- Demo-Plan laden
- Trainingsplan importieren

## Trainingspläne vorhanden
Zeige eine Planübersicht mit:
- aktive Pläne
- Entwürfe
- archivierte Pläne
- Demo-Pläne klar gekennzeichnet

## Planaktionen
Der Nutzer soll:
- Plan öffnen
- Plan duplizieren
- Plan archivieren
- Plan löschen
- Demo-Plan laden
- neuen Plan erstellen können

Bitte achte auf:
- moderne SwiftUI-UX
- klare Empty-State-Texte
- keine Christian-B1-spezifischen UI-Texte
- saubere Navigation

Bitte liefere:
1. angepasste Views
2. ViewModel-Logik
3. Tests für Empty State und Planübersicht
4. SwiftUI Previews
```

---

## Prompt 5: Trainingsplan-Editor

```markdown
Implementiere einen vollständigen generischen Trainingsplan-Editor für GymTracker.

Ziel:
Der Nutzer soll alle Inhalte eines Trainingsplans individuell erstellen, bearbeiten, löschen, duplizieren und verschieben können.

Bitte implementiere Funktionen für:

## Trainingsplan
- Name bearbeiten
- Beschreibung bearbeiten
- Ziel bearbeiten
- Startdatum optional setzen
- Status setzen: Entwurf, aktiv, archiviert
- Plan duplizieren
- Plan löschen

## Trainingswochen
- Woche hinzufügen
- Woche bearbeiten
- Woche löschen
- Woche duplizieren
- Reihenfolge ändern
- Wochenfokus bearbeiten

## Sessions
- Session hinzufügen
- Session bearbeiten
- Session löschen
- Session duplizieren
- Reihenfolge ändern
- Session-Fokus bearbeiten
- geplante Dauer bearbeiten
- Notizen bearbeiten

## Übungen
- Übung hinzufügen
- Übung bearbeiten
- Übung löschen
- Übung duplizieren
- Reihenfolge ändern
- Übungsname bearbeiten
- Muskelgruppe bearbeiten
- Equipment bearbeiten
- Cueing bearbeiten
- Tempo bearbeiten
- Ziel-RIR bearbeiten
- Schmerz-Ziel bearbeiten
- Notizen bearbeiten

## Sätze
- Satz hinzufügen
- Satz bearbeiten
- Satz löschen
- Satz duplizieren
- geplante Wiederholungen bearbeiten
- geplantes Gewicht optional bearbeiten
- Ziel-RIR bearbeiten
- Pause bearbeiten
- Tempo bearbeiten
- Satztyp bearbeiten

Bitte liefere:
1. UI-Flows
2. SwiftUI-Formulare
3. Validierungslogik
4. ViewModels
5. Tests
6. Akzeptanzkriterien
```

---

## Prompt 6: Import, Export, Tests und finaler Review

```markdown
Stabilisiere GymTracker nach der Umstellung auf eine allgemeine Gym-Tracking-App.

Ziel:
Die App soll mit beliebigen Trainingsplänen funktionieren und nicht mehr vom Demo-Plan abhängig sein.

Bitte prüfe und implementiere:

## Import
- JSON-Import für beliebige Trainingspläne
- Validierung der Struktur
- Import-Vorschau
- Fehleranzeige bei ungültigen Daten
- keine Annahme, dass der Plan Christian B1 ist

## Export
- Export eines beliebigen Plans
- Export absolvierter Sessions
- JSON-Export
- CSV-Export
- optional Markdown-Zusammenfassung

## Tests
Ergänze Tests für:
- App startet ohne Trainingsplan
- neuer Plan kann erstellt werden
- Plan kann bearbeitet werden
- Woche kann hinzugefügt werden
- Session kann hinzugefügt werden
- Übung kann hinzugefügt werden
- Satz kann hinzugefügt werden
- Demo-Plan kann geladen werden
- Demo-Plan kann gelöscht werden
- Demo-Plan kann dupliziert werden
- Import beliebiger Trainingspläne funktioniert
- Export beliebiger Trainingspläne funktioniert
- Live-Session funktioniert mit selbst erstelltem Plan
- Dashboard funktioniert mit selbst erstellten Daten

## Finaler Review
Prüfe:
- keine hardcodierten Christian-B1-Abhängigkeiten
- App-Name überall GymTracker
- Build erfolgreich
- Tests erfolgreich
- UI ohne Platzhaltertexte
- Empty States vorhanden
- Error Handling vorhanden

Bitte liefere:
1. Code-Änderungen
2. Test-Ergebnisse
3. Liste gefundener und behobener Probleme
4. verbleibende Risiken
5. finale MVP-Checkliste
```

---

## Zusatzprompt nach jedem Umsetzungsschritt

```markdown
Bitte führe nach den Änderungen einen vollständigen Build und alle vorhandenen Tests aus. Behebe auftretende Fehler, ohne neue Features zu ergänzen.
```

---

## Empfohlene Reihenfolge

1. Analyse ohne Code-Änderung
2. Datenmodell generisch machen
3. Demo-Daten auslagern
4. App-Start und Planübersicht umbauen
5. Trainingsplan-Editor bauen
6. Import/Export, Tests und finaler Review

Nach jedem Prompt sollte die App gebaut und getestet werden, bevor der nächste Schritt umgesetzt wird.
