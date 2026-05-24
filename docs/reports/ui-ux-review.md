# UI/UX Review

Datum: 2026-05-24

## Kurzfazit

Die App war vor der Modernisierung funktional solide, aber visuell noch stark MVP-getrieben. SwiftUI, NavigationStack, SwiftData und native Charts waren bereits eine gute technische Basis. Die groessten UX-Schwaechen lagen in fehlender visueller Priorisierung, zu wenigen wiederverwendbaren UI-Bausteinen, Standard-Formularen, uneinheitlichen Metric Cards und einem fehlenden Dashboard als schneller Startpunkt.

## Befunde

- Dashboard: Der vorhandene Dashboard-Screen zeigte nur Titel und Untertitel. Es gab keine KPIs, keine naechste Einheit, keine Quick Actions und keinen echten Orientierungspunkt beim App-Start.
- Navigation: Die App startete direkt im Plan-Tab. Das ist fuer Planung logisch, aber fuer eine Fitness-App weniger intuitiv als ein Dashboard-first Einstieg.
- Design System: `AppTheme` enthielt nur zwei Spacing-Werte und einige Surface-Helfer. Farben, States, Buttons, Cards, Empty/Error/Loading States, Metric Cards und Textfelder waren nicht zentral definiert.
- Karten und Metriken: Aehnliche Karten wurden in Dashboard, History, Summary und Analytics mehrfach lokal nachgebaut. Dadurch entstanden kleine Unterschiede in Hoehe, Typografie, Icon-Nutzung und Abstand.
- Planuebersicht: Die Planliste war funktional, aber die Informationshierarchie war flach. Status, Anzahl aktiver Plaene und Entwuerfe wurden nicht als schnelle Orientierung hervorgehoben.
- Session Flow: Active Session war nutzbar, aber Live-Status, Navigation zwischen Uebungen und Abschluss-CTA wirkten eher systemstandard als hochwertig.
- History: Die Historie nutzte eine Standard-List. Das war effizient, aber weniger konsistent mit den Kartenlayouts der restlichen App.
- Analytics: Charts waren vorhanden, aber ohne starken Seitenheader und mit einem sehr einfachen Exercise Filter.
- Formulare: Editor-Screens nutzten native `Form` komplett im Standardlook. Das ist robust, wirkte aber optisch anders als die modernen Card-Screens.
- Accessibility: Touch Targets waren groesstenteils ausreichend. Verbesserungsbedarf lag bei zusammengefassten Card-Labels, Dynamic-Type-robusten Cards und konsistenten Empty States.
- Dark Mode: Native Systemfarben waren vorhanden, aber ohne definierte Surface- und State-Tokens. Dadurch war der Dark Mode technisch korrekt, aber weniger bewusst gestaltet.

## Prioritaeten

1. Zentrales Design System fuer wiederkehrende UI-Patterns schaffen.
2. Dashboard als Startpunkt mit KPI Cards, naechster Einheit und Quick Actions ausbauen.
3. Plan-, Session-, History- und Analytics-Screens an ein gemeinsames Premium-Card-System anbinden.
4. Formulare modernisieren, ohne die schnelle Dateneingabe zu verschlechtern.
5. Empty/Error/Loading States standardisieren.
6. Accessibility und Dark Mode ueber Tokens und zusammengefasste Card-Elemente verbessern.
