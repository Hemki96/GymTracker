# Analyse der Excel-Vorlage

## 1. Verwendete Vorlage

Datei: `Trainingsplan Christian Hemker B1.xlsx`

Erkannte Arbeitsblätter:

| Sheet | Inhalt |
| --- | --- |
| Woche 1 | Trainingswoche mit 3 Trainingstagen |
| Woche 2 | Trainingswoche mit 3 Trainingstagen |
| Woche 3 | Trainingswoche mit 3 Trainingstagen |
| Woche 4 | Trainingswoche mit 3 Trainingstagen |
| Woche 5 | Trainingswoche mit 3 Trainingstagen |
| Woche 6 | Trainingswoche mit 3 Trainingstagen |

## 2. Erkannte Metadaten

| Feld | Wert |
|---|---|
| Name | Christian Hemker |
| Block | Wettkampfvorbereitung bis 20.06.2026 |
| Ziel | Belastbarkeitsaufbau Knie + Kraftsteigerung |
| Umfang | 6 Wochen |
| Trainingstage pro Woche | 3 |
| Geplante Sessions | 18 |
| Geplante Übungszeilen | 108 |

Hinweis: In Woche 6 steht in der Vorlage „Wettkampfvorbereitung 1/2 bis ca 31.05.2026“. Die App sollte solche Abweichungen nicht automatisch korrigieren, sondern als Planmetadaten übernehmen und optional als Hinweis anzeigen.

## 3. Struktur der Vorlage

Die Vorlage ist nicht nur eine Übungsliste, sondern ein periodisierter Plan mit wiederkehrenden Trainingstagen. Jede Woche enthält drei Tage, und jeder Tag enthält sechs Übungen.

| Feld | App-Bedeutung | Beschreibung |
| --- | --- | --- |
| Woche | Plan-Periodisierung | Nummer/Label der Trainingswoche; in der Vorlage 1–6. |
| Tag | Trainingseinheit | Trainingstag innerhalb der Woche; in der Vorlage Tag 1, Tag 2, Tag 3. |
| Übung | Exercise-Stammdaten | Name der Übung, z. B. Kniebeugen, Trapbar-Kreuzheben, Latziehen. |
| Cueing | Technik-Hinweis | Individueller Fokus während der Übung, z. B. Fußdruck, Kniekontrolle, Explosivität. |
| Tempo | Ausführungsstandard | Bewegungsgeschwindigkeit und Pausenhinweise, z. B. kontrolliert langsam mit Pause. |
| Sätze | Planvorgabe | Geplante Anzahl Sätze. |
| Wiederholungen | Planvorgabe | Geplante Wiederholungen oder Zeit-/AMRAP-/ALAP-Vorgabe. |
| Gewicht | Planvorgabe / Logwert | Geplantes oder verwendetes Gewicht; auch komplexe Angaben wie 3x90/2x80 möglich. |
| Ziel RIR | Intensitätssteuerung | Geplante Reps in Reserve, z. B. 2–3, 3–4 oder RPE-ähnliche Vorgabe. |
| Ist RIR | Session-Logging | Nach jedem Satz bzw. nach der Übung erfasste tatsächliche Anstrengung. |
| Schmerz Ziel | Belastungssteuerung/Reha | Maximal zulässige Schmerzintensität, z. B. max 3/10. |
| Tatsächlicher Schmerz | Session-Logging | Subjektive Schmerzbewertung während/nach der Übung. |
| Notizen | Freitext | Kontext, Anpassungen, Techniknotizen, Abweichungen oder Feedback. |

## 4. Übungsbibliothek aus der Vorlage

| Nr. | Übung |
| --- | --- |
| 1 | Ab Wheel |
| 2 | Beinbeuger |
| 3 | Beinstrecker |
| 4 | Bulgarian Split Squats |
| 5 | Hollow Body Hold |
| 6 | Hyperextensions mit Glute Fokus |
| 7 | Klimmzüge (mit Zusatzgewicht) |
| 8 | Kniebeugen |
| 9 | Kreuzheben mit Trapbar |
| 10 | Kurzhantel über Kopf drücken, stehend |
| 11 | Latziehen |
| 12 | Lu Raises |
| 13 | Pallof Rotations |
| 14 | Rudern mit V-Griff |
| 15 | Superman Hold |
| 16 | Überzüge mit Kurzhantel |

## 5. App-Implikationen aus der Vorlage

### 5.1 Der Plan ist wochenbasiert

Die App benötigt eine Hierarchie:

```text
TrainingBlock
└── TrainingWeek
    └── WorkoutDay
        └── PlannedExercise
            └── PlannedSet / LoggedSet
```

