# Monster-System – Phase 1: Foundation

## Status und Abgrenzung

**Implementiert:** Monsterarten als editierbare Resources, sieben Evolutionsstufen als Enum, sechs begrenzte Stats, unabhängige individuelle Monsterdaten, Current HP/MP, Laden per technischer ID, drei Testdefinitionen und wiederholbare Headless-Tests.

**Nur geplant:** Begleiter-KI, wilde Monster, Gegner-/Bossverhalten, Training als Spielmechanik, Pflege, Evolution, Zeitverwaltung, Schlaf, Lebensalter, Tod, Animationssteuerung und Savegames. Für diese Bereiche gibt es keine leeren Klassen, vorläufigen Simulationsfelder oder Manager. Die Monster werden in Phase 1 noch nicht in die Waldszenen eingesetzt.

Die neuen verbindlichen Zukunftsentscheidungen dieses Dokuments konkretisieren die zuvor als OFFEN markierten Monsterregeln in Game Design und Roadmap. Noch fehlende Zahlen und Ereignisdefinitionen bleiben ausdrücklich offen.

## Implementierte Datenklassen

### MonsterDefinition: gemeinsame Artdefinition

`scripts/monsters/monster_definition.gd` erweitert `Resource`. Die Dateien liegen unter `data/monsters/definitions/<monster_id>.tres` und lassen sich im Inspector bearbeiten.

| Feld | Verantwortung |
| --- | --- |
| `monster_id: StringName` | Stabile, nicht übersetzte technische ID, etwa `drako`. |
| `display_name_key: StringName` | Übersetzungsschlüssel, etwa `MONSTER_DRAKO_NAME`. |
| `evolution_stage: EvolutionStage` | Typisierte Evolutionsstufe. |
| `base_stats: MonsterStats` | Grundwerte der Art, als eingebettete Stat-Resource. |
| `visual_scene: PackedScene` | Referenz auf eine unabhängig austauschbare visuelle Szene. |

Das zentrale Enum `MonsterDefinition.EvolutionStage` besitzt explizite Werte: `BABY=0`, `TRAINING=1`, `KID=2`, `TEEN=3`, `ADULT=4`, `ASCENDED=5`, `MASTER=6`. Vor späteren Savegames dürfen diese Werte nicht beiläufig umnummeriert werden. Es existiert noch keine Evolutionsprüfung.

Definitionen werden bewusst gemeinsam geladen. Sie sind zur Laufzeit **Konfiguration, keine Trainingsdaten**. Godot-Resources sind technisch veränderbar; diese Konvention ist keine allgemeine Schreibsperre. Insbesondere darf Spielcode nicht über `instance.definition.base_stats` trainieren. Erweiterungen um Animationszuordnungen, Schlafrhythmen und Evolutionsregeln gehören später in die Artkonfiguration, sobald ihre konkrete Verantwortung feststeht.

### MonsterStats: wiederverwendbare Wertestruktur

`scripts/monsters/monster_stats.gd` erweitert `Resource`. Die sechs Integer-Felder sind `hp`, `mp`, `atk`, `defense` (DEF), `speed` und `brain`. HP und MP bezeichnen hier **Maximalwerte**, keine aktuellen Vitalwerte.

Die vorläufigen technischen Grenzen stehen zentral in der Klasse:

- Alle Stats höchstens `TECHNICAL_MAX = 1_000_000`.
- HP mindestens `HP_MIN = 1`.
- MP, ATK, DEF, SPEED und BRAIN mindestens `TECHNICAL_MIN = 0`.
- Current HP/MP mindestens 0 und höchstens ihr jeweiliger individueller Maximalwert.

**Dies sind Schutzgrenzen für technische Testdaten, keine finalen Balancing-Zahlen, keine 16-Bit-Speicherbegrenzung und keine Aussage über spätere Trainingsfortschritte.** Änderungen daran benötigen später eine bewusste Daten-/Savegame-Bewertung. Die Beispielwerte legen kein Balancing fest.

Setter begrenzen auch direkte Zuweisungen außerhalb des Inspectors. `copy()` erstellt eine neue Resource mit eigenen Werten. `adjust(field, delta)` ist eine allgemeine Datenänderung ohne Trainingskosten oder Spielregeln. Es begrenzt extreme Deltas vor der Addition, um einen Integer-Überlauf zu vermeiden; unbekannte Attribute liefern `false`. Die `changed`-Signale ermöglichen das Nachführen von Vitalgrenzen.

