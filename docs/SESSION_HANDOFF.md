# FantasyMon — kompakte Session-Übergabe

Stand: 2026-10-24. Prüfbasis: `da5ce5a` nach Merge von `feature/first-companion`.
Orientierung für neue Sessions; Code und verbindliche Fachdokumente bleiben maßgeblich.
Git-Angaben und Testergebnisse sind Snapshots, keine dauerhafte Live-Auskunft.

Kennzeichnungen:
- **IMPLEMENTED:** im Code/Resources nachgewiesen.
- **DECIDED:** ausdrücklicher Projektbeschluss; Quelle jeweils angegeben.
- **PROPOSED:** noch nicht bestätigte Idee/Empfehlung.
- **OPEN:** ungeklärt oder ohne hinreichenden Beschlussbeleg.

## 1. Projektüberblick und aktueller Entwicklungsstand

- **IMPLEMENTED:** Godot 4.7.2 / GDScript, Monster-Raising-RPG-Prototyp unter Windows.
  Zwei Waldsegmente, ein Begleiter sowie Life & Care MVP 1 sind spielbar.
- **DECIDED:** Feste Kameras und eine 2.5D-Welt mit vorgerenderten Hintergründen und
  echten 3D-Figuren/Kollisionen; eigenständige Designs, inspiriert von Digimon World 1.
  Quellen: [Game Design](GAME_DESIGN.md), [Architektur](ARCHITECTURE.md).
- **IMPLEMENTED:** Nur `forest_clearing.tscn` nutzt einen gebackenen PNG-Hintergrund
  mit 3D-Verdeckung; `forest_path.tscn` bleibt eine 3D-Testszene. Ausgabe 16:9 mit Balken.
- **OPEN:** Roadmap-Schritt 1 ist nicht vollständig abgenommen (u. a. echte Animationen);
  Schritt 2 enthält die Versorgungsschleife, aber noch kein Training. Monster-Phasen
  1/2 sind technische Arbeitspakete, keine abgeschlossenen offiziellen Roadmap-Stufen.

## 2. Relevante Architektur und zentrale Komponenten

Autoload-Liste: `project.godot`; Details nur bei Bedarf in [ARCHITECTURE.md](ARCHITECTURE.md).

| Komponente | Verantwortung / Einstieg |
| --- | --- |
| MonsterDefinition / MonsterStats | Artkonfiguration und Base Stats; `scripts/monsters/monster_definition.gd`, `monster_stats.gd`; editierbare `.tres` unter `data/monsters/definitions/`. |
| MonsterInstance | Individuelle kopierte Stats, HP/MP, Sättigung, Verweigerung, Pflegeereignisse; `scripts/monsters/monster_instance.gd`. |
| MonsterRegistry | ID-basierter, geteilter Definitions-Cache; `scripts/monsters/monster_registry.gd`; kein Autoload. |
| CompanionManager / Follower / Visual | Eine aktive Dateninstanz; je Szene neuer Körper und Modell aus Definition; `scripts/monsters/companion_*.gd`, `monster_visual.gd`. |
| SceneManager / SegmentExit | Frisches Laden, Fade und Marker3D-Eintrittspunkte; `scripts/scene_manager.gd`, `segment_exit.gd`. |
| WorldTime / LifeCare | Zentrale Zeitintervalle und Fortschreibung des aktiven Monsters; `scripts/life/world_clock.gd`, `life_care_service.gd`. |
| PlayerInventory / Inventory / FeedingService | Sitzungsinventar, Stapel und UI-unabhängige Fütterung; `scripts/items/`; Katalog `data/items/catalog.tres`. |
| Menus / GameMenus / GameHud | Eine Menü-/Pausenkoordination, getrennte Views, signalgesteuertes HUD; `ui/menu_coordinator.gd`, `ui/game/`. |
| GameSettings / TranslationServer | Einstellungen unter `user://settings.cfg`, EN/DE-Texte; `scripts/game_settings.gd`, `translations/strings.csv`. |

**DECIDED:** Veränderliche Daten von Darstellung und Artdefinition trennen;
Komposition, datenbasierte Konfiguration und kleine Verantwortlichkeiten bevorzugen.
Kein Event-Bus/ECS oder Monster-Sondercode nötig. Quelle: Architektur und freigegebener MVP.

## 3. Implementierte Funktionen

- **IMPLEMENTED:** Technische Arten Drako, Slimo, Fenri; sechs Stats HP/MP/ATK/DEF/
  SPEED/BRAIN; sieben Evolutionsstufen als Enum, noch keine Evolutionssimulation.