### 5.2 Das Logging muss Plan- und Ist-Werte trennen

Beispiel:

- Plan: Kniebeugen, 5x5, 80 kg, Ziel-RIR 2–3, Schmerz max 3/10
- Ist: Satz 1: 80 kg x 5, RIR 3, Schmerz 1/10
- Ist: Satz 2: 80 kg x 5, RIR 2, Schmerz 2/10

Dadurch bleibt nachvollziehbar, ob die Vorgabe erfüllt wurde.

### 5.3 Gewicht ist nicht immer rein numerisch

Die Spalte `Gewicht` enthält Werte wie:

- `80`
- `5/5`
- `3x90/2x80`
- `-`
- leere Werte

Die App sollte daher zwei Felder unterscheiden:

| Feld | Zweck |
|---|---|
| `plannedWeightText` | Originalangabe aus dem Plan |
| `loggedWeightKg` | konkrete numerische Eingabe beim Tracking |

### 5.4 Wiederholungen sind nicht immer numerisch

Die Vorlage enthält:

- feste Wiederholungen, z. B. `5`
- Bereiche, z. B. `6-10`
- AMRAP
- ALAP

Daher sollte die App Wiederholungen als strukturierte Vorgabe modellieren:

```swift
enum RepPrescription {
    case fixed(Int)
    case range(min: Int, max: Int)
    case amrap
    case alap
    case text(String)
}
```

### 5.5 Schmerztracking ist zentral

Da bei mehreren Beinübungen `max 3/10` hinterlegt ist, braucht die App:

- sichtbares Schmerz-Ziel pro Übung
- Eingabe für tatsächlichen Schmerz
- Warnung bei Überschreitung
- Verlauf je Übung und Woche
- Session-Zusammenfassung mit Schmerzmaxima

## 6. Vollständig erkannter Trainingsplan

### Woche 1

| Tag | Übung | Cueing | Tempo | Sätze | Wdh. | Gewicht | Ziel RIR | Schmerz Ziel | Notizen |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Tag 1 | Kniebeugen | Auf Druck unter den Fußsohlen achten | kontrolliert langsam mit Pause | 5 | 5 | 80 | 2-3 | max 3/10 | Barfuß |
| Tag 1 | Bulgarian Split Squats | Auf Druck unter den Fußsohlen achten | kontrolliert langsam | 3 | 6-10 | 10 | 3-4 | max 3/10 | Barfuß |
| Tag 1 | Latziehen |  | explosiv hoch | 5 | 5 | 50 | 3-4 |  |  |
| Tag 1 | Lu Raises |  |  | 3 | 6-10 | 5/5 | 3-4 |  |  |
| Tag 1 | Ab Wheel |  |  | 3 | AMRAP | - | 3-4 |  |  |
| Tag 1 | Hyperextensions mit Glute Fokus |  |  | 3 | 6-10 | 8 | 3-4 |  |  |
| Tag 2 | Kreuzheben mit Trapbar |  | etwas explosiv vom Boden, wenn das Knie es erlaubt | 5 | 5 | 80 | 3-4 | max 3/10 |  |
| Tag 2 | Rudern mit V-Griff |  |  | 3 | 6-8 | 40 | 3-4 |  |  |
| Tag 2 | Überzüge mit Kurzhantel |  |  | 3 | 6-8 | 18 | 3-4 |  |  |
| Tag 2 | Pallof Rotations |  |  | 4 | 8-12 |  | 2-3 |  |  |
| Tag 2 | Beinbeuger |  |  | 4 | 8-12 | 60 | 2-3 |  |  |
| Tag 2 | Beinstrecker |  |  | 4 | 8-12 |  | 2-3 | max 3/10 |  |
| Tag 3 | Kniebeugen | Auf Druck unter den Fußsohlen achten | kontrolliert langsam mit Pause | 5 | 5 |  | 2-3 | max 3/10 |  |
| Tag 3 | Bulgarian Split Squats | Auf Druck unter den Fußsohlen achten | kontrolliert langsam | 3 | 6-10 |  | 3 | max 3/10 |  |
| Tag 3 | Klimmzüge (mit Zusatzgewicht) |  |  | 3 | 5 |  | 3-4 |  |  |
| Tag 3 | Kurzhantel über Kopf drücken, stehend |  |  | 3 | 6-8 |  | 3-4 |  |  |
| Tag 3 | Hollow Body Hold |  |  | 3 | ALAP |  | 7RPE |  |  |
| Tag 3 | Superman Hold |  |  | 3 | ALAP |  | 7RPE |  |  |

