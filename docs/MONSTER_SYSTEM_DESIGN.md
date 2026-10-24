# Monster-System – Foundation und erster Begleiter

## Status und Abgrenzung

„Phase 1“ (Foundation) und „Phase 2“ (erster Begleiter) bezeichnen die technischen Monster-Arbeitspakete. Beide gehören zum ersten Schritt „Spielbarer Prototyp: Waldlichtung“ der [Projekt-Roadmap](ROADMAP.md); daraus folgt keine Abnahme der späteren Roadmap-Stufen.

**Implementiert, Phase 1:** Monsterarten als editierbare Resources, sieben Evolutionsstufen als Enum, sechs begrenzte Stats, unabhängige individuelle Monsterdaten, Current HP/MP, Laden per technischer ID, drei Testdefinitionen und wiederholbare Headless-Tests.

**Implementiert, Phase 2:** Ein zentral verwalteter Begleiter, einfache kollisionsgebundene Folgebewegung entlang der Spielerroute, Neuerzeugung der Weltinstanz bei Segmentwechseln mit Erhalt derselben Monsterdaten und ein visueller Adapter für `idle`/`walk`. Die vorhandenen Platzhalter besitzen keine Animationsclips; fehlende Clips sind ausdrücklich zulässig.

**Implementiert, Life & Care MVP 1:** Zentrale Weltzeit, individuelle Sättigung, Futterverweigerung, Hunger-/Überfütterungsereignisse, datenbasierte Lebensmittel, Inventar und Fütterungsdienst sowie getrennte Menüs, HUD und Entwickleroberfläche. Paketaufteilung, Testwerte und Erweiterungspunkte stehen zentral in [LIFE_CARE_MVP.md](LIFE_CARE_MVP.md).

**Nur geplant:** Attribut- und Elementwirkungen, wilde Monster, Gegner-/Bossverhalten, Training als Spielmechanik, weitere Pflegebedürfnisse, Evolution, Schlaf, biologisches Alter, Tod, weitere Animationen und Savegames. Die folgenden Typregeln und die Monster-Artstyle-Richtung sind verbindlich beschlossen; sie sind noch keine Gameplay-Implementierung oder fertigen Monsterassets.

Die verbindlichen Zukunftsentscheidungen dieses Dokuments ergänzen Game Design und Roadmap, ohne die betreffenden Systeme bereits zu implementieren. Noch fehlende Zahlen und Ereignisdefinitionen bleiben ausdrücklich offen.

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
| `idle_animation: StringName` | Artspezifischer Clipname für den logischen Zustand `idle`; Standard `idle`. |
| `walk_animation: StringName` | Artspezifischer Clipname für den logischen Zustand `walk`; Standard `walk`. |
| `initial_satiety: float` | Konfigurierbarer Startwert der individuellen Sättigung. |
| `satiety_decay_rate: float` | Sättigungsverlust pro Spielstunde. |
| `food_requirement: float` | Positiver Futterbedarfsfaktor für die Wirkung von Nahrung. |

Das zentrale Enum `MonsterDefinition.EvolutionStage` besitzt explizite Werte: `BABY=0`, `TRAINING=1`, `KID=2`, `TEEN=3`, `ADULT=4`, `ASCENDED=5`, `MASTER=6`. Vor späteren Savegames dürfen diese Werte nicht beiläufig umnummeriert werden. Es existiert noch keine Evolutionsprüfung.

Definitionen werden bewusst gemeinsam geladen. Sie sind zur Laufzeit **Konfiguration, keine Trainingsdaten**. Godot-Resources sind technisch veränderbar; diese Konvention ist keine allgemeine Schreibsperre. Insbesondere darf Spielcode nicht über `instance.definition.base_stats` trainieren. Die beiden grundlegenden Animationszuordnungen existieren seit Phase 2. Weitere Zuordnungen, Schlafrhythmen und Evolutionsregeln gehören später in die Artkonfiguration, sobald ihre konkrete Verantwortung feststeht.

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
- Eigene Sättigung, vorübergehende Futterverweigerung und Pflegeereignisse. Änderungen werden über Signale gemeldet; die Detailregeln stehen im Life-&-Care-Dokument.

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

### Attribute und Elemente

