# Funktionale und nicht-funktionale Requirements

## 1. Scope

Die App soll eine iOS-Anwendung zum Planen, Durchführen und Auswerten von Gym-Sessions werden. Grundlage ist die Excel-Vorlage mit einem 6-Wochen-Plan und drei Trainingstagen pro Woche.

## 2. Funktionale Anforderungen

### FR-01 Trainingsblock verwalten

**Beschreibung:**  
Der Nutzer kann einen Trainingsblock anlegen, anzeigen und aktivieren.

**Details:**

- Name des Blocks
- Zeitraum
- Zielbeschreibung
- Anzahl Wochen
- Anzahl Trainingstage pro Woche
- Status: geplant, aktiv, abgeschlossen, archiviert

**Akzeptanzkriterien:**

- Ein Block kann mit Titel und Ziel gespeichert werden.
- Ein aktiver Block wird auf dem Dashboard prominent angezeigt.
- Ein abgeschlossener Block bleibt in der Historie erhalten.

### FR-02 Trainingsplan anzeigen

**Beschreibung:**  
Die App zeigt den hinterlegten Plan wochenweise an.

**Details:**

- Wochenübersicht
- Trainingstage je Woche
- Planwerte je Übung:
  - Cueing
  - Tempo
  - Sätze
  - Wiederholungen
  - Gewicht
  - Ziel-RIR
  - Schmerz-Ziel
  - Notizen

**Akzeptanzkriterien:**

- Der Nutzer kann von Woche zu Woche navigieren.
- Jede Session zeigt alle geplanten Übungen.
- Übungsdetails sind vor dem Start sichtbar.

### FR-03 Session starten

**Beschreibung:**  
Der Nutzer kann eine geplante Einheit starten.

**Details:**

- Startzeit speichern
- geplante Übungen in Tracking-Modus übernehmen
- Status der Session: nicht gestartet, aktiv, pausiert, abgeschlossen, abgebrochen

**Akzeptanzkriterien:**

- Eine Session kann aus dem Wochenplan gestartet werden.
- Beim Start werden alle geplanten Übungen geladen.
- Eine aktive Session kann fortgesetzt werden, wenn die App geschlossen wird.

### FR-04 Satzdaten erfassen

**Beschreibung:**  
Während der Session können Satzdaten erfasst werden.

**Pflichtfelder pro Satz:**

- Gewicht
- Wiederholungen
- RIR
- Schmerz
- optional: Notiz

**Akzeptanzkriterien:**

- Die App erzeugt initial so viele Satzzeilen wie geplant.
- Sätze können ergänzt oder gelöscht werden.
- Ist-Daten werden automatisch gespeichert.
- Der Nutzer kann zur nächsten Übung springen.

### FR-05 Übungsnotizen erfassen

**Beschreibung:**  
Der Nutzer kann Notizen pro Übung und pro Session erfassen.

**Beispiele:**

- „Knie stabil, kein Schmerz“
- „Nur 3 Wiederholungen mit Zusatzgewicht“
- „Technik gut, nächstes Mal +2,5 kg möglich“

**Akzeptanzkriterien:**

- Notizen bleiben in der Session-Historie sichtbar.
- Notizen sind bei der nächsten Wiederholung der Übung referenzierbar.

### FR-06 Schmerztracking

**Beschreibung:**  
Die App vergleicht Schmerz-Ziel und tatsächlichen Schmerz.

**Regeln:**

- Schmerz wird auf einer Skala 0–10 erfasst.
- Wenn `actualPain > targetPain`, zeigt die App einen Warnhinweis.
- Schmerzverlauf wird je Übung angezeigt.

**Akzeptanzkriterien:**

- Schmerz-Ziel ist in der Übung sichtbar.
- Überschreitungen werden in der Session-Zusammenfassung markiert.
- Dashboard zeigt maximale Schmerzwerte pro Woche.

### FR-07 RIR-Tracking

**Beschreibung:**  
Die App erfasst Ziel- und Ist-RIR.

**Details:**

