# Life & Care MVP 1

## Status und Grenzen

Alle sechs freigegebenen Arbeitspakete sind implementiert und jeweils vor dem
nächsten Paket getestet worden. Die bestehenden Monsterarten bleiben Drako,
Slimo und Fenri. Toxipad und Prototyp 2 sind ausschließlich visuelle Referenzen.
Training, Fatigue, Happiness, Discipline, Schlaf, biologisches Alter, Krankheiten,
Evolution, Praise/Scold und Savegames werden noch nicht simuliert.

## 1. Weltzeit

`WorldTime` ist ein Autoload von `FantasyMonWorldClock`. Weltsekunden sind von
Realzeit, biologischem Alter und der lokalen Following-Uhr getrennt. Eine reale
Minute entspricht einer Spielstunde; ein Tag hat 24 Stunden. Die vorläufige
Startkonfiguration ist Tag 1 um 08:00.

Normale Fortschreibung ruht während SceneTree-Pause und Segmentübergängen. Es
werden keine OS-Zeitstempel zum Nachholen verwendet; bei geschlossenem Spiel
vergeht keine Zeit. `advance_seconds()` und `advance_hours()` simulieren explizite
Vorwärtsintervalle und melden beide Endpunkte über `advanced`. Normale Schritte
und Zeitsprünge benutzen denselben Pfad. Künftige zeitabhängige Systeme müssen
an diesem Intervall ansetzen. `debug_set_seconds()` verändert dagegen nur den
Testzustand und meldet keine simulierte Zeit. Frühere Pflegeereignisse werden
bei direktem Zurücksetzen der Uhr nicht umgeschrieben.

`region_time_factor` (Standard 1) ist ein Erweiterungspunkt; es gibt noch keine
regionsabhängigen Regeln. Die technische Grenze von 1e12 Weltsekunden ist keine
Lebenszeit- oder Balancingentscheidung. Negative/nicht endliche Simulationsdeltas
werden abgewiesen. Explizite Debug-Zeitsprünge sind auch im pausierten Menü möglich.

## 2. Sättigung und Pflegeereignisse

`MonsterInstance` besitzt `satiety` (0..100), `refusing_food` und einen eigenen
Pflegeereignisverlauf. `MonsterDefinition` hält Startwert, Verlust pro Spielstunde
und Futterbedarf. Diese Werte sind konfigurierbar und unabhängig von trainierten
Stats. `changed` informiert Ansichten auch über Vital- und Statänderungen.

| Vorläufige Testkonfiguration | Start | Verlust/Stunde | food_requirement |
| --- | --- | --- | --- |
| Drako | 100 | 8 | 1,5 |
| Slimo | 100 | 5 | 0,75 |
| Definition-Standard / Fenri | 100 | 8 | 1,0 |

**Keine endgültigen Balancingwerte.** Ab 80 gilt ein Monster als satt.
`LifeCare` verbindet die Weltzeit mit der aktiven Monsterinstanz, unabhängig vom
sichtbaren Körper. Aktuell wird nur der aktive Begleiter simuliert; ein Monster-
Roster mit inaktiven Bewohnern existiert noch nicht.

- **STARVATION:** Regulärer Zeitfortschritt einschließlich Zeitsprüngen erreicht
  aus positiver Sättigung 0. Das Ereignis erhält den berechneten Zeitpunkt des
  Grenzübertritts und tritt pro ununterbrochener Hungerphase höchstens einmal auf.
  Erfolgreiche Versorgung ermöglicht eine neue Hungerphase.
- **OVERFEEDING:** Eine erfolgreiche Fütterung ergibt rechnerisch mehr als 100.
  Die Anzeige wird auf 100 begrenzt; weiteres Futter wird verweigert, bis der Wert
  strikt unter 80 sinkt. Genau 100 erzeugt keinen Überfütterungsfehler.

Ereignisse enthalten eine stabile Ursache, Weltsekunden und die Monsterinstanz-ID.
Neue Ursachen benötigen kein anderes Ereignisformat. Direktes Debug-Setzen löst
keine Pflegefehler aus. Das Löschen des Verlaufs aktiviert eine laufende Hungerphase
nicht erneut. Pflegefehler sind ausschließlich in der Debug-UI sichtbar.

## 3. Items, Inventar und Fütterung