Attribute und Elemente sind zwei voneinander unabhängige Systeme. „Attribut“ bezeichnet hier Angst, Fable, Wish oder Unknown; die trainierbaren Werte HP, MP, ATK, DEF, SPEED und BRAIN heißen zur Unterscheidung **Stats**. Ein Attribut legt kein Element fest und umgekehrt. Die bestehende `MonsterDefinition` enthält noch keine Attribut- oder Elementfelder; die technischen Testarten erhalten durch diese Dokumentation keine Typzuweisung.

#### Attributvorteile

Ein Pfeil bedeutet einen offensiven Vorteil gegen das Zielattribut:

**Angst → Fable → Wish → Angst**

| Attribut | Vorteil gegen | Schwach gegen |
| --- | --- | --- |
| Angst | Fable | Wish |
| Fable | Wish | Angst |
| Wish | Angst | Fable |
| Unknown | Keine | Keine |

Unknown ist in beiden Richtungen attributneutral: Es hat weder attributbedingte Vorteile noch attributbedingte Nachteile.

#### Elementvorteile und abgeleitete Schwächen

Die 13 Elemente sind Fire, Water, Earth, Wind, Nature, Lightning, Ice, Light, Dark, Arcane, Machine, Poison und None. Die folgende Tabelle enthält die verbindlichen offensiven Vorteile. Die Spalte „Schwach gegen“ wird ausschließlich daraus abgeleitet: Steht A als Vorteil gegen B fest, ist B schwach gegen A.

| Element | Offensiv stark gegen | Schwach gegen |
| --- | --- | --- |
| Fire | Nature, Ice | Water, Earth |
| Water | Fire, Earth | Nature, Lightning, Poison |
| Earth | Fire, Lightning, Wind | Water, Nature |
| Wind | Poison, Arcane | Earth, Ice |
| Nature | Water, Earth | Fire, Arcane, Poison |
| Lightning | Water, Machine | Earth |
| Ice | Wind | Fire, Machine |
| Light | Dark | Dark |
| Dark | Light | Light |
| Arcane | Machine, Nature | Wind, Machine |
| Machine | Arcane, Ice, Poison | Lightning, Arcane |
| Poison | Nature, Water | Wind, Machine |
| None | Keine | Keine |

None ist in beiden Richtungen elementneutral. Nicht aufgeführte offensive Paarungen gewähren keinen Elementvorteil; daraus entstehen keine zusätzlichen Resistenzen oder Immunitäten. Gegenseitige Vorteile wie Light/Dark und Arcane/Machine bleiben ausdrücklich bestehen: Beide Angriffsrichtungen haben den jeweiligen Vorteil.

Die Neutralität gilt jeweils innerhalb des eigenen Systems: Unknown hebt keine Elementwirkung auf, None hebt keine Attributwirkung auf. Zahlenwerte für Vorteile, die rechnerische Kombination beider Systeme sowie mögliche Mehrfachtypen sind noch nicht festgelegt und werden hier nicht vorweggenommen.

#### Visuelle Referenz und Verbindlichkeit

Das Typechart-Mockup liegt unter [mocks/types.png](../mocks/types.png) (in der Aufgabenbeschreibung als `mocks/typesmock` bezeichnet). Es dient als visuelle Referenz für die tabellarische Darstellung, Elementicons und den getrennten Attributkreislauf. Es ist **keine technische Datenquelle**. Verbindlich sind ausschließlich die hier dokumentierten Regeln; abweichende Symbole, Pfeile, Legenden oder Texte im Bild ändern sie nicht. Insbesondere bedeutet eine neutrale Paarung keine Schadensimmunität, auch wenn die Mockup-Legende „No effect“ zeigt.

### Monster-Artstyle und Toxipad

Die verbindliche Artstyle-Referenz für zukünftige Monster ist [mocks/monster/prototypemonster1.png](../mocks/monster/prototypemonster1.png) (ursprünglich als `mocks/monster/prototypmonster` bezeichnet). [Prototyp 2](../mocks/monster/prototypemonster2.png) bleibt ebenfalls eine visuelle Designreferenz; beide ersetzen keine bestehende technische Monsterart.

