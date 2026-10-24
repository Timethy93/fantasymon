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

Der technische Prototyp verbindet zwei frisch geladene Waldsegmente über definierte Ausgänge und Eintrittspunkte. Die Lichtung verwendet einen vorgerenderten PNG-Hintergrund, eine feste perspektivische Kamera und ein 3D-Verdeckungsmesh; der Waldpfad bleibt eine 3D-Testszene. Die Ausgabe bleibt bei 16:9 mit Balken in anderen Fensterformaten. Details stehen in [ARCHITECTURE.md](ARCHITECTURE.md) und [PRERENDERED_FOREST_POC.md](PRERENDERED_FOREST_POC.md).

**OFFEN:** Weltumfang und Verbindungen weiterer Schauplätze, finale Kameraperspektiven, zusätzliche Vordergrundverdeckung sowie endgültiger Licht- und Schattenstil.

## Spieler und Monsterpartner

Die Monster-Foundation und der erste Begleiter sind in [MONSTER_SYSTEM_DESIGN.md](MONSTER_SYSTEM_DESIGN.md) beschrieben. Die dortigen Phasen 1/2 sind technische Monster-Arbeitspakete innerhalb des ersten Roadmap-Schritts. Implementiert sind Artdefinitionen, individuelle Stats, Current HP/MP, ID-basiertes Laden und genau ein aktiver Platzhalterbegleiter, der zeitversetzt folgt und seine individuellen Daten über Segmentwechsel erhält. Die Darstellung unterstützt logische `idle`-/`walk`-Zustände; die vorhandenen Platzhalter besitzen noch keine Clips. Das Monsterdokument ist außerdem die maßgebliche Quelle für bereits beschlossene zukünftige Monsterregeln und ihre noch offenen Details.

Der Spieler bewegt sich durch die Welt und wird von einem Monsterpartner begleitet. Der Partner ist der Mittelpunkt der Aufzucht und des Kampfsystems.

Implementiert sind kamerarelative, frei belegbare Bewegungstasten und einfache kollisionsgebundene Begleiterbewegung. Artwechsel sind über eine technische API möglich, noch nicht über ein Spielmenü. **OFFEN:** Weitere Eingabegeräte, finale Bewegungsabstimmung, Interaktionsreichweite, komplexere Hindernisfälle und die spielerische Auswahl des Partners.

## Bedürfnisse und Training

Die Versorgung und das Training des Partners bilden die Grundlage der Aufzucht. Bedürfnisse sollen den Spieler zu Fürsorgehandlungen veranlassen; Training beeinflusst die Entwicklung des Monsters.

Bedürfnisse und die sechs trainierbaren Attribute sind im Monsterdokument festgelegt. Die Pflege- und Trainingssimulation ist noch nicht implementiert. **OFFEN:** Wertebereiche und Änderungsraten der Bedürfnisse, konkretes Zeitmodell, Trainingsarten, Kosten, Auswirkungen und Folgen vernachlässigter Versorgung.

## Verzweigte Evolution

Der Partner kann abhängig von seiner Aufzucht unterschiedliche Evolutionsformen erreichen. Die Auswahl der Form soll auf nachvollziehbaren Aufzuchtergebnissen beruhen.

Sieben Evolutionsstufen, verzweigte Bedingungen und grundlegende Stat- und Todesregeln sind im Monsterdokument festgelegt; die Evolution selbst ist noch nicht implementiert. **OFFEN:** Monsteranzahl, konkrete Voraussetzungen und Boni, Prüfzeitpunkte, Priorität bei mehreren erfüllten Bedingungen, Sichtbarkeit der Kriterien, Lebensspanne und Wiedergeburt.

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