- Ziel-RIR aus Plan anzeigen
- Ist-RIR pro Satz oder Übung erfassen
- Abweichung erkennen

**Akzeptanzkriterien:**

- RIR-Werte können schnell ausgewählt werden.
- Eine deutliche Abweichung vom Ziel wird angezeigt.
- Session-Zusammenfassung zeigt Zielerfüllung.

### FR-08 Fortschritt anzeigen

**Beschreibung:**  
Die App zeigt Fortschritt über Wochen und Übungen.

**Metriken:**

- verwendetes Gewicht
- Wiederholungen
- geschätztes Volumen
- RIR-Verlauf
- Schmerzverlauf
- Anzahl abgeschlossener Sessions
- Plan-Compliance

**Akzeptanzkriterien:**

- Übungsdetail zeigt historische Werte.
- Dashboard zeigt Wochenvergleich.
- Belastungstrends sind visuell erkennbar.

### FR-09 Plan anpassen

**Beschreibung:**  
Der Nutzer kann Planwerte bei Bedarf anpassen.

**Details:**

- Gewicht ändern
- Wiederholungsbereich ändern
- Sätze ändern
- Notiz ergänzen
- Übung ersetzen
- Übung hinzufügen

**Akzeptanzkriterien:**

- Änderungen werden versioniert.
- Originalplan bleibt nachvollziehbar.
- Anpassungen gelten wahlweise nur für eine Session oder für zukünftige Sessions.

### FR-10 Trainingshistorie

**Beschreibung:**  
Alle Sessions werden historisiert.

**Details:**

- Datum
- Dauer
- Session-Status
- absolvierte Übungen
- Satzdaten
- Notizen
- Warnungen

**Akzeptanzkriterien:**

- Abgeschlossene Sessions sind chronologisch sichtbar.
- Jede Session kann erneut geöffnet werden.
- Werte können nachträglich korrigiert werden.

### FR-11 Export

**Beschreibung:**  
Der Nutzer kann Daten exportieren.

**Formate im MVP:**

- Markdown
- CSV

**Spätere Formate:**

- Excel
- PDF
- JSON

**Akzeptanzkriterien:**

- Ein Block kann exportiert werden.
- Eine einzelne Session kann exportiert werden.
- Export enthält Plan- und Ist-Werte.

## 3. Nicht-funktionale Anforderungen

### NFR-01 Offline-first

Die App muss vollständig ohne Internet funktionieren.

### NFR-02 Performance

- App-Start unter 2 Sekunden auf aktuellen Geräten
- Session-Screen muss ohne spürbare Verzögerung reagieren
- Lokale Abfragen für Historie und Dashboard unter 500 ms bei normaler Datenmenge

### NFR-03 Datenschutz

- Daten bleiben lokal auf dem Gerät.
- Keine Cloud-Synchronisation ohne explizite Aktivierung.
- HealthKit nur optional und nur nach Zustimmung.

### NFR-04 Bedienbarkeit im Training

- große Touch-Ziele
- Dark Mode
- schneller Wechsel zur nächsten Übung
- minimale Texteingabe während der Session
- Eingaben mit Stepper, Slider und Chips statt langer Formulare

### NFR-05 Barrierefreiheit

- Dynamic Type
- VoiceOver Labels
- ausreichende Kontraste
- keine rein farbliche Kodierung von Warnungen

### NFR-06 Wartbarkeit

- klare Modulstruktur
- getrennte Domain-, UI- und Persistenzschicht
- Unit Tests für Progression, RIR, Schmerzlogik und Datenmodell
- keine Businesslogik direkt in Views

## 4. Definition of Done für MVP

Der MVP gilt als fertig, wenn:

- der 6-Wochen-Plan aus der Vorlage vollständig in der App abgebildet ist
- Sessions gestartet und abgeschlossen werden können
- Satzdaten gespeichert werden
- Schmerz und RIR ausgewertet werden
- Dashboard und Historie funktionieren
- alle Kernflows durch Tests abgesichert sind
- die App lokal offline verwendbar ist
