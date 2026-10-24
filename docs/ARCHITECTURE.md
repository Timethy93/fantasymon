# FantasyMon – Architektur

## Rahmen und Status

Technische Grundlage sind Godot 4.7.2 und GDScript. Die Darstellung kombiniert vorgerenderte 2D-Hintergründe mit animierten 3D-Charakteren, festen Kameraperspektiven und unsichtbarer 3D-Kollisionsgeometrie.

Dieses Dokument beschreibt den implementierten technischen Prototyp und grenzt zukünftige Systeme davon ab. **OFFEN** markiert noch zu treffende Entscheidungen. Details zu Monsterdaten und Begleitung stehen zentral in [MONSTER_SYSTEM_DESIGN.md](MONSTER_SYSTEM_DESIGN.md).

## Grundprinzip

Ein Schauplatz hält die räumliche Darstellung und seine lokalen Objekte zusammen. Beide Waldsegmente enthalten einen lokalen Player-Knoten mit demselben Steuerungsskript. Der Begleiter wird aus einer wiederverwendbaren Szene erzeugt. Fachliche Regeln für Aufzucht, Evolution, Kampf und Stadt werden erst mit dem jeweiligen Entwicklungsschritt ergänzt.

Direkte Methodenaufrufe reichen für lokale Zusammenarbeit. Signale verbinden klar abgegrenzte Ereignisse wie eine Änderung von Partnerwerten mit der Anzeige. Ein globaler Event-Bus, ein Entity-Component-System oder ein umfangreiches Manager-Netzwerk sind für den geplanten Einstieg nicht vorgesehen.

## Szenenstruktur des Prototyps

Vereinfachter Ausschnitt der Waldlichtung einschließlich des zur Laufzeit erzeugten Begleiters:

```text
ForestClearing (Node3D)
├── Camera3D
├── PrerenderedBackdrop        # PNG-Bildfläche und Verdeckungsmesh zur Laufzeit
├── ForestBackdrop             # bearbeitbare Quellkulisse, zur Laufzeit ausgeblendet
├── WorldGeometry (Node3D)
│   ├── Ground (StaticBody3D mit CollisionShape3D)
│   ├── Bounds (statische Kollisionskörper)
│   └── TestRock (StaticBody3D)
├── Player (CharacterBody3D)
│   ├── CollisionShape3D
│   └── Visual                 # statisches Platzhaltermesh
├── EntryPoints (Node3D mit Marker3D)
├── ToForestPath (Area3D)
└── Companion (CharacterBody3D) # vom CompanionManager erzeugt
    ├── CollisionShape3D
    └── Visual                 # MonsterVisual mit Modell aus der Definition
```

Die Kamera bewegt sich im ersten Prototyp nicht. Position, Projektion und Hintergrund werden gemeinsam eingerichtet, damit sichtbare Wege mit der Kollisionsgeometrie übereinstimmen. Auf der Lichtung werden die Quellmeshes zur Laufzeit ausgeblendet; der Waldpfad zeichnet seine 3D-Testkulisse weiterhin direkt. Zur Entwicklung kann die Kollisionsanzeige genutzt werden.

Für den ersten 2.5D-Prototyp festgelegt: perspektivische feste Kamera, vorgerendertes PNG, echte 3D-Figuren und Collider sowie einfache 3D-Verdeckungsmeshes. Die Ausgabe bleibt bei 16:9 mit Balken auf abweichenden Seitenverhältnissen. `forest_clearing.tscn` verwendet diese Darstellung; `forest_path.tscn` bleibt vorerst dreidimensional. Technischer Aufbau, Exportanleitung, Tests und Grenzen stehen in [PRERENDERED_FOREST_POC.md](PRERENDERED_FOREST_POC.md).

**OFFEN:** Zusätzliche Vordergrundebenen für komplexe Motive, Umgebungsanimationen, dynamische Kontaktschatten und finale Beleuchtung. Eine Tiefenkarte ist im ersten Prototyp nicht vorgesehen.

## Verantwortlichkeiten

