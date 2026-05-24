# UX Improvements

Datum: 2026-05-24

## Verbesserte User Flows

- App-Start: Nutzer landen jetzt auf einem Dashboard statt direkt in der Planverwaltung.
- Orientierung: Dashboard zeigt direkt Anzahl Plaene, abgeschlossene Sessions, Wochenvolumen und letzte Dauer.
- Training fortsetzen: Die naechste Einheit wird auf dem Dashboard prominent sichtbar.
- Schnellzugriff: Plan und Analyse sind ueber Quick Actions erreichbar, ohne den Kontext erraten zu muessen.
- Planuebersicht: Aktive Plaene und Entwuerfe werden durch KPI Cards schneller erfassbar.
- Session Tracking: Live-Status, Vor/Zurueck Navigation und Abschluss-CTA sind visuell klarer getrennt.
- Historie: Abgeschlossene Sessions erscheinen als scanbare Cards mit Datum, Dauer, Volumen und Warnungen.
- Analyse: Charts bekommen eine staerkere Einordnung und der Uebungsfilter wirkt wie ein kontrollierter App-Baustein.

## Reduzierte kognitive Last

- Wiederkehrende Kennzahlen haben ein einheitliches Card-Muster.
- Empty States verwenden einen einheitlichen Aufbau.
- Status wird ueber Pills kommuniziert.
- Primaere und sekundaere Aktionen unterscheiden sich visuell konsistent.
- Weniger lokale Speziallayouts bedeuten weniger visuelle Wechsel zwischen Screens.

## Accessibility und Lesbarkeit

- Cards nutzen flexible Hoehen und `minimumScaleFactor` fuer laengere Werte.
- Touch Targets bleiben gross genug fuer Training im Alltag.
- VoiceOver profitiert von kombinierten Card-Elementen in zentralen Rows.
- Systemfarben und grouped Backgrounds verbessern Dark Mode und Kontrastverhalten.

## Performance

- ScrollViews bleiben LazyVStack/LazyVGrid-basiert, wo Listen laenger werden koennen.
- Keine uebertriebenen Animationen oder globalen Transitions.
- KPI-Berechnungen sind klein und lokal; Charts nutzen weiterhin die vorhandenen Mapper.
- Die Modernisierung vermeidet neue ViewModels, wo einfache View-Komposition reicht.