Die Zielrichtung ist eine **modernisierte PS1-3D-Monsterästhetik**, inspiriert vom Spielgefühl von Digimon World 1, mit eigenständigen Kreaturendesigns. Die Referenz konkretisiert dies durch klar lesbare Silhouetten, markante Proportionen, sichtbare kantige 3D-Formen und ausdrucksstarke Farbkontraste. Diese Richtung gilt für zukünftige Monstermodelle; die vorhandenen technischen Primitive sind weiterhin Platzhalter. Aus dem Bild werden keine verbindlichen Polygonzahlen, Texturauflösungen, Shader oder Animationsvorgaben abgeleitet.

**Toxipad** ist ein grüner Giftfrosch mit lila Augen, lila Krallen und Stacheln, einer langen Zunge und markanten Proportionen. Er ist ein potenzieller Starter und Maskottchen-Kandidat. Der Name ist vorläufig; weder Starterrolle noch Maskottchenrolle sind endgültig entschieden. Das Konzept ist dem Element Poison zugeordnet; ein Attribut aus Angst/Fable/Wish/Unknown ist noch nicht festgelegt.

Toxipad ist bislang eine Designreferenz, keine implementierte Monsterdefinition, kein neues Modell und kein Ersatz für den aktuellen Testbegleiter. Größen-, Gewichts- und Attackenangaben der Referenzbilder bleiben Mockup-Inhalte, solange sie nicht gesondert beschlossen werden. Gleiches gilt für andere dort abgebildete Kreaturen.

### Stats, Training und Evolution

- Die sechs Stats bleiben HP, MP, ATK, DEF, SPEED und BRAIN. Training verändert individuelle Werte.
- Evolution erhält trainierte Stats grundsätzlich; eine Evolution darf daher nicht einfach eine neue Instanz aus den Base Stats der Zielart erzeugen.
- Permanente Evolutionsboni und -abzüge sollen standardmäßig additiv angewendet werden. Multiplikative Modifikatoren sollen später möglich sein, ohne mehrere widersprüchliche Kopien effektiver Stats zu pflegen.
- Die sieben Stufen folgen Baby → Training → Kid → Teen → Adult → Ascended → Master.
- Verzweigte Evolutionen verwenden datengetriebene Bedingungen: Stats, Alter, Pflegefehler, Happiness, Discipline und weitere Faktoren.
- Fehlentwicklungen können individuelle Stats reduzieren. Konkrete Boni, Bedingungen, Reihenfolge bei mehreren Treffern und Grenzwerte sind noch offen.

### Vitalwerte und Pflege

Hunger ist im MVP als Sättigung umgesetzt; hoher Wert bedeutet satt. Füttern sowie STARVATION- und OVERFEEDING-Ereignisse sind implementiert. Pflegefehler werden separat mit Ursache, Weltzeitpunkt und Instanz-ID gespeichert. Regeln, Grenzen und vorläufige Werte stehen in [LIFE_CARE_MVP.md](LIFE_CARE_MVP.md). Fatigue, Happiness, Discipline, Poopmeter und Krankheiten bleiben geplant. Current HP/MP existieren; Regeneration, Verbrauch und K.-o.-Folgen sind noch nicht simuliert.

### Leben und Tod

Standardmäßig tritt Tod nach dem **dritten relevanten K. o.** ein. Was ein relevanter K. o. ist und welche Sonderfälle gelten, muss vor dieser Mechanik präzisiert werden. Natürlicher Tod durch biologisches Alter ist ein separater Auslöser. Noch kein K.-o.-Zähler, biologisches Alter oder Todes-/Wiedergeburtssystem vorhanden.

### Zeit und Schlaf

Reale Zeit, Weltzeit und biologisches Alter sind verschiedene Konzepte. Die zentrale Weltzeit ist implementiert: eine reale Minute entspricht einer Spielstunde; Pausen und Segmentübergänge erzeugen keinen normalen Fortschritt. Explizite Vorwärtsintervalle aktualisieren die Sättigung auch bei Zeitsprüngen. Regionale Faktoren sind technisch konfigurierbar; regionale Regeln und biologisches Alter sind nicht simuliert. Training kann später explizit Weltzeit verbrauchen.

Es gibt keinen numerischen Sleepiness-Wert. Jede Art soll einen zeitbasierten Schlafrhythmus mit konfigurierbarer Schlafenszeit und Schlafdauer besitzen. Verspäteter Schlaf verschiebt grundsätzlich auch die Aufwachzeit. Fatigue und Schlafbedürfnis sind voneinander unabhängig. Schlafrhythmen und Schlafzustände sind noch nicht implementiert.

