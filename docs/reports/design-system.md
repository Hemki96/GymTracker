# Design System

Datum: 2026-05-24

## Tokens

Farben:
- Primary: `Color.accentColor`
- Secondary: `Color(.secondaryLabel)`
- Surface: `Color(.secondarySystemGroupedBackground)`
- Elevated Surface: `Color(.tertiarySystemGroupedBackground)`
- Background: `Color(.systemGroupedBackground)`
- Error: `Color.red`
- Success: `Color.green`
- Warning: `Color.orange`

Spacing:
- `xsmall`: 4
- `small`: 8
- `medium`: 12
- `large`: 16
- `screen`: 24
- `xlarge`: 32

Radius:
- Cards: 8
- Controls: 8

Animation:
- Dezente `snappy` Animation fuer Button Feedback und kleine State Changes.

## Komponenten

- `PrimaryButton`: prominente CTA fuer Starten, Abschliessen und primaere Aktionen.
- `SecondaryButton`: ruhige zweite Aktion fuer Import, Demo, Navigation und Editor-Aktionen.
- `AppCard`: zentrale Kartenoberflaeche mit Padding, Surface, Radius und Dark-Mode-faehigen Systemfarben.
- `SectionContainer`: wiederverwendbarer Abschnitt mit Icon, Titel, optionalem Untertitel und Content.
- `LoadingView`: konsistenter Ladezustand mit ProgressView und Text.
- `EmptyStateView`: standardisierter leerer Zustand auf Basis von `ContentUnavailableView`.
- `ErrorStateView`: wiederverwendbarer Fehlerzustand mit roter Tinted Surface.
- `MetricCard`: KPI-Karte fuer Dashboard, Summary, History und Analysewerte.
- `DashboardCard`: hervorgehobene Infokarte mit Icon, Titel, Untertitel und Content.
- `ModernTextField`: gelabeltes Textfeld mit moderner Surface und Accessibility Label.
- `ModernNavigationBar`: grosser Screen-Header mit Icon, Titel und Untertitel.
- `AppStatusPill`: Status-Badge fuer Live, Demo, Aktiv, Historie und abgeschlossene States.

## Einsatzregeln

- Screens verwenden `ModernNavigationBar` fuer klare Orientierung.
- Wiederholte Kennzahlen verwenden `MetricCard`, keine lokalen Metric-Duplikate.
- Listen mit hoher Produktwirkung verwenden Cards statt Standard-List-Zellen.
- Formulare bleiben native `Form`, erhalten aber die gemeinsame grouped Background Surface.
- Cards werden nicht dekorativ verschachtelt; innerhalb einer Card werden kompakte Control Surfaces genutzt.
- Systemfarben bleiben die Basis fuer robustes Dark Mode Verhalten.

## Accessibility

- Cards und Row-Elemente werden dort kombiniert, wo VoiceOver sonst zu viele Einzelteile vorliest.
- Touch Targets bleiben mindestens 44pt hoch.
- Dynamic Type wird durch `lineLimit`, `minimumScaleFactor` und flexible Grids unterstuetzt.
- Status wird nicht nur ueber Farbe transportiert, sondern mit Text und teilweise Symbolen.
