# Vorgerenderte Waldlichtung – Proof of Concept

## Umfang und Aufbau

Nur `forest_clearing.tscn` verwendet den vorgerenderten Hintergrund. `forest_path.tscn` bleibt unverändert eine 3D-Szene. Beide verwenden die gemeinsame 16:9-Ausgabe: Basis 1152×648, `canvas_items`, Seitenverhältnis `keep`. Andere Fensterformate erhalten Balken; der Bildausschnitt wird weder erweitert noch unabhängig vom 3D-Bild gestreckt.

Das Bild liegt unter `res://assets/backgrounds/forest/forest_clearing/background.png` und ist 1920×1080 Pixel groß. Es wird direkt aus der vorhandenen Godot-Kulisse erzeugt. Es enthält keine Spielfigur, Wegbeschriftung, Menü oder Schwarzblende. Tiefenkarten und zusätzliche Vordergrundbilder werden nicht benötigt.

Die Quellkulisse `ForestBackdrop` und das Bodenmesh bleiben in der Szene erhalten und im Editor bearbeitbar. `PrerenderedBackdrop` blendet sie nur zur Laufzeit aus. Boden-Collider, Randbegrenzungen, Spieler, Kamera, Ausgang und Eintrittspunkt bleiben bestehen. Es gibt keinen neuen Autoload und keine geänderte Bewegungs- oder Segmentlogik.

Der neue Testblock steht bei X=3, Z=0. Sein Quellmesh befindet sich unter `ForestBackdrop/TestRock`, sein Collider unter `WorldGeometry/TestRock`. Beide haben Größe 2,4×2,8×1,8 und Mittelpunkt (3, 1,4, 0). Der Block ist bewusst ein einfacher Platzhalter.

## Darstellung und Verdeckung

Die vorhandene Kamera bleibt perspektivisch bei (0, 18, 10,4), Rotation (-60°, 0°, 0°), vertikalem Sichtfeld 34° und `KEEP_HEIGHT`. Die beim Export verwendete Transformation, das Sichtfeld und die Kamera-Offsets werden am `PrerenderedBackdrop` gespeichert. Abweichungen oder ein Bild ohne 16:9-Format erzeugen eine übersetzte Fehlermeldung; die Quellkulisse bleibt in diesem Fehlerfall sichtbar.

Zur Laufzeit erzeugt die Komponente eine kamerafeste Bildfläche sowie ein einziges Verdeckungsmesh aus demselben Mesh und derselben Transformation wie der Testblock. Das Verdeckungsmaterial liest über `SCREEN_UV` dieselben PNG-Pixel wie die Bildfläche, schreibt jedoch die wirkliche 3D-Tiefe des Blocks. Figuren davor bleiben sichtbar, Figuren dahinter werden korrekt verdeckt. `ALPHA` wird nicht geschrieben; das Material bleibt im opaken Renderpfad.

Die Bildfläche verwendet keinen Tiefenschreibzugriff. Ihre Clip-Tiefe liegt bei 0,00001, knapp innerhalb der Reverse-Z-Fernebene. Exakt 0 würde im strikten Tiefentest verworfen. Das kamerafeste Quad deaktiviert Backface-Culling. Die beiden kleinen Shader sind für den aktuell verwendeten Godot-4.7-Forward+-Renderer mit D3D12 geprüft.

## Hintergrund erneut erzeugen

1. Spiel stoppen und `forest_clearing.tscn` im Godot-Editor öffnen.
2. `ForestBackdrop` beziehungsweise Boden, Licht oder Kamera bearbeiten. Die Quellkulisse ist im Editor sichtbar. Bei Änderungen am Testhindernis dessen Collider ebenfalls passend anpassen.
3. Szene speichern. `PrerenderedBackdrop` auswählen und im Inspector **Bake background.png** auslösen. Alternativ über Godot MCP `node_call_method` mit `node_path: "PrerenderedBackdrop"`, `method_name: "bake_background"` aufrufen.
4. Auf die Ausgabe **Background baked: … (1920x1080)** im Editor warten. Der Export läuft asynchron. Der Button wird währenddessen gegen parallele Ausführung gesperrt.
5. Godot importiert das überschreibend erzeugte PNG erneut. Danach die Szene nochmals speichern, damit auch die aktualisierte Kamerakalibrierung erhalten bleibt. Die erste Texturreferenz ist bereits gesetzt und muss nicht neu zugeordnet werden.
6. Mit F5 starten und Vorder-/Rückseite, Bodenposition sowie Hin- und Rückweg testen.