### Monsterrollen, Modelle und Animationen

Begleiter, wilde Monster, Gegner und Bosse verwenden dieselben Definitionen. Rollen entstehen durch austauschbare Verhaltenskomponenten; keine Vererbungsbäume pro Monsterart. Die individuelle Dateninstanz bleibt unabhängig von CharacterBody, Modellknoten, Skelett und konkreten Animationen.

`MonsterVisual` setzt seit Phase 2 die grundlegenden logischen Zustände `idle` und `walk` um. Weitere Zustände sind noch nicht festgelegt. Die Komponente kennt keine konkreten Skelette oder Monsterarten.

## Phase 2: aktiver Begleiter und Weltinstanz

`CompanionManager` (`scripts/monsters/companion_manager.gd`) ist ein schlanker zusätzlicher Autoload. Er hält genau eine `active_monster: MonsterInstance` im Arbeitsspeicher und eine Referenz auf den aktuellen `CompanionFollower`. Der Standard ist die vorhandene Definition `drako`, konfiguriert durch `default_monster_id`. Erst eine Szene mit lokalem `Player` in der Gruppe `player` benötigt und erzeugt den Begleiter.

Die Szenen und der SceneManager enthalten keine Begleiter-Sonderlogik. Der Manager hört auf `SceneTree.scene_changed`, wartet auf Physikregistrierung und Spielerplatzierung und hängt die wiederverwendbare Szene `scenes/monsters/companion.tscn` an das aktuelle Segment. Die vorige Szene entfernt ihren Körper beim Entladen. Erneutes Anfordern in derselben Szene erzeugt keinen zweiten Körper. Während der bestehenden Übergangsblende pausiert der Controller seine Bewegung.

Die Weltinstanz enthält nur Körper, Collider, Verhaltenskomponente und visuelle Komponente. Sie referenziert dieselbe zentrale MonsterInstance. Individuelle Stats, Current HP/MP und Instanz-ID werden beim Szenenwechsel nicht kopiert oder neu erzeugt. Das ist Erhalt innerhalb der laufenden Spielsitzung, **kein Savegame-System**.

### Folgebewegung und sichere Positionierung

`CompanionFollower` (`scripts/monsters/companion_follower.gd`) verwendet `CharacterBody3D`, Schwerkraft und `move_and_slide()`. Die konfigurierbaren Ausgangswerte sind 1,5 Einheiten Folgeabstand, 0,08 Wiederanlaufreserve, 4,5 Einheiten/Sekunde normales Lauftempo und ein Annäherungsfaktor von 4 pro Sekunde. `acceleration = 9.0` Einheiten/Sekunde² ergibt etwa 0,5 Sekunden vom Stillstand bis zum normalen Lauftempo. `deceleration = 14.0` steuert das Abbremsen separat. `catch_up_speed = 6.0` begrenzt die Aufholgeschwindigkeit: Ab `catch_up_distance = 1.0` Einheiten Rückstand zum **verzögerten** Ziel wird das Geschwindigkeitslimit linear erhöht; beim doppelten Rückstand ist das Maximum erreicht. Ein niedrigerer Aufholwert reduziert nicht das normale Lauftempo. Diese technischen Bewegungsparameter sind unabhängig vom trainierbaren SPEED-Stat; eine spätere Zuordnung wäre eine eigene Spielregel.

Der Controller zeichnet pro Physikschritt Spielerpositionen mit lokaler Simulationszeit auf. `follow_delay = 1.0` Sekunden ist im Inspector konfigurierbar (0 bis 3 Sekunden). Interpolation liefert Position und Bewegungsrichtung zum Zeitpunkt `jetzt - follow_delay`; jüngere Daten werden niemals als Bewegungsziel oder Abkürzung verwendet. Menüpausen und Übergangsblenden lassen diese Uhr ruhen. Beim Erzeugen wird die bekannte Eintrittsposition als Vorgeschichte eingetragen: Ein entfernter Begleiter kann sofort zum Eintrittspunkt laufen, ohne zusätzliche Startsperre. Laufende Änderungen des Delay-Werts benötigen bei einer Erhöhung zunächst neue Historie; für reproduzierbare Konfiguration vor `configure()` setzen.