- **IMPLEMENTED:** Genau ein aktiver Begleiter; Identität und individuelle Werte bleiben
  bei Segmentwechseln erhalten. Spielerbewegung bleibt kamerarelativ und frei belegbar.
- **IMPLEMENTED:** Zeitgestempelte Route mit `follow_delay = 1.0`, sanftem Anlaufen
  (ca. 0,5 s), separater Bremsung, begrenztem Aufholen und Capsule-geprüften Abkürzungen.
  Nur bereits freigegebene ältere Punkte werden verfolgt. Keine allgemeine Navigation.
- **IMPLEMENTED:** Weltzeit: 1 reale Minute = 1 Spielstunde, 24 Stunden/Tag. Normale
  Zeit ruht bei Menüpause/Segmentwechsel; kein Offline-Fortschritt. Explizite Sprünge
  aktualisieren Sättigung; biologische Alterung ist davon getrennt und nicht implementiert.
- **IMPLEMENTED:** Sättigung 0..100; satt ab 80. Wirkung von Nahrung ist deren
  Sättigungswert geteilt durch `food_requirement`; artspezifischer Verlust pro Spielstunde.
- **IMPLEMENTED:** STARVATION einmal pro Hungerphase beim simulierten Erreichen von 0,
  auch durch reguläre Zeitsprünge; erfolgreiche Versorgung ermöglicht eine neue Phase.
  Pflegeereignisse enthalten Ursache, Weltzeit und Monsterinstanz-ID und bleiben intern.
- **IMPLEMENTED — aktuelle Überfütterungsregel:** Rechnerisches Ergebnis >100 gilt
  als erfolgreiche Fütterung, begrenzt Sättigung auf 100, registriert OVERFEEDING und
  sperrt Futter bis strikt unter 80. Abgelehnte Versuche verbrauchen nichts und
  erzeugen keine weiteren Fehler. Diese Regel ist noch nicht überarbeitet.
- **IMPLEMENTED:** Small Meat, Apple und Mushroom als Resources; Stapelinventar mit
  Kapazitätsprüfung. Alle normalen Lebensmittel sind für alle Arten möglich.
  Parameter, 20 Slots und Anfangsmengen sind vorläufige MVP-Testwerte, keine finale Balance.
- **IMPLEMENTED:** Fütterungsfix aus `ed06709`: `Inventory.consume_if()` reserviert,
  prüft `receive_food()` und rollt bei Ablehnung die exakten Stapel zurück. Schutz
  gegen Signal-Reentranz und numerischen Unterlauf; keine Gewichtsfunktion ergänzt.
- **IMPLEMENTED:** Separate Inventar-/Pflege-/Status-/Settings-Menüs; F1/F2/F3/F4,
  ESC zurück/schließen; F12 Debug. Gemeinsame Pause, EN/DE und HUD-Anzeigeoptionen.
  Debug trennt direktes Setzen von regulärer Simulation. Details: [Life & Care](LIFE_CARE_MVP.md).

## 4. Beschlossene, aber noch nicht implementierte Funktionen

Folgende **DECIDED**-Regeln stammen aus [MONSTER_SYSTEM_DESIGN.md](MONSTER_SYSTEM_DESIGN.md):
- Fatigue, Happiness, Discipline, Poopmeter und Krankheiten; Zahlen und Auswirkungen offen.
- Kein Sleepiness-Stat. Artspezifischer Schlafrhythmus; spätes Einschlafen verschiebt
  grundsätzlich die Aufwachzeit. Fatigue und Schlafbedürfnis bleiben unabhängig.
- Reale Zeit, Weltzeit und biologisches Alter bleiben verschieden. Regionale Faktoren
  sind technisch vorbereitet; regionale Spielregeln/Alterssimulation fehlen.
- Baby → Training → Kid → Teen → Adult → Ascended → Master; datengetriebene,
  verzweigte Evolutionen. Trainierte Stats grundsätzlich erhalten; permanente Boni/
  Abzüge standardmäßig additiv, multiplikative Modifikatoren später möglich.
- Tod standardmäßig nach drittem relevantem K. o.; Alterstod separat. Definition von
  relevantem K. o., Lebensspanne und weitere Details offen; keine Todesmechanik vorhanden.
- Unabhängige Attribute Angst → Fable → Wish → Angst, Unknown neutral; Elementchart
  im Monsterdokument verbindlich. Noch keine Typfelder/Kampfwirkungen implementiert.
