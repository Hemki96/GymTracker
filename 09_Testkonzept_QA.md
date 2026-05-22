# Testkonzept und Qualitätssicherung

## 1. Teststrategie

Die App verarbeitet persönliche Trainingsdaten und soll während einer Session zuverlässig funktionieren. Daher liegt der Fokus auf:

- Domain-Logik
- Persistenz
- Session-Wiederherstellung
- Auswertungen
- UI-Flows
- Export

## 2. Testpyramide

```text
Viele Unit Tests
Einige Integration Tests
Wenige UI Tests
Manuelle Explorationschecks
```

## 3. Unit Tests

## 3.1 VolumeCalculatorTests

### Testfälle

| Test | Erwartung |
|---|---|
| 80 kg x 5 | 400 kg |
| Gewicht leer | 0 |
| Reps leer | 0 |
| mehrere Sätze | Summe korrekt |
| Körpergewichtsübung ohne Gewicht | Reps-Volumen separat behandeln |

## 3.2 RIRAnalyzerTests

| Eingabe | Erwartung |
|---|---|
| Ziel 2–3, Ist 2 | im Ziel |
| Ziel 2–3, Ist 4 | zu leicht |
| Ziel 2–3, Ist 1 | zu schwer |
| Ziel 3–4, Ist leer | unvollständig |
| Ziel 7RPE | als Sonderfall behandeln |

## 3.3 PainThresholdEvaluatorTests

| Ziel | Ist | Erwartung |
|---|---|---|
| max 3/10 | 2 | ok |
| max 3/10 | 3 | ok |
| max 3/10 | 4 | Warnung |
| leer | 5 | keine Zielbewertung |
| max 3/10 | leer | unvollständig |

## 3.4 SeedImportTests

| Test | Erwartung |
|---|---|
| Seed importiert Block | 1 Block |
| Strukturvalidierung | beliebige positive Wochen-, Tages- und Übungsanzahl |
| Demo-Seed importiert | Demo-Block wird einmalig importiert |
| Generischer Seed importierbar | nicht an Demo-Plan gebunden |
| Planwerte bleiben erhalten | Übungen, Sätze, Wiederholungen, Gewicht, RIR, Schmerz, Notizen |

## 4. Repository Tests

### PlanRepository

- aktiven Block laden
- Woche nach Nummer laden
- Workout nach Woche und Tag laden
- Planänderung speichern
- Originalwerte erhalten

### SessionRepository

- Session erstellen
- aktive Session finden
- Satzdaten speichern
- Session abschließen
- abgebrochene Session speichern
- Historie sortieren

## 5. ViewModel Tests

### DashboardViewModel

- zeigt aktive Woche
- zeigt nächste Session
- berechnet Planfortschritt
- zeigt Warnhinweise aus letzter Session

### ActiveSessionViewModel

- initialisiert Sätze aus Plan
- speichert Gewicht/Reps/RIR/Schmerz
- springt zur nächsten Übung
- erkennt Sessionabschluss
- stellt aktive Session wieder her

### AnalyticsViewModel

- berechnet Wochenvolumen
- berechnet Schmerzmaxima
- erzeugt Chartdaten
- gruppiert nach Übung

## 6. UI Tests

## 6.1 Session starten und abschließen

```text
Given ein aktiver Trainingsblock existiert
When der Nutzer Tag 1 startet
And alle geplanten Sätze markiert
And Session abschließt
Then erscheint eine Zusammenfassung
And die Session ist in der Historie sichtbar
```

## 6.2 Schmerz-Warnung

```text
Given eine Übung hat Schmerz-Ziel max 3/10
When der Nutzer Schmerz 4/10 erfasst
Then zeigt die App eine Warnung
And die Warnung erscheint in der Session-Zusammenfassung
```

## 6.3 App schließen während Session

```text
Given eine Session ist aktiv
When die App beendet und neu geöffnet wird
Then kann die aktive Session fortgesetzt werden
```

## 7. Manuelle Testfälle

| Bereich | Test |
|---|---|
| Dark Mode | alle Screens lesbar |
| Dynamic Type | große Schrift bricht Layout nicht |
| Einhandbedienung | Session-Logging mit Daumen möglich |
| Offline | App funktioniert im Flugmodus |
| Export | Datei kann geteilt werden |
| Datenpersistenz | Daten bleiben nach Neustart erhalten |

## 8. Qualitätskriterien

- Kein Datenverlust bei App-Wechsel
- Keine blockierenden Dialoge während Satzlogging
- Session-Screen reagiert unmittelbar
- Schmerz-Warnungen verständlich, aber nicht alarmistisch
- Export enthält vollständige Plan- und Ist-Daten
- Tests für alle zentralen Businessregeln

## 9. Fehlerfälle

| Fehlerfall | Erwartetes Verhalten |
|---|---|
| Gewicht ungültig | Eingabe ablehnen oder markieren |
| Schmerz > 10 | nicht zulassen |
| negative Reps | nicht zulassen |
| Session ohne Sätze abschließen | Bestätigung verlangen |
| aktive Session existiert bereits | Fortsetzen statt neue Session |
| Seed-Daten beschädigt | Fehlermeldung + Recovery |
