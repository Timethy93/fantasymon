# FantasyMon – Architektur

## Rahmen und Status

Technische Grundlage sind Godot 4.7.2 und GDScript. Die Darstellung kombiniert vorgerenderte 2D-Hintergründe mit animierten 3D-Charakteren, festen Kameraperspektiven und unsichtbarer 3D-Kollisionsgeometrie.

Die folgende Struktur ist ein einfacher Architekturvorschlag für die schrittweise Umsetzung. Vorgeschlagene Szenen-, Skript- und Datennamen sind keine bereits existierenden Implementierungen. **OFFEN** markiert noch zu treffende Entscheidungen. Dieses Dokument erstellt keine Szenen oder Skripte.

## Grundprinzip

Ein Schauplatz hält die räumliche Darstellung und seine lokalen Objekte zusammen. Spieler und Partner sind wiederverwendbare Szenen. Fachliche Regeln für Aufzucht, Evolution, Kampf und Stadt werden erst mit dem jeweiligen Entwicklungsschritt ergänzt.

Direkte Methodenaufrufe reichen für lokale Zusammenarbeit. Signale verbinden klar abgegrenzte Ereignisse wie eine Änderung von Partnerwerten mit der Anzeige. Ein globaler Event-Bus, ein Entity-Component-System oder ein umfangreiches Manager-Netzwerk sind für den geplanten Einstieg nicht vorgesehen.

## Vorgeschlagene Szenenstruktur des Prototyps

```text
ForestClearing (Node3D)
├── Camera3D
├── Background                 # Darstellungstechnik OFFEN
├── WorldGeometry (Node3D)
│   ├── Ground (StaticBody3D mit CollisionShape3D)
│   └── Obstacles (statische Kollisionskörper)
├── Player (CharacterBody3D)
│   ├── CollisionShape3D
│   └── Visual                 # animiertes 3D-Modell
└── Partner (CharacterBody3D)
    ├── CollisionShape3D
    └── Visual                 # animiertes 3D-Modell
```

Die Kamera bewegt sich im ersten Prototyp nicht. Position, Projektion und Hintergrund werden gemeinsam eingerichtet, damit sichtbare Wege mit der unsichtbaren Geometrie übereinstimmen. Die Kollisionskörper erhalten keine sichtbaren Spiel-Meshes; zur Entwicklung kann die Kollisionsanzeige genutzt werden.

**OFFEN:** Orthografische oder perspektivische Projektion, Hintergrund als 2D-Ebene oder 3D-Fläche, Render-Ebenen, Vordergrundverdeckung, Schatten und Beleuchtung. Diese Fragen werden durch einen kleinen Darstellungstest entschieden, bevor weitere Schauplätze entstehen.

## Verantwortlichkeiten

| Baustein | Aufgabe | Einführung |
| --- | --- | --- |
| Schauplatzszene | Kamera, Hintergrund, lokale Kollisionsgeometrie und Startpositionen zusammenhalten | Erster Prototyp |
| Spielersteuerung | Eingaben in Bewegung umsetzen und Kollisionen berücksichtigen | Erster Prototyp |
| Partnersteuerung | Spieler als Ziel erhalten und mit Abstand folgen | Erster Prototyp |
| Partnerzustand | Später benötigte Aufzuchtdaten unabhängig vom sichtbaren Modell halten | Aufzuchtprototyp |
| Aufzuchtregeln | Bedürfnisse und Training auf den Partnerzustand anwenden | Aufzuchtprototyp |
| Evolutionsprüfung | Aufzuchtdaten mit definierten Evolutionsbedingungen vergleichen | Evolutionsprototyp |
| Kampfsteuerung | Automatisches Verhalten und Spielereingriffe koordinieren | Kampfprototyp |
| Stadtzustand | Rekrutierte Bewohner und daraus abgeleiteten Fortschritt halten | Stadtprototyp |
| Benutzeroberfläche | Eingaben und Zustand der jeweils vorhandenen Mechaniken anzeigen | Schrittweise |

Die Bausteine beschreiben Verantwortlichkeiten. Sie benötigen nicht jeweils einen Autoload oder eine eigene Basisklassenhierarchie.

## Bewegung und Begleitung

Spieler und Partner bewegen sich über die Godot-Physik mit `CharacterBody3D`. Eingaben werden über die Input Map gebündelt. Die konkrete Zuordnung zwischen Eingabe, Kamera und Bewegung wird beim Prototyp festgelegt.

Die Partnersteuerung erhält eine Referenz auf den Spieler. Zunächst genügt eine einfache Folgebewegung auf der kleinen Lichtung. Ein Abstand verhindert dauerhaftes Auflaufen. Hindernisfälle werden bewusst getestet; bei erforderlicher Wegfindung kann anschließend `NavigationAgent3D` ergänzt werden.

