# Demo-Daten-Strategie

GymTracker behandelt den bisherigen Plan "Christian B1" ausschliesslich als optionalen Demo-/Seed-Datensatz. Der Plan ist kein fachlicher Default und keine Voraussetzung fuer App-Start, Tests, Previews oder Domain-Services.

## Grundsaetze

- Die App startet mit einem leeren SwiftData-Container ohne automatischen Demo-Import.
- Demo-Import, Demo-Loeschung und Duplizieren als eigene Vorlage laufen ueber `DemoDataService`.
- `TrainingPlan.isDemoPlan` und `TrainingPlan.demoSourceIdentifier` markieren importierte Demo-Plaene eindeutig.
- Ein duplizierter Demo-Plan wird als neuer, nicht markierter `TrainingPlan` mit eigenen Wochen, Workouts, geplanten Uebungen und Saetzen gespeichert.
- Views duerfen Demo-Aktionen anbieten, enthalten aber keine Import-, Loesch- oder Kopierlogik.
- Domain-Services arbeiten nur mit den uebergebenen Trainingsplandaten und fragen keine Demo-Kennung ab.
- Previews und Tests nutzen eigene kleine Fixtures, wenn sie keinen expliziten Demo-Service-Test abdecken.

## Rollen

- `SeedDataService` validiert und importiert generische JSON-Seed-Fixtures.
- `DemoDataService` kapselt die konkrete Christian-B1-Demo-Ressource und alle Demo-spezifischen Operationen.
- `PlanPreviewData` baut eigene Preview-Daten im Speicher und importiert nicht den Demo-Plan.
