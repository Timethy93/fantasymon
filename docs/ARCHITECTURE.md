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

Für den ersten 2.5D-Prototyp festgelegt: perspektivische feste Kamera, vorgerendertes PNG, echte 3D-Figuren und Collider sowie einfache 3D-Verdeckungsmeshes. Die Ausgabe bleibt bei 16:9 mit Balken auf abweichenden Seitenverhältnissen. `forest_clearing.tscn` verwendet diese Darstellung; `forest_path.tscn` bleibt vorerst dreidimensional. Technischer Aufbau, Exportanleitung, Tests und Grenzen stehen in [PRERENDERED_FOREST_POC.md](PRERENDERED_FOREST_POC.md).

**OFFEN:** Zusätzliche Vordergrundebenen für komplexe Motive, Umgebungsanimationen, dynamische Kontaktschatten und finale Beleuchtung. Eine Tiefenkarte ist im ersten Prototyp nicht vorgesehen.

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

Monster-Phase 1 verwendet editierbare `MonsterDefinition`-Resources mit stabilen IDs, Stufe, Base Stats und visueller PackedScene. `MonsterStats` hält die sechs Attribute. `MonsterInstance` ist ein RefCounted-Datenobjekt mit eigener Identität, kopierten individuellen Stats und Current HP/MP. `MonsterRegistry` lädt Definitionen bedarfsgesteuert aus `data/monsters/definitions/<id>.tres`; ein zusätzlicher Autoload ist nicht erforderlich. Die Daten sind noch nicht in die Waldsegmente eingebunden. Details, Erweiterungsregeln und Tests stehen in [MONSTER_SYSTEM_DESIGN.md](MONSTER_SYSTEM_DESIGN.md).

Aufzucht- und Evolutionsregeln sollen mit Daten arbeiten und keine Abhängigkeit von Kamera oder Charaktermodell benötigen. Eine Evolution kann dadurch später die sichtbare Form wechseln, ohne die gesamte Aufzuchtlogik zu ersetzen.

**OFFEN:** Weitere Datenfelder für Pflege, Zeit und Evolutionsbedingungen sowie deren konkrete Regeln. Die bereits beschlossenen Zukunftsentscheidungen und die Abgrenzung zur implementierten Foundation sind in `MONSTER_SYSTEM_DESIGN.md` festgehalten.

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

## Einstellungen und Übersetzungen

`GameSettings` (`scripts/game_settings.gd`) hält Sprache, vier physische Bewegungstasten, Fenster-/Vollbildmodus und Master-Lautstärke. Änderungen gelten sofort und werden als `ConfigFile` unter `user://settings.cfg` gespeichert. Beim Start werden die Werte geprüft und angewendet; ohne Datei gelten Englisch, WASD, Fenstermodus und 100 Prozent Lautstärke. Defekte Konfigurationen verwenden Standardwerte. Doppelte Bewegungstasten und ESC als Bewegungstaste werden abgewiesen; ESC bleibt für das Menü reserviert.

`SettingsMenu` ist eine einzige Autoload-Szene (`ui/settings_menu.tscn`) mit echten Controls. Ihre Logik (`ui/settings_menu.gd`) bedient den Einstellungsdienst. Sie bleibt bei Segmentwechseln bestehen. ESC öffnet und schließt das Menü; während einer Neubelegung bricht ESC zuerst die Eingabe ab. Tab, Pfeile und Enter sowie die Maus bedienen die Controls. Eine Neubelegung beginnt durch Aktivieren der betreffenden Tastenschaltfläche. Das Panel passt sich dem verfügbaren Fenster an; Schrift und Bedienelemente werden in kleinen Fenstern vergrößert, um die vorhandene Canvas-Skalierung auszugleichen. Die Reiterinhalte sind scrollbar und folgen dem Tastaturfokus.

Das Menü läuft mit `PROCESS_MODE_ALWAYS` und pausiert den SceneTree. Spielerphysik und Area3D-Übergänge ruhen, und `SceneManager.travel_to()` verweigert Aufrufe während der Pause ausdrücklich. Während einer laufenden Segmentblende kann das Menü nicht geöffnet werden. Die Bewegungsimplementierung und Kameras bleiben unverändert.

**Verbindliche Textregel:** Neue spielerseitige Texte sind immer für Übersetzungen vorzubereiten. Stabile Schlüssel und vollständige englische/deutsche Einträge gehören in `translations/strings.csv`. Godot importiert daraus die in den Projekteinstellungen registrierten Translation-Ressourcen. Englisch ist die Standardsprache, `TranslationServer` schaltet sofort um. Statische Controls erhalten Schlüssel; dynamische Texte verwenden `tr()` mit benannten Platzhaltern und aktualisieren sich bei `NOTIFICATION_TRANSLATION_CHANGED`. Auch Hinweise, Fehler und Tastennamen gehören dazu.

`WorldExitLabel` (`scripts/world_exit_label.gd`) zeigt die übersetzte Segmentbeschriftung mit der tatsächlich belegten Taste. Es reagiert auf Sprach- und Einstellungsänderungen. Segment-Ladefehler werden als Schlüssel über `SceneManager.travel_failed` an einen übersetzten UI-Hinweis gegeben; technische Details bleiben zusätzlich im Diagnoseprotokoll.

Der Referenzpfad `mocks/settings_menu.png` war nicht vorhanden; die vorhandene Montage `mocks/image.png` diente als Layout- und Farbreferenz. Das Menü übernimmt nur vereinbarte Einstellungen, ohne weitere Mechaniken aus dem Mockup.

### Einstellungsmenü selbst testen

1. Mit F5 starten, ESC drücken. Bewegungseingaben und Segmentwechsel müssen bis zum Schließen pausieren.
2. Unter General/Allgemein zwischen English und Deutsch wechseln. Menü und Wegbeschriftung ändern sich sofort.
3. Unter Controls/Steuerung eine Bewegungsschaltfläche aktivieren und eine freie Taste drücken. Eine doppelte Taste wird abgewiesen; ESC bricht die Erfassung ab. Mit der neuen Taste laufen und den aktualisierten Wegweiser prüfen.
4. Master-Lautstärke ändern, Fenster/Vollbild wechseln, Spiel stoppen und neu starten. Die Werte einschließlich Belegung und Sprache bleiben erhalten.
5. Beide Segmente besuchen und dort ESC testen. Der Rückweg und die festen Kameras bleiben erhalten.
6. Kleines und großes Spielfenster prüfen. Hinweis: Godots eingebettete Spielansicht erzwingt Fenstermodus und Fenstergröße. Den echten Vollbildwechsel in einem eigenständigen Spielfenster prüfen.

## Prüfung während der Entwicklung

Der erste Prototyp wird in Godot auf Kamerabild, Bewegungsgefühl, Kollisionen und Begleitung geprüft. Später lohnen sich gezielte Regeltests für Evolutionsgrenzen und Zustandsänderungen, sobald die Regeln feststehen. Jede Roadmap-Stufe soll einzeln spielbar und überprüfbar bleiben.