**OFFEN:** Konkrete Eingaben, Bewegungsparameter, Kollisionsschichten, Kollision zwischen Spieler und Partner sowie die Lösung für festhängende Partner. Navigation und Teleportieren sind noch keine festgelegten Systeme.

## Daten und Spiellogik

Für spätere statische Definitionen bieten sich kleine Godot-Resources an, beispielsweise für Monsterformen oder Evolutionsbedingungen. Veränderliche Daten eines konkreten Partners bleiben davon getrennt, damit Training keine gemeinsam genutzten Definitionen verändert.

Aufzucht- und Evolutionsregeln sollen mit Daten arbeiten und keine Abhängigkeit von Kamera oder Charaktermodell benötigen. Eine Evolution kann dadurch später die sichtbare Form wechseln, ohne die gesamte Aufzuchtlogik zu ersetzen.

**OFFEN:** Datenfelder, Formate und Bedingungsmodell. Ressourcen werden erst angelegt, wenn die jeweilige Mechanik konkrete Daten benötigt.

## Szenenübergreifender Zustand und Speichern

Der Segmentprototyp verwendet `SceneManager` als Autoload (`scripts/scene_manager.gd`). Er lädt jedes Segment frisch, blendet kurz nach Schwarz und setzt den lokalen Spieler an einen benannten `Marker3D` unter `EntryPoints`. Jede Segmentdatei enthält ihren eigenen `Player` (`CharacterBody3D`, Gruppe `player`) und eine feste Kamera. Gegner, NPCs und Ereignisse können später als lokale Knoten ergänzt werden; der Manager kennt deren Regeln nicht.

`SegmentExit` (`scripts/segment_exit.gd`) ist ein wiederverwendbarer `Area3D`-Trigger mit `target_scene` und `target_entry`. Die Eintrittspunkte liegen außerhalb der Übergangsflächen. Während Blende und Szenenwechsel sperrt der Manager weitere Übergänge und die Spielerbewegung. Zielszene und Eintrittspunkt werden vor dem Wechsel geprüft. Die WASD-Steuerung bleibt unverändert.

Temporäre Segmentzustände werden beim erneuten Betreten zurückgesetzt. Dauerhafte Spielzustände wie Rekrutierungen, abgeschlossene Quests und wichtige Ereignisse sollen später unabhängig von den Segmentknoten gehalten und gespeichert werden. Dafür ist noch kein Persistenz- oder Speichersystem implementiert. Auch ein künftiger Partnerzustand muss getrennt vom lokalen Szenenaufbau erhalten bleiben.

**OFFEN:** Struktur des dauerhaften Spielzustands, Speicherumfang, Dateiformat, Speicherzeitpunkte, Slots und Versionsbehandlung. Szenenknoten sollen nicht das dauerhafte Speicherformat bilden.

### Segmentwechsel selbst testen

1. Projekt mit F5 starten (`forest_clearing.tscn`, Segment A).
2. Dem Weg mit W nach oben zur Beschriftung „Waldpfad (W)“ folgen. Nach der kurzen Schwarzblende erscheint der Spieler im gelblicheren Segment B mit dem großen Felsblock.
3. Ohne Eingabe bleibt der Spieler am Eintrittspunkt `FromForestClearing` stehen. Mit S zum unteren Wegende „Lichtung (S)“ laufen, um zu A zurückzukehren.
4. In A erscheint der Spieler bei `FromForestPath`, etwas unterhalb des Ausgangs. Er bleibt dort stehen, bis eine neue Eingabe erfolgt. W führt erneut nach B.

Die Kameras bleiben fest. Die bisherigen Kollisionsränder bleiben als Sicherheitsbegrenzungen bestehen; die Übergangsflächen liegen kurz davor. Segment B (`forest_path.tscn`) kann zum Testen auch direkt mit F6 gestartet werden.

## Mögliche spätere Ordneraufteilung

```text
scenes/       # Schauplätze und wiederverwendbare Charaktere
scripts/      # Verhalten, nach Verantwortlichkeit gegliedert
data/         # statische Definitionen, sobald benötigt
assets/       # eigene Hintergründe, Modelle, Animationen und Audio
ui/           # Oberflächenszenen und zugehöriges Verhalten
docs/         # Design, Architektur und Planung
```

Diese Aufteilung ist ein Vorschlag und wird erst bei der Implementierung nach Bedarf angelegt. Ein zusätzliches Framework oder Plugin ist nicht festgelegt.

## Prüfung während der Entwicklung

Der erste Prototyp wird in Godot auf Kamerabild, Bewegungsgefühl, Kollisionen und Begleitung geprüft. Später lohnen sich gezielte Regeltests für Evolutionsgrenzen und Zustandsänderungen, sobald die Regeln feststehen. Jede Roadmap-Stufe soll einzeln spielbar und überprüfbar bleiben.
