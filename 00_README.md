# GymTracker iOS App – Dokumentationspaket

Dieses Paket beschreibt eine allgemeine iOS-App zum Planen, Tracken und Auswerten strukturierter Gym-Sessions. Der bisherige Plan **„Trainingsplan Christian Hemker B1.xlsx“** dient nur noch als Demo-/Seed-Datensatz.

Der Demo-Datensatz enthält:

- 6 Wochen Trainingsplanung
- 3 Trainingstage pro Woche
- 18 Sessions insgesamt
- 108 geplante Übungszeilen
- Fokus: Wettkampfvorbereitung, Belastbarkeitsaufbau Knie, Kraftsteigerung
- Tracking-Felder: Übung, Cueing, Tempo, Sätze, Wiederholungen, Gewicht, Ziel-RIR, Ist-RIR, Schmerz-Ziel, tatsächlicher Schmerz, Notizen

## Ziel der App

Die App soll aus einem statischen Trainingsplan ein dynamisches Trainingssystem machen:

1. Trainingsplan hinterlegen
2. Session starten
3. Übung für Übung tracken
4. Satzdaten, Gewicht, RIR, Schmerz und Notizen erfassen
5. Fortschritt über Wochen erkennen
6. Belastbarkeit des Knies kontrolliert steuern
7. Plananpassungen und Progression dokumentieren

## Enthaltene Dateien

| Datei | Inhalt |
|---|---|
| `00_README.md` | Überblick über das Dokumentationspaket |
| `01_App_Beschreibung_Produktvision.md` | Produktidee, Zielbild, MVP, spätere Ausbaustufen |
| `02_Excel_Vorlage_Analyse.md` | Analyse der hochgeladenen Trainingsplan-Vorlage |
| `03_Funktionale_Requirements.md` | Funktionale und nicht-funktionale Anforderungen |
| `04_Domain_Model_Datenmodell.md` | Domain-Modell, Entitäten, Beziehungen und Datenfelder |
| `05_UX_UI_Screens_User_Flows.md` | Screens, Navigation und zentrale User-Flows |
| `06_Tracking_Progression_Logik.md` | Logging, RIR, Schmerz, Volumen, Progression und Warnlogik |
| `07_Technische_Architektur_iOS.md` | SwiftUI-/SwiftData-Architektur und Modulstruktur |
| `08_Backlog_ToDos_Roadmap.md` | Epics, User Stories, Akzeptanzkriterien und To-dos |
| `09_Testkonzept_QA.md` | Teststrategie, Testfälle und Qualitätskriterien |
| `10_Datenschutz_Security_HealthKit.md` | Datenschutz, lokale Datenhaltung, optionale HealthKit-Integration |
| `11_Codex_Implementierungs_Prompts.md` | Schrittweise Prompts zur Umsetzung mit Codex |
| `12_Extrahierter_Trainingsplan.md` | Der aus Excel extrahierte Trainingsplan als Markdown |
| `seed_christian_b1_plan.json` | Zusatzdatei mit vollständigen Seed-Daten für die Implementierung |

## Empfohlener Technologie-Stack

| Bereich | Empfehlung |
|---|---|
| UI | SwiftUI |
| Lokale Persistenz | SwiftData |
| Diagramme | Swift Charts |
| Architektur | MVVM + Repository + Service Layer |
| Tests | XCTest / Swift Testing |
| Synchronisation | später optional iCloud/CloudKit |
| Health-Daten | später optional HealthKit, nur nach expliziter Zustimmung |

## Offizielle Apple-Referenzen

- SwiftUI: https://developer.apple.com/documentation/swiftui
- SwiftData: https://developer.apple.com/documentation/SwiftData
- Swift Charts: https://developer.apple.com/documentation/Charts
- HealthKit: https://developer.apple.com/documentation/healthkit
- HealthKit Setup: https://developer.apple.com/documentation/healthkit/setting_up_healthkit
- HealthKit Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/healthkit
