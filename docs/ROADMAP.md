# FantasyMon – Roadmap

## Planungsgrundlage

Die Entwicklung beginnt mit einem kleinen spielbaren Prototyp und erweitert ihn schrittweise. Die Reihenfolge ist ein Arbeitsvorschlag; Termine, Aufwand, Teamgröße und endgültiger Inhaltsumfang sind **OFFEN**. Jeder Schritt erhält ein überprüfbares Ergebnis, bevor der nächste größere Mechanikbereich hinzukommt.

Festgelegt sind Godot 4.7.2, GDScript, vorgerenderte 2D-Hintergründe mit animierten 3D-Charakteren, feste Kameraperspektiven und unsichtbare 3D-Geometrie. Weitere Details werden ausdrücklich entschieden und anschließend in den Dokumenten nachgeführt.

## 1. Spielbarer Prototyp: Waldlichtung

**Technischer Zwischenstand:** Monster-Foundation Phase 1 ist als separates Datenmodell mit Tests umgesetzt; siehe [MONSTER_SYSTEM_DESIGN.md](MONSTER_SYSTEM_DESIGN.md). Sichtbarer Begleiter, Folgebewegung und Animationssteuerung sind weiterhin offen. Dieser Zwischenstand schließt die gesamte folgende Prototyp-Abnahme noch nicht ab.

**Ziel:** Das Zusammenspiel aus Hintergrund, Kamera, Bewegung, Kollision und Monsterbegleiter praktisch prüfen.

1. Eine kleine Waldlichtung mit vorläufigem vorgerendertem 2D-Hintergrund einrichten.
2. Eine feste Kamera auf Hintergrund und Bewegungsfläche abstimmen.
3. Unsichtbaren Boden, Grenzen und wenige Hindernisse als 3D-Kollisionsgeometrie ergänzen.
4. Einen steuerbaren 3D-Spieler mit Kollision und einfacher Bewegungsanimation einsetzen.
5. Einen animierten 3D-Monsterpartner ergänzen, der dem Spieler folgt.
6. Die Lichtung einschließlich Rändern, Hindernissen und Richtungswechseln durchspielen.

**Abnahme:** Die Szene ist startbar. Spieler und Partner passen sichtbar zur Perspektive des Hintergrunds. Der Spieler kann sich bewegen und wird an Grenzen und Hindernissen gestoppt. Der Partner folgt bei normaler Erkundung nachvollziehbar; Hindernisfälle sind geprüft und erkennbare Blockaden behoben. Kamera und Hintergrund bleiben fest.

**Vor oder während dieses Schritts zu entscheiden – OFFEN:** Kameraprojektion, Hintergrundtechnik, Eingaben, Geschwindigkeiten, Folgeabstand und erforderliche Hindernisbehandlung des Partners.

Aufzucht, Evolution, Kampf, Stadtaufbau und Speichern sind für diese Abnahme nicht erforderlich. Vorläufige eigene Assets genügen.

## 2. Kleine Aufzuchtschleife

**Ziel:** Versorgung und Training des Partners erstmals spielbar machen.

- Einen kleinen Satz an Bedürfnissen und eine Trainingsmöglichkeit auswählen.
- Den Partnerzustand einführen und die benötigten Werte anzeigen.
- Versorgung und Training mit sichtbaren Auswirkungen umsetzen.
- Die Schleife wiederholt durchspielen und auf verständliche Rückmeldung prüfen.

**Abnahme:** Der Spieler kann einen Bedarf erkennen, darauf reagieren und eine Trainingswirkung am Partnerzustand nachvollziehen.

**OFFEN:** Bedürfnisse, Zeitmodell, Wertebereiche, Trainingswirkung, Kosten und Folgen von Vernachlässigung. Diese Regeln müssen vor ihrer Umsetzung festgelegt werden.

## 3. Verzweigte Evolution erproben

**Ziel:** Unterschiedliche Aufzucht zu unterschiedlichen Entwicklungen führen lassen.

