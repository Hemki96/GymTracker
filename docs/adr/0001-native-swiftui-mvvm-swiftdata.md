# ADR 0001: Native SwiftUI App mit MVVM und SwiftData

## Status

Akzeptiert

## Kontext

GymTracker soll als native iOS-App entstehen. Die App startet mit einem leeren Dashboard, soll aber spaeter Trainingsplaene, Sessions, Satzlogs, Progression und lokale Persistenz abbilden. Die vorhandene Produkt- und Architekturdokumentation empfiehlt SwiftUI, SwiftData und eine klare Trennung zwischen UI, Presentation, Domain und Data.

## Entscheidung

Wir verwenden den SwiftUI App Lifecycle, strukturieren Features nach MVVM und bereiten SwiftData ueber eine zentrale `ModelContainer`-Fabrik vor. SwiftUI Views bleiben auf Layout und User-Interaktion beschraenkt. ViewModels stellen UI-State bereit und werden ueber `AppEnvironment` erzeugt. Domain- und Data-Schichten werden frueh als eigene Ordner angelegt, auch wenn das fachliche Modell im ersten Schritt bewusst minimal bleibt.

## Konsequenzen

- Neue Features bekommen eigene Views und ViewModels unter `Features/`.
- Businesslogik wandert in `Domain/Services` oder fachliche Typen, nicht in Views.
- Persistenzzugriffe werden spaeter ueber Repositories gekapselt.
- SwiftData kann erweitert werden, ohne die App-Struktur neu schneiden zu muessen.
- Das erste Persistenzmodell ist nur ein Marker, damit die Infrastruktur baubar vorbereitet ist.