`tools/bake_forest_background.gd` erstellt dafür einen temporären SubViewport mit eigenem World3D und kopiert ausschließlich Quellkulisse, Boden, Kamera, Licht und Environment hinein. Drei erzwungene Renderdurchläufe vermeiden eine Abhängigkeit vom reduzierten Zeichnen eines unfokussierten Editors. Danach wird das PNG gespeichert und der temporäre Viewport entfernt. Die bearbeitbare Szene wird durch den Export nicht ersetzt.

Rendergröße und Zielpfad stehen als Konstanten im Exportskript. Beim Ändern der Rendergröße muss 16:9 erhalten bleiben. Bei Änderungen an Beleuchtung, Environment oder Renderer ist zusätzlich die Farbübereinstimmung zu prüfen. Das vorliegende Material ist keine allgemeine Lösung für andere Kameraprojektionen oder beliebige Nachbearbeitung.

## Durchgeführte Tests

Geprüft mit Godot MCP und Godot 4.7.2 unter Windows/Forward+/D3D12, zusätzlich in einem eigenständigen Spielfenster.

| Prüfung | Ergebnis |
| --- | --- |
| PNG-Export und erneuter Export | 1920×1080 aus der vorhandenen Kulisse; ohne Spieler und UI. |
| Kamera | Transformation und Sichtfeld unverändert; Bild und Proxy passen räumlich zusammen. |
| Hinter dem Testblock | Spieler bei (3, 0,901, -1,3) vollständig verdeckt. |
| Vor und seitlich neben dem Block | Spieler sichtbar, auch im Überlappungsbereich vor dem Block. |
| Kontrollprobe ohne Proxy | Derselbe Spieler hinter dem Block wird wieder sichtbar. |
| Pixelprüfung bei 1152×648 | Hinter dem Block 0 orange Spielerpixel, davor 2280, seitlich 2135; ohne Proxy hinter dem Block 2172. |
| Kollision beidseitig | Bewegung stoppt bei Z≈-1,251 beziehungsweise Z≈+1,251; Spieler bleibt auf dem Boden. |
| 4:3-Fenster | 800×600 Fenster mit 800×450 Renderbereich; Verdeckung bleibt korrekt, hinten 0 orange Pixel und vorne 1105. |
| Ultrawide-Fenster | 1280×540 Fenster mit 960×540 Renderbereich; Verdeckung bleibt korrekt, hinten 0 orange Pixel und vorne 1591. |
| Vollbild | Umschaltung über das Einstellungsmenü auf 3440×1440 und zurück; konstantes 16:9-Bild. |
| Segmentwechsel | A→B→A in eingebetteter und eigenständiger Spielansicht, korrekte Eintrittspunkte; A blendet Quelle aus, B behält sichtbare 3D-Kulisse. |
| Menü und Pause | ESC funktioniert; Spieler bleibt bei Bewegungseingabe stehen, SceneManager verweigert Wechsel während der Pause. |
| Übersetzungen | Wegbeschriftung aktualisiert sich sofort EN↔DE; Texte sind nicht ins Hintergrundbild eingebrannt. |

Die MCP-Screenshots enthalten den 16:9-Renderbereich und schneiden die außerhalb liegenden Fensterbalken ab. Fenstergröße und Rendergröße wurden deshalb zusätzlich direkt abgefragt. Die Pixelzählung dient als gezielte Prüfung der orangefarbenen Platzhalterfigur, nicht als allgemeiner Grafikvergleich.

## Grenzen des Prototyps

- Nur der Testblock besitzt ein Verdeckungsmesh. Weitere relevante Hindernisse benötigen entsprechende Meshes; die bisherigen Randbäume stehen außerhalb der begehbaren Fläche.
- Statische Umgebungsschatten sind im PNG enthalten. Ein dynamischer Kontaktschatten des Spielers auf dem PNG und die Beleuchtung der Figur durch die gebackene Umgebung sind noch nicht umgesetzt.
- Die Quellmeshes bleiben vorläufig im Szenenbestand und damit im Speicher, obwohl sie nicht gezeichnet werden.
- Änderungen an der Kulisse erfordern einen neuen Export. Der Kalibrierungscheck erkennt Kameraabweichungen, aber keine vergessenen Exporte nach Material- oder Geometrieänderungen.
- Keine animierten Umgebungsobjekte, Tiefenkarten oder neue Gameplay-Systeme. Für andere Renderer und auf anderen GPUs ist ein eigener Verdeckungstest erforderlich.