- Für einen kleinen Testumfang alternative Evolutionsformen und Bedingungen definieren.
- Die Auswahl anhand des Partnerzustands implementieren.
- Den Wechsel der sichtbaren Monsterform anbinden.
- Unterschiedliche Aufzuchtverläufe sowie Grenzfälle prüfen.

**Abnahme:** Zwei bewusst unterschiedlich aufgezogene Testverläufe können verschiedene Evolutionszweige erreichen; die Auswahl entspricht den zuvor definierten Regeln.

**OFFEN:** Konkrete Formen, Kriterien, Prüfzeitpunkt, Prioritätsregeln und Darstellung der Evolution. Der Testumfang legt die spätere Monsteranzahl nicht fest.

## 4. Halbautomatischen Kampf erproben

**Ziel:** Das Zusammenspiel aus selbstständigem Monsterverhalten und Einfluss des Spielers bewerten.

- Das Zeitmodell und den kleinsten sinnvollen Spielereingriff festlegen.
- Eine kleine Testbegegnung mit automatischem Verhalten aufbauen.
- Den gewählten Eingriff und eine verständliche Rückmeldung ergänzen.
- Kampfabschluss und die Rückkehr zum normalen Spielablauf umsetzen.

**Abnahme:** Eine Begegnung lässt sich vollständig spielen. Automatische Aktionen und der Einfluss des Spielers sind erkennbar und folgen den festgelegten Regeln.

**OFFEN:** Befehle, Fähigkeiten, Ressourcen, Positionierung und Konsequenzen des Kampfausgangs. Eine Kopplung an Rekrutierung wird hier nicht vorausgesetzt.

## 5. Rekrutierung und zentrale Stadt

**Ziel:** Weltfortschritt durch einen rekrutierten Bewohner in der Stadt sichtbar machen.

- Einen kleinen Stadtbereich und einen rekrutierbaren Bewohner planen.
- Eine konkrete Rekrutierungsbedingung festlegen und umsetzen.
- Den Rekrutierungszustand halten und eine sichtbare Veränderung der Stadt daran knüpfen.
- Erkundung und Rückkehr in die Stadt miteinander verbinden.

**Abnahme:** Ein Monster lässt sich nach den definierten Bedingungen rekrutieren. Danach ist sein Beitrag zum Wiederaufbau sichtbar und bleibt bei einem Schauplatzwechsel erhalten.

**OFFEN:** Bewohner, Bedingung, Stadtbeitrag, Dienstleistungen und Schauplatzübergänge.

## 6. Zusammenhängende kleine Spielprobe

**Ziel:** Die bisher erprobten Mechaniken in einem begrenzten Ablauf verbinden.

- Erkundung, Aufzucht, Evolution, Kampf und Stadtfortschritt gemeinsam spielbar machen.
- Rückmeldungen, Übergänge und grundlegende Bedienung vereinheitlichen.
- Speicherbedarf definieren und Speichern/Laden für den vereinbarten Umfang ergänzen.
- Durchspielen, Fehler beheben und das Zusammenspiel der Systeme bewerten.

**Abnahme:** Der vereinbarte Ablauf kann ohne Entwickler-Eingriffe durchgespielt werden. Speichern und Laden stellen den definierten Fortschritt wieder her. Die Spielprobe liefert eine Grundlage für die Entscheidung über den weiteren Umfang.

**OFFEN:** Länge und Inhalt der Spielprobe, Speicherumfang und konkrete Qualitätsziele.

## 7. Inhaltlicher Ausbau und Fertigstellung

Erst nach Bewertung der kleinen Spielprobe werden weitere Gebiete, eigene Monster, Evolutionszweige, Bewohner und Stadtbeiträge geplant. Anschließend folgen der vereinbarte Inhaltsausbau, Balancing, finale Assets und Audio sowie technische Optimierung und Veröffentlichungsvorbereitung.

**OFFEN:** Inhaltsmenge, Produktionsplan, Zielplattformen, Leistungsziele, Barrierefreiheit, Lokalisierung, Vertriebsweg und Veröffentlichungstermin. Diese Stufe ist noch keine verbindliche Umfangszusage.
