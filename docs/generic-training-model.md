# Generisches Trainingsmodell

GymTracker behandelt den bisherigen Plan "Christian B1" nur als Seed-Datensatz. Das Datenmodell darf keine fixe Anzahl von Wochen, Trainingstagen, Uebungen, Saetzen, RIR-Zielen oder Schmerzgrenzen voraussetzen.

## Modell

- `TrainingPlan` ist der fachliche Alias fuer `TrainingBlock` und enthaelt beliebig viele `TrainingWeek`-Eintraege.
- `TrainingWeek` enthaelt beliebig viele geplante `TrainingSession`-Eintraege. Persistiert ist dieser Typ weiterhin als `WorkoutPlan`, damit bestehende SwiftData-Daten nicht durch ein reines Rename verloren gehen.
- `Exercise` ist Stammdaten-/Bibliotheksobjekt und nicht an einen bestimmten Plan gebunden.
- `PlannedExercise` verbindet eine `Exercise` mit einer geplanten Session und enthaelt uebungsweite Plantexte.
- `PlannedSet` ist die satzgenaue geplante Quelle fuer Wiederholungen, Gewicht, RIR-Ziel, Schmerz-Ziel, Warmup-Flag und Notizen.
- `CompletedSession`, `CompletedExercise` und `CompletedSet` sind fachliche Aliase fuer `SessionLog`, `ExerciseLog` und `SetLog`.

Alle persistierten Entitaeten besitzen stabile `UUID`-IDs. Geplante Daten bleiben in `TrainingPlan`/`TrainingWeek`/`TrainingSession`/`PlannedExercise`/`PlannedSet`; getrackte Daten bleiben in `CompletedSession`/`CompletedExercise`/`CompletedSet`. `CompletedSet.plannedSet` referenziert optional den geplanten Satz, speichert aber die tatsaechlichen Werte separat.

## Services

- `SeedDataService` importiert beliebige wohlgeformte Fixtures und erzeugt `PlannedSet`-Eintraege aus den jeweiligen Planwerten.
- `SessionStartService` erzeugt Set-Entwuerfe bevorzugt aus `PlannedSet`. Nur alte Plaene ohne `PlannedSet` fallen auf `setsPrescription`/`repsPrescription` zurueck.
- `SessionCompletionService` bewertet RIR- und Schmerz-Ziele satzgenau, wenn `PlannedSet`-Targets vorhanden sind.
- `TrainingExportService` exportiert ungetrackte Sessions satzgenau aus `PlannedSet` und getrackte Sessions aus den `CompletedSet`-Daten.

## SwiftData-Migration

Diese Aenderung fuegt mit `PlannedSet` ein neues optional angebundenes SwiftData-Modell und `CompletedSet.plannedSet` als optionale Beziehung hinzu. Die bestehenden persistierten Typnamen bleiben erhalten; die neuen Fachnamen sind Swift-Typaliasse. Dadurch wird ein destruktives Rename von `TrainingBlock`, `WorkoutPlan`, `SessionLog`, `ExerciseLog` und `SetLog` vermieden.

Fuer produktive Bestandsdaten sollte beim naechsten expliziten Schema-Upgrade eine leichte Migration vorhandene `PlannedExercise`-Eintraege ohne `plannedSets` backfillen. Die Backfill-Logik entspricht dem aktuellen Fallback: Satzanzahl aus `setsPrescription`, Satzwerte aus `repsPrescription`, `plannedWeightText`, `targetRIRText` und `painTargetText`.