### Woche 2

| Tag | Übung | Cueing | Tempo | Sätze | Wdh. | Gewicht | Ziel RIR | Schmerz Ziel | Notizen |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Tag 1 | Kniebeugen | Auf Druck unter den Fußsohlen achten | kontrolliert langsam mit Pause | 5 | 4 | 3x90/2x80 | 2-3 | max 3/10 | Barfuß |
| Tag 1 | Bulgarian Split Squats | Auf Druck unter den Fußsohlen achten | kontrolliert langsam | 3 | 6-10 | 10 | 3-4 | max 3/10 | Barfuß |
| Tag 1 | Latziehen |  | explosiv hoch | 5 | 3 | 55 | 3-4 |  |  |
| Tag 1 | Lu Raises |  |  | 3 | 6-10 | 5/5 | 3-4 |  |  |
| Tag 1 | Ab Wheel |  |  | 3 | AMRAP | 8/ | 3-4 |  |  |
| Tag 1 | Hyperextensions mit Glute Fokus |  |  | 3 | 6-10 |  | 3-4 |  |  |
| Tag 2 | Kreuzheben mit Trapbar |  | etwas explosiv vom Boden, wenn das Knie es erlaubt | 5 | 4 | 70 | 3-4 | max 3/10 |  |
| Tag 2 | Rudern mit V-Griff |  |  | 3 | 6-8 | 40 | 3-4 |  |  |
| Tag 2 | Überzüge mit Kurzhantel |  |  | 3 | 6-8 | 18 | 3-4 |  |  |
| Tag 2 | Pallof Rotations |  |  | 4 | 8-12 |  | 2-3 |  |  |
| Tag 2 | Beinbeuger |  |  | 4 | 8-12 | 65 | 2-3 |  |  |
| Tag 2 | Beinstrecker |  |  | 4 | 8-12 |  | 2-3 | max 3/10 |  |
| Tag 3 | Kniebeugen | Auf Druck unter den Fußsohlen achten | kontrolliert langsam mit Pause | 5 | 4 | 80 | 2-3 | max 3/10 |  |
| Tag 3 | Bulgarian Split Squats | Auf Druck unter den Fußsohlen achten | kontrolliert langsam | 3 | 6-10 |  | 3 | max 3/10 |  |
| Tag 3 | Klimmzüge (mit Zusatzgewicht) |  | explosiv hoch | 3 | 5 | 5 | 3-4 |  | Nur 3 Wiederholungen mit dem Gewicht |
| Tag 3 | Kurzhantel über Kopf drücken, stehend |  |  | 3 | 6-8 | 12 | 3-4 |  |  |
| Tag 3 | Hollow Body Hold |  |  | 3 | ALAP |  | 7RPE |  |  |
| Tag 3 | Superman Hold |  |  | 3 | ALAP |  | 7RPE |  |  |

### Woche 3

| Tag | Übung | Cueing | Tempo | Sätze | Wdh. | Gewicht | Ziel RIR | Schmerz Ziel | Notizen |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Tag 1 | Kniebeugen | Auf Druck unter den Fußsohlen achten | kontrolliert langsam mit Pause | 5 | 3 | 100 | 2-3 | max 3/10 | Barfuß |
| Tag 1 | Bulgarian Split Squats | Auf Druck unter den Fußsohlen achten | kontrolliert langsam | 3 | 6-10 | 12 | 3-4 | max 3/10 | Barfuß |
| Tag 1 | Latziehen |  | explosiv hoch | 5 | 1 | 60 | 3-4 |  |  |
| Tag 1 | Lu Raises |  |  | 3 | 6-10 | 5/5 | 3-4 |  |  |
| Tag 1 | Ab Wheel |  |  | 3 | AMRAP |  | 3-4 |  |  |
| Tag 1 | Hyperextensions mit Glute Fokus |  |  | 3 | 6-10 |  | 3-4 |  |  |
| Tag 2 | Kreuzheben mit Trapbar |  | etwas explosiv vom Boden, wenn das Knie es erlaubt | 5 | 3 | 80 | 3-4 | max 3/10 |  |
| Tag 2 | Rudern mit V-Griff |  |  | 3 | 6-8 | 40 | 3-4 |  |  |
| Tag 2 | Überzüge mit Kurzhantel |  |  | 3 | 6-8 | 18 | 3-4 |  |  |
| Tag 2 | Pallof Rotations |  |  | 4 | 8-12 |  | 2-3 |  |  |
| Tag 2 | Beinbeuger |  |  | 4 | 8-12 |  | 2-3 |  |  |
| Tag 2 | Beinstrecker |  |  | 4 | 8-12 | 35 | 2-3 | max 3/10 |  |
| Tag 3 | Kniebeugen | Auf Druck unter den Fußsohlen achten | kontrolliert langsam mit Pause | 5 | 3 |  | 2-3 | max 3/10 |  |
| Tag 3 | Bulgarian Split Squats | Auf Druck unter den Fußsohlen achten | kontrolliert langsam | 3 | 6-10 |  | 3 | max 3/10 |  |
| Tag 3 | Klimmzüge (mit Zusatzgewicht) |  | explosiv hoch | 3 | 5 |  | 3-4 |  |  |
| Tag 3 | Kurzhantel über Kopf drücken, stehend |  |  | 3 | 6-8 |  | 3-4 |  |  |
| Tag 3 | Hollow Body Hold |  |  | 3 | ALAP |  | 7RPE |  |  |
| Tag 3 | Superman Hold |  |  | 3 | ALAP |  | 7RPE |  |  |