### MonsterInstance: individuelles Monster

`scripts/monsters/monster_instance.gd` erweitert `RefCounted`, weder Node noch gemeinsam geladene Resource. Die vorgesehene Erzeugung erfolgt ausschließlich über `MonsterInstance.create(definition)`. Bei fehlender oder ungültiger Definition liefert die Factory `null`; der Konstruktor ist kein alternativer Validierungseinstieg.

Eine gültig erzeugte Instanz enthält:

- Eine zufällig erzeugte 128-Bit-Instanz-ID als 32-stelligen Hex-`StringName`. Sie dient später als dauerhafte Identität und muss beim Laden wiederhergestellt werden; die Wiederherstellung ist noch nicht implementiert.
- Eine Referenz auf die gemeinsame Definition.
- Eigene individuelle `MonsterStats`, initialisiert durch Kopieren aller Base Stats.
- Getrennte `current_hp` und `current_mp`, bei Neuerzeugung vollständig aufgefüllt.

Die öffentliche Identität und Definition werden über Getter angeboten. Auch eine spätere Zuweisung an `instance.stats` kopiert die übergebenen Werte, damit weder Base Stats noch Geschwisterinstanzen versehentlich dieselbe veränderliche Stat-Resource besitzen. Nullzuweisungen werden ignoriert. Verringert sich ein Maximalwert unter den aktuellen Vitalwert, wird dieser begrenzt. Eine Erhöhung des Maximums heilt beziehungsweise füllt nicht automatisch auf. Current HP=0 löst in Phase 1 **keinen** K. o., Tod oder Pflegeeffekt aus.

### MonsterRegistry: Laden nach ID

`scripts/monsters/monster_registry.gd` ist ein normaler `RefCounted`-Dienst, **kein zusätzlicher Autoload**:

```gdscript
var registry := MonsterRegistry.new()
var definition := registry.get_monster(&"drako")
if definition != null:
    var monster := MonsterInstance.create(definition)
    monster.stats.atk = 45
    # Drakos Base ATK bleibt 20.
```

IDs sind nichtleere, kleingeschriebene Identifier; Dateiname und `monster_id` müssen übereinstimmen. Daher hat jede ID genau einen Ressourcenpfad. Die Registry lädt nur angeforderte Definitionen, prüft Typ, Felder und ID und hält danach die Referenz im Cache. Godots ResourceLoader teilt dieselben geladenen Ressourcen auch zwischen mehreren Registry-Objekten. Es gibt kein globales statisches Monsterinventar und keine Monsterinstanzen in der Registry.

Unbekannte/ungültige IDs, falsche Ressourcentypen und abweichende Ressourcen-IDs liefern kontrolliert `null` plus `last_error`. Diese Diagnose ist für Entwickler, nicht für die Spieloberfläche bestimmt. Eine spätere UI muss daraus übersetzte Meldungen ableiten. `validate_all()` ist eine explizite Autoren-/Testprüfung; sie findet auch unter anderen Dateinamen versteckte doppelte IDs. Sie gehört nicht in den regulären Startpfad, da sie alle Definitionen und damit ihre visuellen Referenzen lädt.

Der feste Ressourcenordner ist für die erste Stufe absichtlich einfach und funktioniert auch in exportierten Projekten. Hunderte Arten können bedarfsgesteuert geladen werden. Falls später Suchfunktionen oder ein Bestiarium alle Arten ohne deren Modelle einlesen müssen, ist ein leichtgewichtiger Metadatenindex eine gesonderte Erweiterung; Phase 1 braucht ihn nicht.

## Beispielressourcen und neue Arten

Die drei Arten sind ausschließlich technische Testdaten:

| ID | Stufe | HP | MP | ATK | DEF | SPEED | BRAIN |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `drako` | Kid | 120 | 40 | 20 | 16 | 12 | 10 |
| `slimo` | Training | 90 | 80 | 10 | 12 | 8 | 22 |
| `fenri` | Teen | 100 | 30 | 18 | 12 | 25 | 14 |

