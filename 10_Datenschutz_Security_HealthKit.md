# Datenschutz, Security und optionale HealthKit-Integration

## 1. Datenschutzprinzipien

Die App verarbeitet persönliche Trainingsdaten. Auch wenn die Daten nicht automatisch medizinisch sind, können Schmerzwerte, Leistungsdaten und Trainingshistorien sensibel sein.

Grundprinzipien:

- Lokal speichern
- Keine Datenübertragung ohne Zustimmung
- Kein Tracking durch Drittanbieter im MVP
- Kein Account-Zwang
- Export nur durch aktive Nutzeraktion
- HealthKit nur optional

## 2. Lokale Datenhaltung

### MVP

Alle Daten werden lokal über SwiftData gespeichert.

### Vorteile

- funktioniert offline
- keine Serverkosten
- geringere Datenschutzkomplexität
- einfache MVP-Umsetzung
- Nutzer behält Kontrolle

### Risiken

| Risiko | Gegenmaßnahme |
|---|---|
| Geräteverlust | später optional iCloud Backup oder Export |
| App-Löschung | Exportfunktion anbieten |
| Datenkorruption | Validierung und Migrationen testen |

## 3. HealthKit

HealthKit kann später sinnvoll sein, ist aber nicht erforderlich für den MVP.

Apple beschreibt HealthKit als zentralen Speicher für Gesundheits- und Fitnessdaten. Apps müssen vor Zugriff auf HealthKit-Daten die Zustimmung des Nutzers einholen und HealthKit in den App Capabilities aktivieren.

## 4. Sinnvolle HealthKit-Daten

### Lesen

- Körpergewicht
- Herzfrequenz
- aktive Energie
- ggf. Workout-Historie

### Schreiben

- Krafttraining-Workout
- Dauer
- Energieverbrauch, falls sinnvoll berechnet
- optional Trainingsmetadaten

## 5. Was nicht sinnvoll ist

- klinische Gesundheitsdaten
- unnötige Dauersynchronisation
- Zugriff auf Daten, die für die App nicht benötigt werden
- HealthKit als Pflichtfunktion

## 6. Berechtigungstext

Beispiel für eine nutzerfreundliche Erklärung:

```text
GymTracker kann optional auf Apple Health zugreifen, um dein Körpergewicht oder Trainingsdaten zu berücksichtigen. Deine Trainingsplanung funktioniert auch ohne diese Freigabe. Du kannst die Berechtigungen jederzeit in den iOS-Einstellungen ändern.
```

## 7. Security-Anforderungen

| Anforderung | Umsetzung |
|---|---|
| lokale Speicherung | SwiftData |
| keine Drittanbieter im MVP | keine Analytics SDKs |
| Export kontrolliert | Share Sheet nur durch Nutzeraktion |
| HealthKit optional | Feature Flag |
| keine unnötigen Daten | Datenminimierung |
| Löschfunktion | alle lokalen Daten löschen |

## 8. Löschkonzept

Die App sollte anbieten:

- einzelne Session löschen
- Trainingsblock archivieren
- Trainingsblock löschen
- alle Daten löschen
- Export vor Löschung anbieten

## 9. Datenschutzseite in der App

Inhalte:

- welche Daten gespeichert werden
- wo Daten gespeichert werden
- ob Daten übertragen werden
- wie Daten exportiert werden
- wie Daten gelöscht werden
- HealthKit-Hinweis, falls aktiviert

## 10. App Store Privacy

Für den MVP sollte das Ziel sein:

- keine Daten mit Drittanbietern geteilt
- keine personenbezogenen Daten für Tracking
- keine Werbung
- keine externen Analytics

## 11. Technische To-dos

- Datenschutztext erstellen
- Settings-Screen „Daten & Datenschutz“
- Exportfunktion
- Löschfunktion
- HealthKit nur hinter Feature Flag
- HealthKit Capability erst aktivieren, wenn wirklich genutzt
- Permission Flow testen

## Offizielle Apple-Referenzen

- SwiftUI: https://developer.apple.com/documentation/swiftui
- SwiftData: https://developer.apple.com/documentation/SwiftData
- Swift Charts: https://developer.apple.com/documentation/Charts
- HealthKit: https://developer.apple.com/documentation/healthkit
- HealthKit Setup: https://developer.apple.com/documentation/healthkit/setting_up_healthkit
- HealthKit Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/healthkit