### Woche 4

| Tag | Übung | Cueing | Tempo | Sätze | Wdh. | Gewicht | Ziel RIR | Schmerz Ziel | Notizen |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Tag 1 | Kniebeugen | Auf Druck unter den Fußsohlen achten | kontrolliert langsam mit Pause | 5 | 5 |  | 2-3 | max 3/10 | Barfuß |
| Tag 1 | Bulgarian Split Squats | Auf Druck unter den Fußsohlen achten | kontrolliert langsam | 3 | 6-10 |  | 3-4 | max 3/10 | Barfuß |
| Tag 1 | Latziehen |  | explosiv hoch | 5 | 5 |  | 3-4 |  |  |
| Tag 1 | Lu Raises |  |  | 4 | 6-10 |  | 3-4 |  |  |
| Tag 1 | Ab Wheel |  |  | 3 | AMRAP |  | 3-4 |  |  |
| Tag 1 | Hyperextensions mit Glute Fokus |  |  | 3 | 6-10 |  | 3-4 |  |  |
| Tag 2 | Kreuzheben mit Trapbar |  | etwas explosiv vom Boden, wenn das Knie es erlaubt | 5 | 5 |  | 3-4 | max 3/10 |  |
| Tag 2 | Rudern mit V-Griff |  |  | 3 | 6-8 |  | 3-4 |  |  |
| Tag 2 | Überzüge mit Kurzhantel |  |  | 3 | 6-8 |  | 3-4 |  |  |
| Tag 2 | Pallof Rotations |  |  | 4 | 8-12 |  | 2-3 |  |  |
| Tag 2 | Beinbeuger |  |  | 4 | 8-12 |  | 2-3 |  |  |
| Tag 2 | Beinstrecker |  |  | 4 | 8-12 |  | 2-3 | max 3/10 |  |
| Tag 3 | Kniebeugen | Auf Druck unter den Fußsohlen achten | kontrolliert langsam mit Pause | 5 | 5 |  | 2-3 | max 3/10 |  |
| Tag 3 | Bulgarian Split Squats | Auf Druck unter den Fußsohlen achten | kontrolliert langsam | 3 | 6-10 |  | 3 | max 3/10 |  |
| Tag 3 | Klimmzüge (mit Zusatzgewicht) |  | explosiv hoch | 3 | 5 |  | 3-4 |  |  |
| Tag 3 | Kurzhantel über Kopf drücken, stehend |  |  | 4 | 6-8 |  | 3-4 |  |  |
| Tag 3 | Hollow Body Hold |  |  | 3 | ALAP |  | 7RPE |  |  |
| Tag 3 | Superman Hold |  |  | 3 | ALAP |  | 7RPE |  |  |

### Woche 5