- Eigenständige modernisierte PS1-3D-Monsterästhetik. Toxipad und Prototyp 2 bleiben
  visuelle Referenzen, keine neuen technischen Arten. Toxipad als Starter/Maskottchen
  ist nur Kandidat; vorläufiger Name. Bildgewichte sind keine beschlossenen Regeln.

Zusätzlich **DECIDED**, ausdrücklich vom Projektverantwortlichen in der
Übergabekorrektur vom 2026-10-24 bestätigt; noch nicht implementiert:
- **Monstergewicht:** Jede Art erhält ein Basisgewicht in Kilogramm. Beim Erstellen
  beziehungsweise Schlüpfen wird das individuelle Gewicht auf dieses Basisgewicht gesetzt.
- Nahrung kann das Gewicht unmittelbar erhöhen, unabhängig von der Sättigung.
- Bei jeder Evolution wird das Gewicht auf das Basisgewicht der neuen Art
  zurückgesetzt, unabhängig vom vorherigen Gewicht.
- Gewichtsreduktion durch Aktivitäten und Gewichtsanforderungen für Evolutionen
  sind spätere Erweiterungen; ihre konkreten Regeln bleiben offen.
- **Überfütterung — Variante B:** Erst wiederholtes Überfüttern soll einen
  Pflegefehler auslösen. Die derzeit implementierte Mechanik aus Abschnitt 3 bleibt
  unverändert, bis die neue Regel separat implementiert wird.

## 5. Offene Entscheidungen und Vorschläge

- **OPEN — Gewicht:** Konkrete Basisgewichte und Gewichtsbeiträge der Lebensmittel
  sind noch nicht festgelegt. Regeln zur späteren Gewichtsreduktion durch Aktivitäten
  und zu Gewichtsanforderungen für Evolutionen müssen gesondert abgestimmt werden.
- **OPEN — Variante B:** Genaue Anzahl beziehungsweise konkreter Auslösezeitpunkt,
  Zurücksetzen der Zählung und Details der Nahrungsverweigerung sind noch abzustimmen.
  Die Entscheidung für wiederholtes Überfüttern ist bestätigt; die Detailregeln nicht.
- **OPEN:** Weitere Pflegeparameter, Training, konkrete Evolutionsbedingungen,
  Savegame-Format, weitere Regionen, finale Modelle/Animationen und Balance.
- **PROPOSED:** Die offenen Werte und Detailregeln vor Implementierung gemeinsam
  klären; danach ein kleines datenbasiertes Arbeitspaket mit Grenzfalltests planen.
  Dies ist eine Empfehlung, keine beschlossene neue Gameplay-Regel.

## 6. Bekannte Probleme und technische Einschränkungen

- **IMPLEMENTED / Grenze:** Nur aktiver Begleiter wird gepflegt; kein Roster-/Offline-
  System und keine Savegames. Monster/Inventar überstehen Szenenwechsel, nicht Spielende.
- **IMPLEMENTED / Grenze:** Platzhaltermodelle haben keine echten Animationsclips;
  `idle`/`walk`-Schnittstelle toleriert das. Komplexe/dynamische Hindernisse, Teleports
  im Segment und Höhenverläufe sind nicht allgemein gelöst. Nur ein Verdeckungs-Testblock.
- **OPEN / Testgrenze:** Windows-Release-EXE nicht getestet: 4.7.2-Exporttemplates
  fehlen laut letztem Exportversuch. Paketstart ist kein nativer Release-EXE-Test.
- **IMPLEMENTED / Exportnachweis:** Preset schließt `dev/*`, `tests/*` und MCP aus.
  Toolkit-Exportplugin entfernt den MCP-Autoload im Paket und stellt ihn im Editor
  wieder her. Vorheriger isolierter Paketstart: 10/0; Entwicklung per MCP bestätigt.
  Pakettests müssen aus leerem Arbeitsverzeichnis laufen, sonst können Source-Dateien
  fehlende Paketdateien überdecken. Keine Toolkit-Deaktivierung als Standardlösung.
- **OPEN / Dokumentationsdrift:** Life-&-Care-Dokument nennt noch den MVP-Nachweis
  70/0; nach Fütterungsfix sind zuletzt 80/0 belegt. Der Satz „Pflege, Evolution und
  Zeit bleiben ... spätere Schritte“ im Monsterdokument ist für Pflege/Zeit zu pauschal.
  Hier nur vermerkt; vorhandene Fachdokumente wurden in dieser Skill-Aufgabe nicht geändert.
- **OPEN / Werkzeughinweis:** Skill-Creator-Validator benötigt PyYAML; zuletzt lokal
  nicht verfügbar. Keine neue Abhängigkeit installieren, nur um diesen Skill zu laden.