`FantasyMonItemDefinition` ist eine editierbare Resource mit ID, EN/DE-Textschlüsseln,
Kategorie, optionalem Icon, Stapelmaximum und `FantasyMonItemEffect`-Resources.
Implementiert sind Kategorie `Food` und Effekt `satiety`; unbekannte Effekte werden
ohne Verbrauch abgelehnt. Vorlieben und Happiness-Effekte fehlen bewusst.

`data/items/catalog.tres` enthält die Definitionen und die Inventar-Startkonfiguration.
Neue normale Lebensmittel werden durch Resources und Katalogeinträge ergänzt;
UI-Skripte führen keine eigene Itemliste.

| Lebensmittel | Sättigungswert | Stapelmaximum | Anfangsmenge |
| --- | --- | --- | --- |
| Small Meat | 30 | 10 | 5 |
| Apple | 15 | 20 | 5 |
| Mushroom | 10 | 20 | 5 |

Auch diese Werte sowie **20 Inventarslots** sind vorläufige Testkonfigurationen.
Alle Arten können jedes normale Lebensmittel essen. Effektiver Zugewinn ist
`food_satiety_value / food_requirement`; der Bedarf muss endlich und positiv sein.

`FantasyMonInventory` ist ein RefCounted-Modell mit Mengen, Stapeln, Kapazitätsprüfung
und `changed`-Signal. Ein Stapel belegt einen Slot. Hinzufügen und Entfernen erfolgen
vollständig oder gar nicht. Ansichten erhalten Kopien der Stapeldaten, gemeinsame
Itemdefinitionen bleiben Konfiguration. Menge/Operation ist technisch auf 1.000.000
und Kapazität auf 1.000 Slots begrenzt; dies sind keine Balancingvorgaben.

`FantasyMonFeedingService.feed(monster, inventory, item, world_seconds)` ist unabhängig
von UI und Autoloads. Er prüft alle Bedingungen, berechnet die Wirkung, verbraucht
bei Erfolg genau ein Item und meldet einen übersetzbaren Ergebnisschlüssel.
Überfütterung ist erfolgreich; Verweigerung verbraucht nichts. Eine Transaktionssperre
verhindert doppelte Verwendung durch synchrone Signal-Callbacks.

`PlayerInventory` hält das Inventar über Segmentwechsel und verbindet den Dienst
mit aktivem Monster, Katalog und Uhr. Monsterdaten und Inventar bleiben nur während
der Spielsitzung erhalten; auf Datenträger werden weiterhin nur Einstellungen gespeichert.

## 4. Menükoordination und Bedienung

`Menus` ist allein für Menüpause und normale Menütasteneingaben zuständig.
Settings, Inventar, Pflege und Monsterstatus sind getrennte Control-Ansichten.
Ein Wechsel entpausiert die Simulation nicht. Pflege -> Feed öffnet eine auf Food
gefilterte Inventaransicht und ermöglicht die Rückkehr zur Pflege. Beide Ansichten
verwenden denselben Fütterungsdienst. Ein inaktives Menü kann kein anderes schließen
oder entpausieren. Während Segmentübergängen öffnen keine Menüs.

| Taste | Funktion |
| --- | --- |
| F1 | Inventar |
| F2 | Pflege |
| F3 | Monsterstatus |
| F4 | Einstellungen |
| ESC | In der Welt Settings öffnen; im Menü zurück/schließen |
| F12 | Debug-UI, nur wenn im Entwicklungsbuild vorhanden |

Diese Funktionstasten und ESC sind für Bewegung gesperrt. Alte Belegungen auf
neu reservierten Funktionstasten fallen beim Laden auf WASD zurück. ESC bricht
zunächst eine laufende Tastenbelegung ab; das nächste ESC schließt Settings.
Mausnavigation und Tastaturfokus stehen zusätzlich bereit. Neue Texte sind EN/DE-
Schlüssel im vorhandenen TranslationServer-System. Die Ansichten verwenden das
Settings-Theme, scrollbare Inhalte und größenabhängige Panels. Header/Footer der
Settings vergrößern sich auf kleinen Zeichenflächen nicht über deren Höhe hinaus.

Der Status zeigt ausschließlich vorhandene Daten: Name, Current/Max HP/MP, sechs
Stats, Sättigung und gegebenenfalls Futterverweigerung. Die Definitionen haben noch
keine Typfelder; Element/Attribut und zukünftige Bedürfnisse werden nicht erfunden.

## 5. HUD und Einstellungen