Nur freigegebene ältere Positionen werden im Abstand von 0,18 Einheiten in die Hindernisspur übernommen. Eine Capsule-Sweep-Prüfung mit Körperbreite erlaubt freie Verbindungen zum verzögerten Ziel oder zu älteren erreichbaren Wegpunkten. Sie kann veraltete Umwege überspringen, aber keine zukünftige Richtungsänderung vorwegnehmen. Die Suche ist begrenzt; die Hindernisspur bleibt auf 512 Punkte beschränkt. Die Zeitspur entfernt fortlaufend nicht mehr benötigte Einträge.

Bei freier Verbindung berücksichtigt die gewünschte Geschwindigkeit ausschließlich die zeitversetzte Bewegung. Der Laufabstand entsteht aus Tempo und Verzögerung; der bisherige Folgeabstand wird beim Anhalten zum persönlichen Ruheabstand eingeblendet, statt zusätzlich zur Sekunde Laufverzögerung aufaddiert zu werden. Eine kurze Vorausprüfung verhindert seitliches Einlenken in einen Felsen. Beschleunigungsgrenze, proportionale Annäherung, Bremsweg und Schrittweitenbegrenzung beruhigen die Bewegung. Kleine Ruhetoleranz und getrennte Walk-/Idle-Schwellen vermeiden numerisches Zittern. Die Blickrichtung verwendet exponentielle, von `delta` abhängige Glättung. Kollisionen oder Aufholen nach Hindernissen können den tatsächlichen Abstand vorübergehend vergrößern; die Sekunde ist kein erzwungener Teleport-Zeitplan.

Es gibt weiterhin genau eine horizontale Geschwindigkeitsintegration mit `move_toward(..., rate * delta)`. Sinkendes Solltempo und Richtungsumkehr verwenden die Bremsstärke, sonst gilt die Beschleunigung. Die Annäherung berechnet die zulässige Geschwindigkeit aus derselben Bremsstärke inklusive einer Physikschritt-Reserve. Richtungswechsel glätten sich innerhalb dieser bestehenden Integration; es gibt keine zweite Bewegungssteuerung oder zusätzliche Pause an jedem Spurpunkt. Die langsamere Anlauframpe darf den tatsächlichen Zeitabstand kurz etwas über die konfigurierte Sekunde erhöhen.

Die Sweep-Prüfung hebt den Collider um 0,05 Einheiten an, damit Bodenkontakt auf den vorhandenen flachen Segmenten keine freien Strecken fälschlich blockiert. Sie ersetzt keine allgemeine Prüfung von Abgründen oder komplexen Höhenverläufen. Gegenüber einem dünnen Sichtstrahl berücksichtigt sie den benötigten Abstand zu Felskanten und Wänden. Kein Navmesh, A*, Teleport-Nachholen oder neues Navigationssystem wurde eingeführt.

Der Manager sucht beim Eintritt in ein Segment acht nahe Kandidatenpositionen. Bodenprüfung, Capsule-Überlappungstest und Sichtprüfung zum Spieler vermeiden Spawns im Felsen, auf dessen Dach oder jenseits der Randkollisionen. Die Füßhöhe wird anhand der aktuellen Spieler-Konvention (Root 0,9 Einheiten über Boden) bestimmt. Der gemeinsame Collider hat Radius 0,3 und Höhe 1,2; künftige deutlich andere Körpergrößen benötigen bewusst abgestimmte Collider.

Der Begleiter verwendet Kollisionslayer 2 und prüft die bestehende Welt auf Layer 1. Der unveränderte Spieler prüft Layer 1 und wird somit nicht vom Begleiter blockiert. Die Area3D-Ausgänge prüfen Layer 1 und akzeptieren zusätzlich nur die Gruppe `player`. Der Begleiter gehört ausschließlich zur Gruppe `companion` und kann deshalb selbst keinen Segmentwechsel auslösen.

### Modelle und Animationen

