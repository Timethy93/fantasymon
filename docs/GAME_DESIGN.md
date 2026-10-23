# FantasyMon – Game Design

## Status und Spielvision

FantasyMon ist ein eigenständiges Monster-Raising-RPG, inspiriert von Digimon World 1 (PS1). Im Mittelpunkt steht die Beziehung zu einem Monsterpartner: Der Spieler erkundet mit ihm die Welt, kümmert sich um seine Bedürfnisse, trainiert ihn und beeinflusst dadurch seine Entwicklung. Rekrutierbare Monster helfen beim Wiederaufbau einer zentralen Stadt.

Dieses Dokument trennt bereits getroffene Entscheidungen von geplanten Ausarbeitungen. **OFFEN** bezeichnet Details, die noch nicht verbindlich entschieden sind. Die Inspiration betrifft das grundlegende Spielerlebnis; Monster, Welten und Assets sind eigene Kreationen.

## Festgelegte Eckpunkte

- Godot 4.7.2 mit GDScript.
- 2.5D-Darstellung: vorgerenderte 2D-Hintergründe und animierte 3D-Charaktere.
- Feste Kameraperspektiven und unsichtbare 3D-Geometrie für Bewegung und Kollisionen.
- Ein Monsterpartner begleitet den Spieler.
- Monsteraufzucht mit Bedürfnissen und Training.
- Verzweigte Evolutionen, die von der Aufzucht abhängen.
- Halbautomatisches Kampfsystem.
- Rekrutierbare Monster bauen eine zentrale Stadt wieder auf.

## Geplanter Spielablauf

Der grundlegende Ablauf verbindet Erkunden, Versorgen, Trainieren und Kämpfen. Die Aufzucht beeinflusst die Evolution des Partners. Begegnungen mit rekrutierbaren Monstern führen zum Fortschritt der Stadt, die wiederum neue Anlässe für weitere Erkundung bieten soll.

**OFFEN:** Konkrete Rückkehrgründe, Freischaltungen, Fortschrittsbedingungen und das Verhältnis zwischen Aufzucht, Erkundung und Kämpfen.

## Welt und Darstellung

Jeder Schauplatz kombiniert einen vorgerenderten Hintergrund mit passend ausgerichteten 3D-Charakteren. Unsichtbare 3D-Flächen und Hindernisse bestimmen begehbare Bereiche und blockieren unpassierbare Stellen. Die Kameraperspektive bleibt fest; Hintergrund und Geometrie müssen räumlich zusammenpassen.

Der erste spielbare Schauplatz ist eine kleine Waldlichtung.

**OFFEN:** Weltumfang, Verbindung zwischen Schauplätzen, Anzahl der Perspektiven je Schauplatz, Kameraprojektion, Verdeckung hinter Vordergrundelementen, Licht- und Schattenstil sowie Zielauflösung.

## Spieler und Monsterpartner

Die technische Monster-Foundation (Phase 1) ist in [MONSTER_SYSTEM_DESIGN.md](MONSTER_SYSTEM_DESIGN.md) beschrieben. Sie implementiert Artdefinitionen, individuelle Stats, Current HP/MP und ID-basiertes Laden, noch keinen sichtbaren Begleiter. Dasselbe Dokument enthält die inzwischen beschlossenen zukünftigen Regeln; diese konkretisieren die folgenden früheren OFFEN-Markierungen für Monsterwerte, sieben Evolutionsstufen, Pflege, Schlaf und Tod, ohne die Simulation bereits umzusetzen.

Der Spieler bewegt sich durch die Welt und wird von einem Monsterpartner begleitet. Der Partner ist der Mittelpunkt der Aufzucht und des Kampfsystems.

**OFFEN:** Eingabegeräte, Steuerungsdetails, Bewegungsgeschwindigkeit, Interaktionsreichweite, Verhalten bei Hindernissen und die Möglichkeit, den Partner zu wechseln.

## Bedürfnisse und Training

Die Versorgung und das Training des Partners bilden die Grundlage der Aufzucht. Bedürfnisse sollen den Spieler zu Fürsorgehandlungen veranlassen; Training beeinflusst die Entwicklung des Monsters.

**OFFEN:** Welche Bedürfnisse existieren, ihre Wertebereiche und Änderungsraten, Zeitmodell, Trainingsarten, Kosten, Auswirkungen und Folgen vernachlässigter Versorgung. Hunger, Müdigkeit oder konkrete Kampfwerte sind damit noch nicht festgelegt.

## Verzweigte Evolution

Der Partner kann abhängig von seiner Aufzucht unterschiedliche Evolutionsformen erreichen. Die Auswahl der Form soll auf nachvollziehbaren Aufzuchtergebnissen beruhen.

**OFFEN:** Evolutionsstufen, Monsteranzahl, Voraussetzungen, Zeitpunkt der Prüfung, Priorität bei mehreren erfüllten Bedingungen und Sichtbarkeit der Kriterien. Lebensspanne, Tod und Wiedergeburt sind nicht entschieden.

## Halbautomatischer Kampf

Der Kampf verbindet selbstständiges Monsterverhalten mit Einfluss durch den Spieler. Welche Aktionen automatisch ablaufen und welche Eingriffe der Spieler erhält, muss vor der Umsetzung eines Kampfprototyps geklärt werden.

**OFFEN:** Echtzeit- oder anderes Zeitmodell, Befehle, Zielauswahl, Fähigkeiten, Ressourcen, Positionierung, Kampfstart und -ende sowie Folgen von Sieg, Niederlage oder Flucht.

## Rekrutierung und Stadtaufbau

Monster können rekrutiert werden und zum Wiederaufbau einer zentralen Stadt beitragen. Dadurch soll der Fortschritt in der Welt auch in der Stadt sichtbar werden.

**OFFEN:** Rekrutierungsbedingungen, konkrete Bewohner, Gebäude, Dienstleistungen, Ausbauabfolge, visuelle Veränderungen und Auswirkungen auf die Aufzucht. Direkte Bauplatzierung durch den Spieler ist nicht entschieden.

## Umfang und Erfolg des ersten Prototyps

Der erste Prototyp prüft ausschließlich das räumliche Grundgefühl: eine Waldlichtung mit festem Hintergrund, fester Kamera, steuerbarem Spieler, funktionierenden Kollisionen und folgendem Monsterpartner. Platzhalter dürfen die spätere Darstellung erproben; finale Inhalte sind hierfür nicht erforderlich.

Der Prototyp ist erfolgreich, wenn der Spieler die Lichtung erkunden kann, an Hindernissen und Grenzen gestoppt wird und der Partner sichtbar mitkommt. Aufzucht, Evolution, Kampf und Stadtaufbau folgen in späteren Schritten.

**OFFEN:** Zielplattformen, Zielgruppe, Umfang des fertigen Spiels, Handlung, Audio, Veröffentlichung und Produktionsbudget.