| Tag | Übung | Cueing | Tempo | Sätze | Wdh. | Gewicht | Ziel RIR | Schmerz Ziel | Notizen |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Tag 1 | Kniebeugen | Auf Druck unter den Fußsohlen achten | kontrolliert langsam mit Pause | 5 | 4 |  | 2-3 | max 3/10 | Barfuß |
| Tag 1 | Bulgarian Split Squats | Auf Druck unter den Fußsohlen achten | kontrolliert langsam | 3 | 6-10 |  | 3-4 | max 3/10 | Barfuß |
| Tag 1 | Latziehen |  | explosiv hoch | 5 | 3 |  | 3-4 |  |  |
| Tag 1 | Lu Raises |  |  | 4 | 6-10 |  | 3-4 |  |  |
| Tag 1 | Ab Wheel |  |  | 3 | AMRAP |  | 3-4 |  |  |
| Tag 1 | Hyperextensions mit Glute Fokus |  |  | 3 | 6-10 |  | 3-4 |  |  |
| Tag 2 | Kreuzheben mit Trapbar |  | etwas explosiv vom Boden, wenn das Knie es erlaubt | 5 | 4 |  | 3-4 | max 3/10 |  |
| Tag 2 | Rudern mit V-Griff |  |  | 3 | 6-8 |  | 3-4 |  |  |
| Tag 2 | Überzüge mit Kurzhantel |  |  | 3 | 6-8 |  | 3-4 |  |  |
| Tag 2 | Pallof Rotations |  |  | 4 | 8-12 |  | 2-3 |  |  |
| Tag 2 | Beinbeuger |  |  | 4 | 8-12 |  | 2-3 |  |  |
| Tag 2 | Beinstrecker |  |  | 4 | 8-12 |  | 2-3 | max 3/10 |  |
| Tag 3 | Kniebeugen | Auf Druck unter den Fußsohlen achten | kontrolliert langsam mit Pause | 5 | 4 |  | 2-3 | max 3/10 |  |
| Tag 3 | Bulgarian Split Squats | Auf Druck unter den Fußsohlen achten | kontrolliert langsam | 3 | 6-10 |  | 3 | max 3/10 |  |
| Tag 3 | Klimmzüge (mit Zusatzgewicht) |  | explosiv hoch | 3 | 5 |  | 3-4 |  |  |
| Tag 3 | Kurzhantel über Kopf drücken, stehend |  |  | 4 | 6-8 |  | 3-4 |  |  |
| Tag 3 | Hollow Body Hold |  |  | 3 | ALAP |  | 7RPE |  |  |
| Tag 3 | Superman Hold |  |  | 3 | ALAP |  | 7RPE |  |  |

### Woche 6

| Tag | Übung | Cueing | Tempo | Sätze | Wdh. | Gewicht | Ziel RIR | Schmerz Ziel | Notizen |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Tag 1 | Kniebeugen | Auf Druck unter den Fußsohlen achten | kontrolliert langsam mit Pause | 5 | 3 |  | 2-3 | max 3/10 | Barfuß |
| Tag 1 | Bulgarian Split Squats | Auf Druck unter den Fußsohlen achten | kontrolliert langsam | 3 | 6-10 |  | 3-4 | max 3/10 | Barfuß |
| Tag 1 | Latziehen |  | explosiv hoch | 5 | 1 |  | 3-4 |  |  |
| Tag 1 | Lu Raises |  |  | 4 | 6-10 |  | 3-4 |  |  |
| Tag 1 | Ab Wheel |  |  | 3 | AMRAP |  | 3-4 |  |  |
| Tag 1 | Hyperextensions mit Glute Fokus |  |  | 3 | 6-10 |  | 3-4 |  |  |
| Tag 2 | Kreuzheben mit Trapbar |  | etwas explosiv vom Boden, wenn das Knie es erlaubt | 5 | 3 |  | 3-4 | max 3/10 |  |
| Tag 2 | Rudern mit V-Griff |  |  | 3 | 6-8 |  | 3-4 |  |  |
| Tag 2 | Überzüge mit Kurzhantel |  |  | 3 | 6-8 |  | 3-4 |  |  |
| Tag 2 | Pallof Rotations |  |  | 4 | 8-12 |  | 2-3 |  |  |
| Tag 2 | Beinbeuger |  |  | 4 | 8-12 |  | 2-3 |  |  |
| Tag 2 | Beinstrecker |  |  | 4 | 8-12 |  | 2-3 | max 3/10 |  |
| Tag 3 | Kniebeugen | Auf Druck unter den Fußsohlen achten | kontrolliert langsam mit Pause | 5 | 3 |  | 2-3 | max 3/10 |  |
| Tag 3 | Bulgarian Split Squats | Auf Druck unter den Fußsohlen achten | kontrolliert langsam | 3 | 6-10 |  | 3 | max 3/10 |  |
| Tag 3 | Klimmzüge (mit Zusatzgewicht) |  | explosiv hoch | 3 | 5 |  | 3-4 |  |  |
| Tag 3 | Kurzhantel über Kopf drücken, stehend |  |  | 4 | 6-8 |  | 3-4 |  |  |
| Tag 3 | Hollow Body Hold |  |  | 3 | ALAP |  | 7RPE |  |  |
| Tag 3 | Superman Hold |  |  | 3 | ALAP |  | 7RPE |  |  |