Platzhalterszenen unter `scenes/monsters/visuals/` besitzen eine Node3D-Wurzel und ein einfaches Mesh mit Bodenbezug. Sie enthalten weder Monsterdaten noch Verhalten oder Animationen. Ihre Namen stehen als EN/DE-Schlüssel in `translations/strings.csv`.

Eine neue Art hinzufügen:

1. Unter `data/monsters/definitions/` im Inspector eine Resource vom Typ `MonsterDefinition` erstellen und als `<id>.tres` speichern, etwa `moro.tres`.
2. Dieselbe stabile ID (`moro`), Übersetzungsschlüssel und Stufe eintragen. IDs später nicht ohne Migration umbenennen.
3. Eine **neue** `MonsterStats`-Subresource als Base Stats anlegen. Beim Duplizieren einer Art diese Subresource im Inspector eigenständig machen, wenn die beiden Arten unterschiedliche Grundwerte erhalten sollen.
4. Eine passende visuelle PackedScene zuweisen und EN/DE-Namenseinträge ergänzen. Runtime-UI verwendet `tr(definition.display_name_key)` und reagiert auf Sprachwechsel.
5. Tests ausführen beziehungsweise `registry.validate_all()` aufrufen. Danach ist `registry.get_monster(&"moro")` verfügbar; Registry-Code und allgemeine Instanzlogik benötigen keine Änderungen.

## Bereits beschlossene zukünftige Systeme – noch nicht implementiert

### Stats, Training und Evolution

- Die sechs Attribute bleiben HP, MP, ATK, DEF, SPEED und BRAIN. Training verändert individuelle Werte.
- Evolution erhält trainierte Stats grundsätzlich; eine Evolution darf daher nicht einfach eine neue Instanz aus den Base Stats der Zielart erzeugen.
- Permanente Evolutionsboni und -abzüge sollen standardmäßig additiv angewendet werden. Multiplikative Modifikatoren sollen später möglich sein, ohne mehrere widersprüchliche Kopien effektiver Stats zu pflegen.
- Die sieben Stufen folgen Baby → Training → Kid → Teen → Adult → Ascended → Master.
- Verzweigte Evolutionen verwenden datengetriebene Bedingungen: Stats, Alter, Pflegefehler, Happiness, Discipline und weitere Faktoren.
- Fehlentwicklungen können individuelle Stats reduzieren. Konkrete Boni, Bedingungen, Reihenfolge bei mehreren Treffern und Grenzwerte sind noch offen.

### Vitalwerte und Pflege

Geplant sind Hunger, Fatigue, Happiness, Discipline, Poopmeter und Krankheiten. Current HP/MP existieren bereits, ihre Spielregeln fehlen noch. Pflegefehler sollen separat erfasste Ereignisse sein und nicht aus einem beliebigen Momentanwert rekonstruiert werden. Noch keine Wertebereiche, Änderungsraten oder Versorgungsaktionen implementieren.

### Leben und Tod

Standardmäßig tritt Tod nach dem **dritten relevanten K. o.** ein. Was ein relevanter K. o. ist und welche Sonderfälle gelten, muss vor dieser Mechanik präzisiert werden. Natürlicher Tod durch biologisches Alter ist ein separater Auslöser. Noch kein K.-o.-Zähler, biologisches Alter oder Todes-/Wiedergeburtssystem vorhanden.

### Zeit und Schlaf

Reale Zeit, Weltzeit und biologisches Alter sind verschiedene Konzepte. Regionen können unterschiedliche Zeitfaktoren besitzen; Training kann später Weltzeit verbrauchen. Wie diese Faktoren auf biologisches Alter wirken, ist vor der Simulation zu entscheiden.

Es gibt keinen numerischen Sleepiness-Wert. Jede Art soll einen zeitbasierten Schlafrhythmus mit konfigurierbarer Schlafenszeit und Schlafdauer besitzen. Verspäteter Schlaf verschiebt grundsätzlich auch die Aufwachzeit. Fatigue und Schlafbedürfnis sind voneinander unabhängig. Noch keine Uhr, Zeitfaktoren, Schlafrhythmen oder Schlafzustände implementiert.

### Monsterrollen, Modelle und Animationen

