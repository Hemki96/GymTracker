# App-Beschreibung und Produktvision

## 1. Ausgangssituation

Der aktuelle Trainingsplan liegt als Excel-Datei vor. Die Struktur ist für die manuelle Planung gut geeignet, aber im Training selbst entstehen typische Probleme:

- Eingaben während der Session sind auf dem iPhone umständlich.
- Ist-Werte wie RIR, Schmerz, Gewicht und Notizen werden nicht sauber historisiert.
- Fortschritt über mehrere Wochen ist nur schwer sichtbar.
- Belastungssteuerung bei Kniebeschwerden erfordert schnelle Rückmeldung.
- Planänderungen werden nicht als Versionen dokumentiert.
- Auswertung von Volumen, Schmerzverlauf und Leistungsentwicklung ist manuell aufwendig.

## 2. Produktidee

Die App soll ein persönlicher Gym-Tracker für strukturierte Krafttrainingspläne werden. Anders als generische Fitness-Apps steht nicht nur das Loggen einzelner Übungen im Fokus, sondern die Umsetzung eines vorbereiteten periodisierten Plans.

Die App soll den Nutzer durch die geplante Session führen, Satzdaten erfassen und aus den Daten ableiten, ob Progression, Wiederholung, Deload oder Anpassung sinnvoll ist.

## 3. Zielgruppe

### Primäre Zielgruppe

- Athletinnen und Athleten mit strukturiertem Krafttraining
- Personen mit festem Trainingsplan über mehrere Wochen
- Schwimmer oder Ausdauersportler mit ergänzendem Krafttraining
- Nutzer, die RIR, RPE, Schmerz und Notizen konsequent dokumentieren möchten

### Sekundäre Zielgruppe

- Trainer, die Pläne für Athleten erstellen
- Athleten mit Reha-/Prehab-Fokus
- Fortgeschrittene Fitnessnutzer, die mehr wollen als einfache Übungslisten

## 4. Kernnutzen

| Problem | App-Lösung |
|---|---|
| Plan liegt statisch in Excel | Plan wird als interaktiver Trainingsblock in der App hinterlegt |
| Keine schnelle Eingabe im Training | Session-Modus mit großen Eingabefeldern und Satznavigation |
| Fortschritt schwer sichtbar | Wochen-, Übungs- und Belastungsübersichten |
| Kniebelastung muss kontrolliert werden | Schmerz-Tracking mit Zielwerten und Warnhinweisen |
| RIR wird selten sauber dokumentiert | Ziel-/Ist-RIR pro Übung und optional pro Satz |
| Plananpassungen gehen verloren | Versionierung von Planänderungen |
| Keine gute Auswertung | Charts für Volumen, Gewicht, RIR und Schmerz |

## 5. MVP-Zielbild

Der MVP soll folgende Kernfragen beantworten:

1. Kann ein 6-Wochen-Plan aus der Excel-Struktur sauber in der App abgebildet werden?
2. Kann eine Trainingseinheit im Gym schnell und zuverlässig getrackt werden?
3. Kann der Nutzer nach der Session erkennen, ob Planvorgaben eingehalten wurden?
4. Kann die App Fortschritt und Schmerzverlauf verständlich darstellen?
5. Kann der Plan später erweitert oder erneut verwendet werden?

## 6. MVP-Funktionsumfang

### Muss enthalten sein

- Trainingsplan mit Wochen und Trainingstagen
- Übungen mit Cueing, Tempo, Sätzen, Wiederholungen, Gewicht und Ziel-RIR
- Session starten
- Übung für Übung abarbeiten
- Ist-Werte erfassen:
  - Gewicht
  - Wiederholungen
  - Ist-RIR
  - Schmerz
  - Notizen
- Session abschließen
- Historie anzeigen
- Fortschritt pro Übung anzeigen
- Schmerzverlauf anzeigen
- Lokale Speicherung auf dem Gerät

### Nicht im MVP enthalten

- Social Features
- Trainer-/Athleten-Cloudportal
- Automatischer Planimport aus Excel
- Apple Watch App
- KI-basierte automatische Plananpassung
- Zahlungsmodell
- Vollständige Cloud-Synchronisation

## 7. Spätere Ausbaustufen

### Version 1.1

- Plan duplizieren
- Plan manuell bearbeiten
- Übungsbibliothek pflegen
- Timer für Pausen
- Supersätze / Zirkeltraining
- Export als CSV oder Markdown

### Version 1.2

- HealthKit-Integration
- Körpergewicht importieren
- Herzfrequenz oder Energieverbrauch optional anzeigen
- iCloud-Sync

### Version 2.0

- Trainer-Modus
- Athletenprofile
- Web-Planer
- Planfreigabe
- Dashboard für Trainer
- KI-Vorschläge für Progression und Belastungssteuerung

## 8. Produktprinzipien

1. **Training zuerst**: Während der Session darf nichts ablenken.
2. **Schnelle Eingabe**: Gewicht, Reps, RIR und Schmerz müssen in wenigen Sekunden erfassbar sein.
3. **Planorientiert**: Die App folgt einem vorbereiteten Trainingsplan, nicht nur einer losen Übungsdatenbank.
4. **Sicherheitsbewusst**: Schmerz- und RIR-Werte sind zentrale Steuerungsdaten.
5. **Offline-first**: Die App funktioniert vollständig ohne Internet.
6. **Exportierbar**: Daten gehören dem Nutzer.
7. **Erweiterbar**: Das Datenmodell muss spätere Cloud-, HealthKit- und Trainerfunktionen zulassen.