| Baustein | Aufgabe | Einführung |
| --- | --- | --- |
| Schauplatzszene | Kamera, Hintergrund, lokale Kollisionsgeometrie und Startpositionen zusammenhalten | Erster Prototyp |
| Spielersteuerung | Eingaben in Bewegung umsetzen und Kollisionen berücksichtigen | Erster Prototyp |
| Partnersteuerung | Spieler als Ziel erhalten und mit Abstand folgen | Erster Prototyp |
| MonsterInstance | Individuelle Stats und Vitalwerte unabhängig vom Weltkörper halten | Bereits implementierte Monster-Foundation |
| Life & Care | Weltzeit, Sättigung, Pflegeereignisse und Fütterung; Training bleibt geplant | MVP 1 implementiert |
| Evolutionsprüfung | Aufzuchtdaten mit definierten Evolutionsbedingungen vergleichen | Evolutionsprototyp |
| Kampfsteuerung | Automatisches Verhalten und Spielereingriffe koordinieren | Kampfprototyp |
| Stadtzustand | Rekrutierte Bewohner und daraus abgeleiteten Fortschritt halten | Stadtprototyp |
| Benutzeroberfläche | Eingaben und Zustand der jeweils vorhandenen Mechaniken anzeigen | Schrittweise |

Die Bausteine beschreiben Verantwortlichkeiten. Sie benötigen nicht jeweils einen Autoload oder eine eigene Basisklassenhierarchie.

## Bewegung und Begleitung

Spieler und Partner bewegen sich über die Godot-Physik mit `CharacterBody3D`. Eingaben werden über die Input Map gebündelt. Die Spielerbewegung verwendet die auf den Boden projizierten Kameraachsen; WASD ist die frei belegbare Standardzuordnung.

Die Partnersteuerung erhält eine Referenz auf den Spieler. Eine zeitgestempelte Positionsspur liefert das Ziel mit konfigurierbarer Verzögerung (`follow_delay = 1.0` Sekunden). Nur zeitlich freigegebene Positionen dürfen für freie Verbindungen und Hindernisabkürzungen verwendet werden. Beim Anhalten geht der Laufabstand in einen ruhigen persönlichen Abstand über. Die bekannte Eintrittsposition dient als Vorgeschichte ohne zusätzliche Spawn-Wartezeit. Hindernisfälle werden bewusst getestet; bei erforderlicher Wegfindung kann später `NavigationAgent3D` ergänzt werden.

Phase 2 verwendet den Autoload `CompanionManager` als Besitzer der aktiven MonsterInstance. Pro Waldsegment erzeugt er genau einen lokalen `CompanionFollower` aus `scenes/monsters/companion.tscn`. Die `MonsterVisual`-Komponente lädt das Modell aus der Definition und unterstützt `idle`/`walk` mit optionalen Clips. Die zeitlich freigegebene Spielerroute wird über Capsule-geprüfte freie Verbindungen abgekürzt. Zeitversetzte Bewegungsvorgaben und gebremste Annäherung erhalten Richtungswechsel und vermeiden unnötige Umwege sowie Schwingen am Ziel. Delay, Ruheabstand, Beschleunigung und Geschwindigkeit bleiben konfigurierbar. Er kollidiert mit der Welt, blockiert den Spieler nicht und löst keine Area3D-Ausgänge aus. Sichere Eintrittspositionen werden über Physikabfragen geprüft; weitere Details und die Tests bei 30/60/120 Physikschritten stehen in [MONSTER_SYSTEM_DESIGN.md](MONSTER_SYSTEM_DESIGN.md).

**OFFEN:** Artspezifische Collider, weitergehende Animationen und Umgang mit komplexeren/dynamischen Hindernissen. Es gibt weiterhin keinen allgemeinen Wegfinder und kein Teleport-Nachholen.

Die bestehende Geschwindigkeitsintegration verwendet getrennt konfigurierbare Beschleunigung und Bremsstärke. Bei zusätzlichem Rückstand zur zeitversetzten Route steigt das Geschwindigkeitslimit begrenzt an; jüngere Spurpositionen bleiben gesperrt. Die Annäherung verwendet dieselbe Bremsstärke und eine Physikschritt-Reserve. Es gibt keine zusätzliche Bewegungssteuerung. Ausgangswerte, Messungen und Einschränkungen stehen im Monsterdokument.

