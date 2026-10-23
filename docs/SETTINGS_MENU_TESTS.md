# Einstellungsmenü – Funktionstest

Stand: 23.10.2026, Godot 4.7.2 unter Windows. Die Prüfungen erfolgten über Godot MCP, zunächst in der eingebetteten Spielansicht und anschließend in einem eigenständigen Spielfenster.

| Prüfung | Ergebnis |
| --- | --- |
| ESC öffnet/schließt das Menü | Erfolgreich; Sichtbarkeit und SceneTree-Pause kontrolliert. |
| Pause | Spielerposition bleibt trotz Bewegungseingabe unverändert. Ein direkter `SceneManager.travel_to()`-Aufruf während der Pause startet keinen Wechsel. |
| Sprache per Tastatur | Option mit Enter öffnen, mit Pfeil wechseln, mit Enter bestätigen: Deutsch → Englisch erfolgreich. |
| Übersetzungen in Segment A | Sofortiger Wechsel zwischen `Forest path (F)` und `Waldpfad (F)`, ohne Szenenneustart. |
| Übersetzungen in Segment B | Sofortiger Wechsel zwischen `Clearing (S)` und `Lichtung (S)`. |
| Neubelegung per Maus/Tastatur | Vorwärtsschaltfläche anklicken, F drücken: Belegung und Szenenhinweis ändern sich, F bewegt anschließend den Spieler. |
| Doppelte Belegung | S für Vorwärts wird abgewiesen, weil Rückwärts bereits S verwendet. |
| ESC während Neubelegung | Bricht zuerst die Erfassung ab; das Menü bleibt offen. Nächstes ESC schließt. |
| Dauerhaftes Speichern | Deutsch, F, 37 Prozent Lautstärke und Vollbild gespeichert; nach vollständigem Neustart identische Werte geladen. `user://settings.cfg` kontrolliert. |
| Master-Lautstärke | Engine-Master-Bus: 0 Prozent → linear 0 und stumm; 37 Prozent → linear ca. 0,37 und nicht stumm. Die Szene enthält bisher keine Musik oder Soundeffekte für einen Hörtest. |
| Echter Anzeigemodus | Eigenständiges Fenster: DisplayServer-Modus 0 (Fenster) → 3 (Vollbild, 3440×1440) → 0. |
| Kleine Fenster | Eigenständige Fenster bei 800×600 und 640×360 geprüft. Bei 640×360 scrollt die Steuerungsseite zum fokussierten unteren Tastenfeld; Schließen bleibt erreichbar. |
| Segmentwechsel | A → B → A über die vorhandenen Area3D-Trigger erfolgreich, auch mit geänderter Vorwärtstaste. Eintrittspunkte bleiben korrekt. |
| Menü in beiden Segmenten | Erfolgreich; derselbe UI-Autoload bleibt erhalten. |
| Spielerfehler übersetzen | Absichtlich ungültigen Eintrittspunkt angefordert: verständlicher Hinweis bleibt beim direkten Sprachwechsel übersetzbar, laufende Szene bleibt erhalten. Der dabei erwartete Diagnosefehler ist kein regulärer Laufzeitfehler. |

Die eingebettete Godot-Spielansicht erzwingt Fenstermodus und Fenstergröße; diese beiden Funktionen wurden deshalb im eigenständigen Fenster geprüft. Die im Mockup enthaltenen zusätzlichen Spielmechaniken wurden nicht übernommen.

Nach den Tests wurden die gespeicherten Werte auf Englisch, WASD, Fenstermodus und 100 Prozent Master-Lautstärke zurückgesetzt. Keine Commits, Merges oder Pushes ausgeführt.