Begleiter, wilde Monster, Gegner und Bosse verwenden dieselben Definitionen. Rollen entstehen durch austauschbare Verhaltenskomponenten; keine Vererbungsbäume pro Monsterart. Die individuelle Dateninstanz bleibt unabhängig von CharacterBody, Modellknoten, Skelett und konkreten Animationen.

Eine spätere Darstellungskomponente soll eine einheitliche logische Animationsschnittstelle verwenden, deren Zustände auf artspezifische Animationen abgebildet werden. Unterschiedliche Skelette und Clips bleiben möglich. Diese Schnittstelle und ihr Zustandssatz sind noch nicht implementiert oder endgültig festgelegt.

## Persistenzvorbereitung und Phase 2

Ein späterer Datensatz soll mindestens Savegame-Schemaversion, technische Art-ID, Instanz-ID, individuelle Stats und Current HP/MP enthalten. Base Stats und vollständige 3D-Szenen werden darin nicht dupliziert. Das Wiederherstellen trainierter Stats muss ausdrücklich vom Erzeugen eines neuen Monsters unterschieden werden. Es gibt noch keinen Serializer, keine Migration und keine vollständige Speicherfunktion.

Für Phase 2 sind vor der Begleiterintegration insbesondere festzulegen:

- Wer die aktive `MonsterInstance` über die frisch geladenen Waldsegmente hinweg besitzt. Der SceneManager soll weiterhin nur Szenen wechseln; die Monsteridentität darf beim Wechsel nicht neu entstehen.
- Welche Darstellung-/Bewegungskomponente die Definition instanziiert und dieselben individuellen Daten referenziert.
- Folgeabstand, Kollisionen, Hindernisfälle und benötigte logische Animationen.
- Prüfbare Abnahme für den ersten Begleiter. Pflege, Evolution und Zeit bleiben eigenständige spätere Schritte.

## Wiederholbare Tests

Im Projektverzeichnis mit der lokal installierten Godot-4.7.2-Binary ausführen:

```powershell
# Bei einem frischen Checkout zuerst Ressourcen und globale Klassen importieren:
& 'D:\godotinstall\Godot_v4.7.2-stable_win64.exe' --headless --path . --editor --import --quit
& 'D:\godotinstall\Godot_v4.7.2-stable_win64.exe' --headless --path . --script tests/test_monsters.gd --log-file .godot/monster_tests.log
& 'D:\godotinstall\Godot_v4.7.2-stable_win64.exe' --headless --path . --fixed-fps 60 --script tests/test_world_smoke.gd --log-file .godot/world_smoke.log
```

Andere Installationen verwenden denselben Aufruf mit ihrem Godot-Pfad. Beide Testtreiber beenden sich bei fachlichen Fehlern mit Exitcode 1. Sie verwenden kein zusätzliches Testframework. Temporäre Testresources werden ausschließlich unter `.godot/` angelegt und wieder entfernt; Sprache und Inputzustände werden nur für den laufenden Prozess geändert.

`test_monsters.gd` prüft Lookup, ungültige IDs und Typen, Enum, Identitäten, Initialisierung, isolierte Änderungen, kopierende Stat-Zuweisung, getrennte Vitalwerte, technische Grenzen und extrem große Deltas. Eine während des Tests neu gespeicherte Art wird ohne Codeänderung geladen; eine zweite Datei mit derselben Ressourcen-ID wird abgewiesen. Übersetzung und einfache visuelle Szenen werden ebenfalls geprüft.

`test_world_smoke.gd` prüft die vorhandene Waldlichtung, Bodenhaftung, feste Kamera, Bewegung, Menüpause und die echten Area3D-Wechsel A→B→A einschließlich Eintrittspunkten. Headless prüft Physik und Abläufe, nicht die Pixelqualität der 2.5D-Shader.

Ergebnis bei Implementierung: Monster-Tests **78 Prüfungen, 0 Fehler**; Welt-Regression **0 Fehler**. Erste Sandbox-Läufe bestanden fachlich, hatten jedoch Zugriffsfehler des bestehenden MCP-Plugins und des Windows-Zertifikatsspeichers. Die freigegebenen Wiederholungen außerhalb der Sandbox lieferten saubere Testprotokolle. Bestehende Szenen, Spielerskript, SceneManager, Einstellungen und Autoload-Konfiguration wurden nicht verändert.