## Daten und Spiellogik

Die Monster-Foundation verwendet editierbare `MonsterDefinition`-Resources mit stabilen IDs, Stufe, Base Stats, visueller PackedScene und seit Phase 2 zwei grundlegenden Animationszuordnungen. `MonsterStats` hält die sechs Stats. `MonsterInstance` ist ein RefCounted-Datenobjekt mit eigener Identität, kopierten individuellen Stats und Current HP/MP. `MonsterRegistry` lädt Definitionen bedarfsgesteuert aus `data/monsters/definitions/<id>.tres` und benötigt weiterhin keinen Autoload. Der CompanionManager hält eine solche Instanz über die Waldsegmente hinweg und trennt ihre Daten vom jeweils neu erzeugten Weltkörper. Details, Erweiterungsregeln und Tests stehen in [MONSTER_SYSTEM_DESIGN.md](MONSTER_SYSTEM_DESIGN.md).

Aufzucht- und Evolutionsregeln sollen mit Daten arbeiten und keine Abhängigkeit von Kamera oder Charaktermodell benötigen. Eine Evolution kann dadurch später die sichtbare Form wechseln, ohne die gesamte Aufzuchtlogik zu ersetzen.

`WorldTime` liefert zentrale Zeitintervalle; `LifeCare` wendet sie auf die aktive Monsterinstanz an. `PlayerInventory` hält ein szenenunabhängiges Inventarmodell und bindet den unabhängigen Fütterungsdienst an aktive Instanz und Uhr. Itemdefinitionen und Startinventar kommen aus Resources. `Menus` koordiniert die getrennten Oberflächen; `GameMenus` und `GameHud` beobachten die Daten. Zuständigkeiten, Schnittstellen und Tests stehen in [LIFE_CARE_MVP.md](LIFE_CARE_MVP.md).

**OFFEN:** Weitere Pflegebedürfnisse, Schlaf, biologisches Alter und Evolutionsbedingungen. Die bereits beschlossenen Zukunftsentscheidungen bleiben im Monsterdokument maßgeblich.

## Szenenübergreifender Zustand und Speichern

Der Segmentprototyp verwendet `SceneManager` als Autoload (`scripts/scene_manager.gd`). Er lädt jedes Segment frisch, blendet kurz nach Schwarz und setzt den lokalen Spieler an einen benannten `Marker3D` unter `EntryPoints`. Jede Segmentdatei enthält ihren eigenen `Player` (`CharacterBody3D`, Gruppe `player`) und eine feste Kamera. Gegner, NPCs und Ereignisse können später als lokale Knoten ergänzt werden; der Manager kennt deren Regeln nicht.

`SegmentExit` (`scripts/segment_exit.gd`) ist ein wiederverwendbarer `Area3D`-Trigger mit `target_scene` und `target_entry`. Die Eintrittspunkte liegen außerhalb der Übergangsflächen. Während Blende und Szenenwechsel sperrt der Manager weitere Übergänge und die Spielerbewegung. Zielszene und Eintrittspunkt werden vor dem Wechsel geprüft. Die WASD-Steuerung bleibt unverändert.

Temporäre Segmentzustände werden beim erneuten Betreten zurückgesetzt. Die aktive MonsterInstance bleibt seit Phase 2 im CompanionManager über diese Wechsel erhalten. Dauerhafte Spielzustände wie Rekrutierungen, abgeschlossene Quests und wichtige Ereignisse sollen später ebenfalls unabhängig von Segmentknoten gehalten und gespeichert werden. Dafür ist noch kein Persistenz- oder Speichersystem implementiert; auch der Begleiterzustand wird bisher nicht auf Datenträger gespeichert.

**OFFEN:** Struktur des dauerhaften Spielzustands, Speicherumfang, Dateiformat, Speicherzeitpunkte, Slots und Versionsbehandlung. Szenenknoten sollen nicht das dauerhafte Speicherformat bilden.