`GameHud` enthält getrennte Komponenten `MonsterHud` (unten rechts) und
`WorldTimeHud` (oben rechts). Sie beobachten Zustandssignale und Sprachwechsel;
sie simulieren selbst keine Bedürfnisse. Die obere Navigation bricht bei wenig
Platz um. Statusansicht und HUD wechseln bei einem anderen aktiven Monster ihre
Signalbindungen; es bleibt bei genau einem Begleiter.

`GameSettings` persistiert vier Sichtbarkeitsschalter unter `[interface]` in
`user://settings.cfg`. Alte Dateien ohne diesen Abschnitt zeigen alle Werte.
Die Schalter liegen im eigenen Interface-Tab der Settings, nicht im Monsterstatus.
Die Tests verwenden einen temporären Konfigurationspfad und überschreiben keine
Spielereinstellungen. HUD-Editor und frei einstellbare Skalierung sind nicht umgesetzt.

## 6. Entwickleroberfläche und Export

`dev/life_debug_menu.gd` bietet editierbare Weltzeit, Sättigung, HP/MP und Stats,
Parameteranzeige, Artwechsel zu vorhandenen Definitionen, Pflegefehler mit Zeit/ID,
Verlaufslöschung, Inventaranzeige, Itemzugabe/-entnahme und reguläre Fütterungs- und
Zeitversuche. Direkte Testmanipulation und reguläre Simulation sind getrennte Bereiche.
Die Oberfläche besitzt keine unabhängige Pflege- oder Fütterungslogik.

Sie wird nur bei `OS.is_debug_build()` und vorhandener Debug-Ressource geladen.
Das Windows-Exportpreset schließt `dev/*`, `tests/*` und das MCP-Toolkit aus.
Dies gilt im bereitgestellten Preset auch für Debug-Exporte; die Entwickleroberfläche
ist für Editor-Spieltests gedacht. Neue Exportpresets müssen dieselben Ausschlüsse
übernehmen. Ein Archive-Test kontrolliert den tatsächlichen Paketinhalt, auch bei
binär exportierten GDScripts. Nicht nur die Schaltfläche wird versteckt.

## Tests und selbst ausprobieren

```powershell
& 'D:\godotinstall\Godot_v4.7.2-stable_win64.exe' --headless --path . --fixed-fps 60 --script tests/test_life_care.gd --log-file .godot/life_care_tests.log
& 'D:\godotinstall\Godot_v4.7.2-stable_win64.exe' --headless --editor --path . --export-pack 'Windows Desktop' .godot/life_release.zip --log-file .godot/life_export.log
python tests/test_release_archive.py .godot/life_release.zip
```

Bei neuem Checkout zuerst Godots Ressourcenimport abschließen. Die Headless-Treiber
prüfen zusätzlich zu Log-Zusammenfassungen ihren Exitcode. Die Windows-GUI-Binary
kann den Shell-Aufruf früh zurückgeben: vor dem nächsten abhängigen Schritt auf die
fertige Zusammenfassung im Log achten. Die vorhandenen Monster-, Companion-,
Bewegungs-, Delay- und Welt-Regressionen bleiben Teil der Abnahme.

Zum Spielen F5 starten, Sättigung im HUD beobachten, F1 oder Pflege -> Feed öffnen
und ein Lebensmittel verwenden. Mit F12 lassen sich Intervalle vorspulen und
Grenzfälle testen. Die normale Anzeige enthält keinen Pflegefehlerzähler.

Nachweise: 70 Life-&-Care-Prüfungen ohne Fehler; unverändert 78 Foundation-,
47 Companion-, 52 Bewegungs- und 24 Delay-Prüfungen sowie Welt-Regression ohne
Fehler. Das geprüfte Exportarchiv enthält keine Debug-, Test- oder MCP-Dateien.
Godot-MCP-Spieltests bestätigten Fütterung, Verweigerung ohne Verbrauch, pausierte
Weltzeit, getrennte Oberflächen und sofortige EN/DE-Aktualisierung.
Die kleine 640x360-Zeichenfläche ist automatisiert auf erreichbare Panels und
automatisch mitwandernden Tastaturfokus geprüft. Die Uhr wurde bei 30/60/120
Physikschritten auf identischen Fortschritt sowie mit verändertem Regionsfaktor geprüft.
Ein nativer Release-EXE-Test steht aus, da lokal keine Exporttemplates installiert sind.
