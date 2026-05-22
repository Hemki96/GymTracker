# UX/UI, Screens und User-Flows

## 1. Navigationskonzept

Empfohlene Hauptnavigation als TabView:

| Tab | Zweck |
|---|---|
| Heute | aktuelle oder nächste geplante Session |
| Plan | Wochen- und Tagesübersicht |
| Training | aktive Session |
| Historie | abgeschlossene Sessions |
| Analyse | Fortschritt, Schmerz, RIR, Volumen |
| Einstellungen | Export, Datenschutz, Stammdaten |

## 2. Screen: Onboarding

### Ziel

Nutzer versteht in kurzer Zeit, was die App macht.

### Inhalte

- „Trainiere nach Plan“
- „Tracke Gewicht, Reps, RIR und Schmerz“
- „Erkenne Fortschritt und Belastbarkeit“
- „Deine Daten bleiben lokal“

### Aktionen

- Beispielplan laden
- neuen Plan erstellen
- später: Excel/CSV importieren

## 3. Screen: Dashboard / Heute

### Ziel

Der Nutzer sieht sofort, was als Nächstes ansteht.

### Komponenten

- Aktiver Trainingsblock
- aktuelle Woche
- nächster Trainingstag
- Fortschritt im Block
- letzte Session
- Schmerz-Hinweis
- Schnellstart-Button

### Beispiel

```text
Wettkampfvorbereitung bis 20.06.2026
Woche 3 von 6
Nächste Session: Tag 2

Fokus:
Trapbar Kreuzheben, Rudern, Beinbeuger, Beinstrecker

[Session starten]
```

## 4. Screen: Wochenplan

### Ziel

Planstruktur anzeigen und navigierbar machen.

### Darstellung

- Segmented Control oder horizontaler Week Picker: Woche 1–6
- Karten für Tag 1, Tag 2, Tag 3
- Status je Tag: geplant, abgeschlossen, übersprungen
- Kernübungen je Tag
- Warnindikatoren bei schmerzrelevanten Übungen

### Interaktion

- Tap auf Tag öffnet WorkoutDetail
- Swipe zwischen Wochen
- Long Press für Plan bearbeiten

## 5. Screen: Workout Detail

### Ziel

Vor dem Start alle Planvorgaben sehen.

### Inhalte

Pro Übung:

- Name
- Cueing
- Tempo
- Sätze x Wiederholungen
- Gewicht
- Ziel-RIR
- Schmerz-Ziel
- Notizen

### Aktionen

- Session starten
- Plan bearbeiten
- als erledigt markieren
- Session verschieben

## 6. Screen: Aktive Session

### Ziel

Schnelles Tracking während des Trainings.

### Grundprinzip

Die App zeigt immer eine aktuelle Übung im Fokus. Nebendaten sind sichtbar, aber nicht dominant.

### Komponenten

- Fortschritt: Übung 2/6
- Übungsname
- Cueing
- Tempo
- Ziel: 5x5 @ 80 kg, RIR 2–3
- Schmerz-Ziel: max 3/10
- Satzliste
- Buttons:
  - Satz erledigt
  - Satz hinzufügen
  - Übung abschließen
  - Pause starten
  - Notiz

### Satzzeile

| Feld | UI-Element |
|---|---|
| Gewicht | Stepper / Numeric Field |
| Reps | Stepper |
| RIR | Chip-Auswahl 0–5 |
| Schmerz | Slider 0–10 oder Chips |
| erledigt | Checkbox |

## 7. Screen: Session-Zusammenfassung

### Ziel

Nach der Einheit klares Feedback geben.

### Inhalte

- Dauer
- abgeschlossene Übungen
- Gesamtvolumen
- maximale Schmerzbewertung
- durchschnittlicher RIR
- Übungen mit Schmerz-Ziel-Überschreitung
- persönliche Notizen
- Vorschlag für nächste Einheit

### Beispiel

```text
Session abgeschlossen

Dauer: 58 min
Volumen: 8.450 kg
Max. Schmerz: 2/10
RIR im Zielbereich: 83 %
Plan erfüllt: 16 von 18 Sätzen

Nächste Empfehlung:
Kniebeugen bei gleichem Gewicht wiederholen oder +2,5 kg, wenn Schmerz <= 2 bleibt.
```

## 8. Screen: Übungsdetail

### Ziel

Historie einer Übung anzeigen.

### Inhalte

- letzte Einheiten
- Gewichtsentwicklung
- Reps
- RIR
- Schmerz
- Notizen
- Bestleistungen

### Charts

- Gewicht über Zeit
- Volumen über Zeit
- Schmerz über Zeit
- RIR über Zeit

## 9. Screen: Analyse

### Ziel

Trainingsdaten verständlich auswerten.

### Metriken

| Metrik | Bedeutung |
|---|---|
| Wochenvolumen | Summe Gewicht x Reps |
| Session-Compliance | erfüllte geplante Sätze / geplante Sätze |
| RIR-Abweichung | Ziel vs. Ist |
| Schmerzmax | höchster Schmerz der Woche |
| Progression | Änderung Gewicht/Reps pro Übung |
| Übungsfrequenz | wie oft eine Übung absolviert wurde |

## 10. Screen: Plan bearbeiten

### Ziel

Der Nutzer kann geplante Werte ändern.

### Bearbeitbare Felder

- Übungsname
- Cueing
- Tempo
- Sätze
- Wiederholungen
- Gewicht
- Ziel-RIR
- Schmerz-Ziel
- Notizen

### Sicherheitsentscheidung

Bei Änderungen an bereits gestarteten Sessions muss die App fragen:

```text
Soll die Änderung nur für diese Session gelten oder auch für zukünftige Einheiten?
```

## 11. User Flow: Session durchführen

```text
Heute öffnen
→ nächste Session sehen
→ Session starten
→ Übung 1 bearbeiten
→ Satzdaten loggen
→ Übung abschließen
→ nächste Übung
→ Session abschließen
→ Zusammenfassung prüfen
→ speichern
```

## 12. User Flow: Fortschritt prüfen

```text
Analyse öffnen
→ Übung auswählen
→ Verlauf Gewicht/RIR/Schmerz sehen
→ Notizen prüfen
→ Entscheidung für nächste Einheit treffen
```

## 13. User Flow: Schmerzgrenze überschritten

```text
Satz loggen
→ Schmerz 4/10 eingeben
→ Ziel ist max 3/10
→ App zeigt Warnung
→ Nutzer kann:
   1. Gewicht reduzieren
   2. Übung abbrechen
   3. Notiz erfassen
   4. Fortfahren
```

## 14. Design-Richtlinien

- Dark Mode priorisieren
- klare Typografie
- große Buttons
- wenig Ablenkung
- Statusfarben sparsam einsetzen
- Warnungen immer mit Text + Icon, nicht nur Farbe
- schnelle Interaktion über Chips/Stepper
