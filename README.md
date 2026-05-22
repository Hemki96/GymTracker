# GymTracker

Native iOS-App zum Tracken von Gym-Sessions auf Basis eines strukturierten Trainingsplans.

## Architektur

- SwiftUI App Lifecycle
- MVVM fuer Features
- Domain-, Data- und DesignSystem-Schichten
- SwiftData vorbereitet mit minimalem Persistenzmodell
- Businesslogik bleibt ausserhalb von SwiftUI Views

## Projektstruktur

```text
GymTracker/
├── App/
├── Domain/
├── Data/
├── Features/
├── DesignSystem/
├── Tests/
└── docs/adr/
```

## Build

```bash
xcodebuild \
  -project GymTracker.xcodeproj \
  -scheme GymTracker \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Fuer einen Simulator- oder Device-Build in Xcode muss ein Development Team im Target `GymTracker` gesetzt werden.

## Tests

```bash
xcodebuild \
  -project GymTracker.xcodeproj \
  -scheme GymTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test
```

Ohne verfuegbaren Simulator koennen App und Tests zumindest kompiliert werden:

```bash
xcodebuild \
  -project GymTracker.xcodeproj \
  -scheme GymTracker \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing
```

Alternativ kann `GymTracker.xcodeproj` direkt in Xcode geoeffnet und ueber `Cmd+B` bzw. `Cmd+U` gebaut und getestet werden.