### Segmentwechsel selbst testen

1. Projekt mit F5 starten (`forest_clearing.tscn`, Segment A).
2. Dem Weg mit W nach oben zur Beschriftung „Waldpfad (W)“ folgen. Nach der kurzen Schwarzblende erscheint der Spieler im gelblicheren Segment B mit dem großen Felsblock.
3. Ohne Eingabe bleibt der Spieler am Eintrittspunkt `FromForestClearing` stehen. Mit S zum unteren Wegende „Lichtung (S)“ laufen, um zu A zurückzukehren.
4. In A erscheint der Spieler bei `FromForestPath`, etwas unterhalb des Ausgangs. Er bleibt dort stehen, bis eine neue Eingabe erfolgt. W führt erneut nach B.

Die Kameras bleiben fest. Die bisherigen Kollisionsränder bleiben als Sicherheitsbegrenzungen bestehen; die Übergangsflächen liegen kurz davor. Segment B (`forest_path.tscn`) kann zum Testen auch direkt mit F6 gestartet werden.

## Projektordner

```text
scenes/       # Schauplätze und wiederverwendbare Charaktere
scripts/      # Verhalten, nach Verantwortlichkeit gegliedert
data/         # statische Monsterdefinitionen als .tres
assets/       # eigene Hintergründe, Modelle, Animationen und Audio
ui/           # Oberflächenszenen und zugehöriges Verhalten
docs/         # Design, Architektur und Planung
```

Diese Ordner sind vorhanden. `tests/` enthält die wiederholbaren Headless-Prüfungen; `tools/` enthält den Hintergrundexport. Weitere Strukturen werden bei konkretem Bedarf ergänzt.

## Einstellungen und Übersetzungen

`GameSettings` (`scripts/game_settings.gd`) hält Sprache, vier physische Bewegungstasten, Fenster-/Vollbildmodus und Master-Lautstärke. Änderungen gelten sofort und werden als `ConfigFile` unter `user://settings.cfg` gespeichert. Beim Start werden die Werte geprüft und angewendet; ohne Datei gelten Englisch, WASD, Fenstermodus und 100 Prozent Lautstärke. Defekte Konfigurationen verwenden Standardwerte. Doppelte Bewegungstasten und ESC als Bewegungstaste werden abgewiesen; ESC bleibt für das Menü reserviert.

`SettingsMenu` ist eine einzige Autoload-Szene (`ui/settings_menu.tscn`) mit echten Controls. Ihre Logik (`ui/settings_menu.gd`) bedient den Einstellungsdienst. Sie bleibt bei Segmentwechseln bestehen. ESC öffnet und schließt das Menü; während einer Neubelegung bricht ESC zuerst die Eingabe ab. Tab, Pfeile und Enter sowie die Maus bedienen die Controls. Eine Neubelegung beginnt durch Aktivieren der betreffenden Tastenschaltfläche. Das Panel passt sich dem verfügbaren Fenster an; Schrift und Bedienelemente werden in kleinen Fenstern vergrößert, um die vorhandene Canvas-Skalierung auszugleichen. Die Reiterinhalte sind scrollbar und folgen dem Tastaturfokus.

Die Menüansichten laufen mit `PROCESS_MODE_ALWAYS`; ausschließlich `Menus` verwaltet die gemeinsame SceneTree-Pause und normale Menütasten. Settings behält nur die Erfassung neuer Bewegungstasten. Menüwechsel entpausieren die Simulation nicht. Spielerphysik, normale Weltzeit und Area3D-Übergänge ruhen; `SceneManager.travel_to()` verweigert Wechsel während der Pause. Während Segmentblenden öffnen keine Menüs. Bewegung und Kameras bleiben unverändert.

Der Interface-Tab ergänzt persistente Sichtbarkeitsschalter für HP, MP, Sättigung und Weltzeit im bestehenden `GameSettings`. Inventar, Pflege und Monsterstatus bleiben getrennte Ansichten. Tastenkürzel, Debug-Exportausschluss und Bedienung stehen im Life-&-Care-Dokument.

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