## 7. Aktueller Git-Stand

- Snapshot bei Beginn der Skill-Erstellung: `feature/project-context-skill`, HEAD `da5ce5a`;
  Arbeitsbaum sauber. Kein Upstream für diesen neuen lokalen Branch angezeigt.
- `da5ce5a`: Merge-Commit zu PR #3, Eltern `8ec23a1` und `ed06709`.
  `feature/first-companion` mit Fütterungsfix ist damit in `main` enthalten.
- Lokale Referenzen `main` und `origin/main` zeigen auf `da5ce5a`; kein Fetch erfolgt,
  daher keine Aussage über einen seitdem veränderten Serverstand.
- Aus der Skill-Erstellung sind AGENTS.md, Skill und Übergabe weiterhin lokale,
  nicht committete Änderungen. Diese Korrektur ändert nur die Übergabe; keine
  Branchwechsel, Commits, Pushes, Merges oder PRs durch diesen Auftrag.
- Bei LOAD immer neu prüfen: Branch/HEAD nicht als dauerhafte Vorgabe übernehmen.

## 8. Nächste sinnvolle Arbeitsschritte

1. Neue Session mit `$project-context LOAD` beginnen; lokalen Git-Snapshot abgleichen.
2. Offene Werte zum beschlossenen Gewichtssystem und Detailregeln von Variante B klären.
   Erst nach ausdrücklicher Freigabe Spielregeln oder Code ändern.
3. Bei nächster beauftragter Dokumentationspflege die oben markierte Drift beheben.
4. Für native Release-Abnahme passende Exporttemplates bereitstellen und EXE starten;
   Paketprüfung und MCP-Entwicklungsprüfung bleiben getrennte Nachweise.
5. Die Roadmap nicht umnummerieren: Training und weitere Aufzucht folgen erst nach
   festgelegtem Umfang; diese Übergabe erteilt keine Implementierungsfreigabe.

## 9. Relevante Dokumente und Testbefehle

Nur aufgabenbezogen nachladen:
- [AGENTS.md](../AGENTS.md), [project-context](../.agents/skills/project-context/SKILL.md),
  [requirements-review](../.agents/skills/requirements-review/SKILL.md): Arbeitsregeln.
- [MONSTER_SYSTEM_DESIGN.md](MONSTER_SYSTEM_DESIGN.md): verbindliche Monster-/Typregeln.
- [LIFE_CARE_MVP.md](LIFE_CARE_MVP.md): Versorgung, Items, Zeit, UI und MVP-Testwerte.
- [ARCHITECTURE.md](ARCHITECTURE.md), [GAME_DESIGN.md](GAME_DESIGN.md),
  [ROADMAP.md](ROADMAP.md): Komponenten, Vision und offizielle Meilensteine.
- [PRERENDERED_FOREST_POC.md](PRERENDERED_FOREST_POC.md),
  [SETTINGS_MENU_TESTS.md](SETTINGS_MENU_TESTS.md): Grafik-/Settings-Nachweise.

Aus dem Projektroot; lokal installierter Pfad, anderswo anpassen:

```powershell
$godotExe = 'D:\godotinstall\Godot_v4.7.2-stable_win64_console.exe'
# Frischer Checkout: einmal Ressourcenimport abschließen.
& $godotExe --headless --editor --path . --import --quit
& $godotExe --headless --path . --script tests/test_monsters.gd
& $godotExe --headless --path . --fixed-fps 60 --script tests/test_companion.gd
& $godotExe --headless --path . --fixed-fps 60 --script tests/test_companion_motion.gd
& $godotExe --headless --path . --fixed-fps 60 --script tests/test_companion_delay.gd
& $godotExe --headless --path . --fixed-fps 60 --script tests/test_life_care.gd
& $godotExe --headless --path . --fixed-fps 60 --script tests/test_world_smoke.gd
& $godotExe --headless --editor --path . --export-pack 'Windows Desktop' .godot/life_release.zip
python tests/test_release_archive.py .godot/life_release.zip
git diff --check
```

Letzte Nachweise aus den vorangegangenen Arbeitssitzungen: Foundation 78/0,
Companion 47/0, Bewegung 52/0, Delay 24/0, Life & Care nach Fütterungsfix 80/0;
Welt-Regression ohne Fehler, Archive-Ausschlussprüfung erfolgreich.
In dieser Skill-Erstellung keine Gameplay-Tests erneut ausgeführt.
Die damalige Paketstart-Probe unter `.godot/windows_release_check/` ist ein lokales,
ignoriertes Diagnoseartefakt, keine im Checkout garantierte Testsuite.
