# Tracking-, Progressions- und Auswertungslogik

## 1. Grundprinzip

Die App unterscheidet drei Ebenen:

1. Planvorgabe
2. Ist-Erfassung
3. Auswertung / Empfehlung

Beispiel:

```text
Plan:
Kniebeugen – 5x5 @ 80 kg, Ziel-RIR 2–3, Schmerz max 3/10

Ist:
Satz 1: 80 kg x 5, RIR 3, Schmerz 1
Satz 2: 80 kg x 5, RIR 2, Schmerz 2
Satz 3: 80 kg x 5, RIR 2, Schmerz 2
Satz 4: 80 kg x 5, RIR 1, Schmerz 3
Satz 5: 80 kg x 4, RIR 1, Schmerz 3

Auswertung:
Plan fast erfüllt, letzter Satz nicht vollständig. Gewicht wiederholen.
```

## 2. Volumenberechnung

### Formel

```text
Volumen = Gewicht × Wiederholungen
```

Für eine Übung:

```text
Übungsvolumen = Summe aller abgeschlossenen Sätze
```

Für eine Session:

```text
Sessionvolumen = Summe aller Übungsvolumina
```

### Sonderfälle

| Fall | Behandlung |
|---|---|
| Körpergewichtsübung | Gewicht optional leer; Volumen kann als Reps-Volumen geführt werden |
| Zusatzgewicht Klimmzüge | Zusatzgewicht als Gewicht erfassen, optional Körpergewicht später ergänzen |
| AMRAP | tatsächliche Wiederholungen erfassen |
| ALAP | Zeitdauer in Sekunden erfassen oder als Textnotiz im MVP |

## 3. RIR-Auswertung

### Ziel

RIR zeigt, wie viele Wiederholungen theoretisch noch möglich gewesen wären.

### Bewertung

| Abweichung | Interpretation |
|---|---|
| Ist-RIR im Zielbereich | Vorgabe getroffen |
| Ist-RIR höher als Ziel | möglicherweise zu leicht |
| Ist-RIR niedriger als Ziel | möglicherweise zu schwer |
| Ist-RIR stark niedriger | Belastung kritisch prüfen |

### Algorithmus

```text
targetRange = parseTargetRIR("2-3")
actual = 1

if actual < targetRange.min:
    status = "zu schwer"
else if actual > targetRange.max:
    status = "zu leicht"
else:
    status = "im Ziel"
```

## 4. Schmerzlogik

### Ziel

Schmerz wird nicht als reine Notiz behandelt, sondern als Steuerungsgröße.

### Regeln

| Regel | App-Verhalten |
|---|---|
| Schmerz <= Ziel | normal speichern |
| Schmerz > Ziel | Warnung anzeigen |
| Schmerz steigt über mehrere Sätze | Hinweis: Gewicht reduzieren oder Übung abbrechen |
| Schmerz bei Knieübungen wiederholt hoch | Wochenhinweis erzeugen |

### Beispiel

```text
Schmerz-Ziel: max 3/10
Ist: 4/10

Warnung:
"Der Schmerz liegt über dem Zielwert. Reduziere die Last, pausiere oder beende die Übung, wenn nötig."
```

Die App ersetzt keine medizinische Beratung. Sie dokumentiert Belastungsreaktionen und hilft, Trainingsentscheidungen bewusster zu treffen.

## 5. Compliance-Berechnung

### Satz-Compliance

```text
Satz-Compliance = abgeschlossene geplante Sätze / geplante Sätze
```

### Session-Compliance

```text
Session-Compliance = abgeschlossene geplante Übungen / geplante Übungen
```

### Plan-Compliance

```text
Plan-Compliance = abgeschlossene Sessions / geplante Sessions
```

## 6. Progressionsentscheidung

Die App kann einfache Regeln anzeigen, ohne automatisch den Plan zu überschreiben.

### Regelvorschlag für Kraftübungen

| Bedingung | Empfehlung |
|---|---|
| Alle Sätze erfüllt, RIR im Ziel, Schmerz <= Ziel | Gewicht leicht erhöhen oder Wiederholungen steigern |
| Alle Sätze erfüllt, RIR deutlich höher als Ziel | Gewicht erhöhen |
| Sätze nicht erfüllt, RIR niedriger als Ziel | Gewicht wiederholen oder reduzieren |
| Schmerz > Ziel | Last reduzieren oder Übung anpassen |
| Schmerzen steigen über Wochen | Deload oder Ersatzübung prüfen |

## 7. Übungsspezifische Logik aus der Vorlage

### Kniebeugen

- Schmerz-Ziel sichtbar anzeigen
- Cue „Druck unter den Fußsohlen“ prominent machen
- Fortschritt über Gewicht, RIR und Schmerz kombinieren

### Bulgarian Split Squats

- unilateral markieren
- Gewicht je Seite ermöglichen
- Notiz „Barfuß“ als Planhinweis anzeigen

### Trapbar-Kreuzheben

- Hinweis: explosiv vom Boden nur, wenn Knie es erlaubt
- Schmerz-Ziel beachten

### Klimmzüge mit Zusatzgewicht

- Zusatzgewicht erfassen
- Körpergewicht optional später ergänzen
- Rep-Ziel separat bewerten

### Core-Übungen AMRAP/ALAP

- AMRAP: Reps erfassen
- ALAP: Zeitdauer erfassen
- RPE/RIR-Feld optional vereinfachen

## 8. Dashboard-Kennzahlen

| Kennzahl | Berechnung |
|---|---|
| abgeschlossene Sessions | Count SessionLog completed |
| geplante Sessions | Count WorkoutPlan |
| Planfortschritt | abgeschlossen / geplant |
| Wochenvolumen | Summe Volumen je Woche |
| max. Schmerz Woche | max pain je Woche |
| durchschnittlicher RIR | Durchschnitt aller RIR-Werte |
| Top-Progression | größte positive Gewichtsentwicklung |
| Warnungen | Schmerzüberschreitungen, niedriger RIR |

## 9. Auswertung pro Übung

Für jede Übung soll die App zeigen:

- letzte 5 Einheiten
- bestes Gewicht
- höchstes Volumen
- durchschnittlicher Schmerz
- Notizen der letzten Einheit
- nächster Planwert
- Abweichung zum letzten Ist-Wert

## 10. Pseudocode für Session-Abschluss

```swift
func completeSession(_ session: SessionLog) {
    session.completedAt = Date()
    session.durationSeconds = calculateDuration(session)
    session.totalVolumeKg = calculateTotalVolume(session)
    session.maxPain = calculateMaxPain(session)
    session.averageRIR = calculateAverageRIR(session)
    session.status = .completed

    let warnings = evaluateWarnings(session)
    session.summary = buildSummary(session, warnings)
}
```