`MonsterVisual` (`scripts/monsters/monster_visual.gd`) instanziiert ausschließlich `definition.visual_scene`, erwartet eine Node3D-Wurzel und verwendet gegebenenfalls den ersten enthaltenen `AnimationPlayer`. `idle_animation` und `walk_animation` der Definition bilden logische Zustände auf beliebige Clipnamen ab. Ein fehlender Walk-Clip fällt auf vorhandenes Idle zurück; fehlen auch Idle beziehungsweise AnimationPlayer, bleibt das Modell ohne Fehler statisch. Vorhandene Assets konfigurieren Schleifen selbst; gemeinsam genutzte Animation-Resources werden nicht verändert.

`set_walking()` wird aus der tatsächlich erzielten horizontalen Körperbewegung angesteuert, damit ein durch Kollision gestoppter Begleiter nicht weiter als laufend behandelt wird. Mehrere AnimationPlayer, AnimationTree-Steuerungen und fortgeschrittene Zustände sind noch nicht Gegenstand dieser Schnittstelle.

### Andere Art oder vorhandene Instanz einsetzen

```gdscript
var companions := get_node("/root/CompanionManager")
companions.select_species(&"slimo")
```

Dies lädt eine andere Definition und erzeugt bewusst eine neue MonsterInstance. Erneute Auswahl derselben Art erhält dagegen die aktuelle Instanz. Die Weltinstanz wird bei Bedarf asynchron nach der nächsten Physikregistrierung erzeugt; unmittelbar nach dem Aufruf kann `get_actor()` noch `null` liefern.

Bereits vorhandene individuelle Monster können mit `companions.set_active_monster(existing_instance)` eingesetzt werden. Für einen anderen Standard beim Spielstart `default_monster_id` ändern. Weder Controller noch visuelle Komponente enthalten artspezifische Fallunterscheidungen. Ungültige IDs liefern `false` und eine technische `last_error`-Diagnose; der aktive Begleiter bleibt erhalten. Die API ist keine Evolution und kein neues Auswahlmenü.

## Persistenzvorbereitung und weitere Schritte

Ein späterer Datensatz soll mindestens Savegame-Schemaversion, technische Art-ID, Instanz-ID, individuelle Stats und Current HP/MP enthalten. Base Stats und vollständige 3D-Szenen werden darin nicht dupliziert. Das Wiederherstellen trainierter Stats muss ausdrücklich vom Erzeugen eines neuen Monsters unterschieden werden. Es gibt noch keinen Serializer, keine Migration und keine vollständige Speicherfunktion.

Für weitere Schritte offen bleiben echte Animationsassets, weitere logische Zustände, artspezifische Körpergrößen sowie die Behandlung wesentlich komplexerer oder dynamischer Hindernisse. Die einfache Wegpunktspur ist kein allgemeiner Wegfinder und behandelt manuelle Teleports innerhalb desselben Segments nicht automatisch. Pflege, Evolution und Zeit bleiben eigenständige spätere Schritte.

## Wiederholbare Tests

Im Projektverzeichnis mit der lokal installierten Godot-4.7.2-Binary ausführen:

```powershell
# Bei einem frischen Checkout zuerst Ressourcen und globale Klassen importieren:
& 'D:\godotinstall\Godot_v4.7.2-stable_win64.exe' --headless --path . --editor --import --quit
& 'D:\godotinstall\Godot_v4.7.2-stable_win64.exe' --headless --path . --script tests/test_monsters.gd --log-file .godot/monster_tests.log
& 'D:\godotinstall\Godot_v4.7.2-stable_win64.exe' --headless --path . --fixed-fps 60 --script tests/test_world_smoke.gd --log-file .godot/world_smoke.log
& 'D:\godotinstall\Godot_v4.7.2-stable_win64.exe' --headless --path . --fixed-fps 60 --script tests/test_companion.gd --log-file .godot/companion_tests.log
& 'D:\godotinstall\Godot_v4.7.2-stable_win64.exe' --headless --path . --fixed-fps 60 --script tests/test_companion_motion.gd --log-file .godot/companion_motion.log
& 'D:\godotinstall\Godot_v4.7.2-stable_win64.exe' --headless --path . --fixed-fps 60 --script tests/test_companion_delay.gd --log-file .godot/companion_delay.log
```

Andere Installationen verwenden denselben Aufruf mit ihrem Godot-Pfad. Alle Testtreiber beenden sich bei fachlichen Fehlern mit Exitcode 1. Sie verwenden kein zusätzliches Testframework. Temporäre Testresources werden ausschließlich unter `.godot/` angelegt und wieder entfernt; Sprache und Inputzustände werden nur für den laufenden Prozess geändert.

`test_monsters.gd` prüft Lookup, ungültige IDs und Typen, Enum, Identitäten, Initialisierung, isolierte Änderungen, kopierende Stat-Zuweisung, getrennte Vitalwerte, technische Grenzen und extrem große Deltas. Eine während des Tests neu gespeicherte Art wird ohne Codeänderung geladen; eine zweite Datei mit derselben Ressourcen-ID wird abgewiesen. Übersetzung und einfache visuelle Szenen werden ebenfalls geprüft.

`test_world_smoke.gd` prüft die vorhandene Waldlichtung, Bodenhaftung, feste Kamera, Bewegung, Menüpause und die echten Area3D-Wechsel A→B→A einschließlich Eintrittspunkten. Headless prüft Physik und Abläufe, nicht die Pixelqualität der 2.5D-Shader.

`test_companion.gd` prüft Folgen, Stillstand, Vergleich bei 30/60/120 Physikschritten pro Sekunde, eine Route um den vorhandenen Testblock, sicheren Boden, Drako und Slimo, Animation-Mappings mit synthetischen Clips, fehlende Clips, fehlenden AnimationPlayer, doppelte Erzeugungsanforderungen und Begleiterwechsel. A→B→A bewahrt dieselbe MonsterInstance einschließlich individuell geänderter Stats und Vitalwerte. Menüpause und das Ignorieren des Begleiters durch Ausgänge sind ebenfalls geprüft. Der Walk-Zustand wird während der Spielerbewegung geprüft; er muss nach dem schnelleren Abbremsen nicht künstlich weiterbestehen.

`test_companion_motion.gd` umfasst 52 Prüfungen für Anlauframpe, begrenztes Aufholen, Beschleunigungs-/Bremsgrenzen, fehlendes Überschwingen und Gegenkorrekturen, verzögerten Start, Stillstand, Kurven und die Testblockroute bei 30/60/120 Physikschritten. Die bestehenden Hindernisgrenzen wurden beibehalten. Gemessen: Start nach 1,03–1,05 Sekunden, maximal 6 Einheiten/Sekunde beim Aufholen, kein Überschwingen am ruhenden Ziel, kein Rückwärtslaufen auf gerader Strecke, keine Positionsdrift in Ruhe, Hindernisroute ohne Stillstandsphasen und Stillstand etwa 1,17–1,18 Sekunden nach Ende der Spielerroute.

`test_companion_delay.gd` ergänzt 24 Prüfungen: gemessene Wegmarken-Verzögerung für 0,5/1,0/1,5 Sekunden, zeitversetztes Abbiegen, lange Ruhephase und sofortige Annäherung eines entfernten Spawns bei 30/60/120 Physikschritten. Für `follow_delay = 1.0` wurde die Wegmarke mit der sanften Anlauframpe etwa 1,07–1,12 Sekunden später passiert; die erkennbare Nordbewegung nach einem 90°-Knick begann nach 1,20–1,23 Sekunden. Aktueller Stand: Delay **24/0**, Bewegung **52/0**, Begleiter **47/0**, Foundation **78/0**, Welt-Regression **0 Fehler**. Diese Messungen beziehen sich auf die definierten Szenarien, nicht jede Hinderniskonstellation.

Die letzten Bewegungsanpassungen betreffen Controller, Tests und Bewegungsdokumentation. Monsterdatenmodell, CompanionManager, Spieler, Kamera, Waldszenen und Szenenwechsel wurden dabei nicht verändert. Die vorliegenden Testprotokolle ergeben insgesamt **201 Einzelprüfungen ohne Fehler** zuzüglich der erfolgreichen Welt-Regression.

Die weichere Variante wurde zusätzlich über Godot MCP im regulären gerenderten Spiel geprüft: Ein entfernter Begleiter beschleunigte innerhalb von 0,28 Sekunden auf etwa 2,55 Einheiten/Sekunde. Die anschließende Route rechts um den Testblock mit zwei Richtungswechseln führte hinter das Hindernis und danach zum ruhigen Stillstand. Die vollständige Prüfung aller drei Physikraten erfolgt reproduzierbar durch die Headless-Tests. Für diese Spielprüfung waren keine temporären Diagnosemethoden nötig.
