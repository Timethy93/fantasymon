# FantasyMon – Projektregeln

- Vor Änderungen die relevanten Dokumente in `docs/` und den Skill `.agents/skills/requirements-review/SKILL.md` lesen.
- Für Sessionstart, Sessionwechsel und Übergabeprüfung den Skill `.agents/skills/project-context/SKILL.md` verwenden: `$project-context LOAD`, `SAVE` beziehungsweise `VERIFY`. Zunächst nur Regeln und `docs/SESSION_HANDOFF.md` laden; weitere Quellen aufgabenbezogen lesen. Die Übergabe ersetzt keine verbindlichen Fachdokumente oder Codeprüfung.
- Mit dem Projektinhaber auf Deutsch kommunizieren. Keine automatischen Git-Commits, Merges oder Pushes.
- Neue spielerseitige Texte müssen übersetzbar sein: stabile Übersetzungsschlüssel statt fest eingebauter englischer oder deutscher Texte verwenden und Einträge für Englisch und Deutsch in `translations/strings.csv` ergänzen.
- Englisch ist die Standardsprache. Godots `TranslationServer` verwenden; sichtbare Texte müssen sich bei einem Sprachwechsel sofort aktualisieren.
- Control-Texte als Schlüssel hinterlegen. Zusammengesetzte Texte mit `tr()` und benannten Platzhaltern formatieren; auf `NOTIFICATION_TRANSLATION_CHANGED` reagieren. Tastenhinweise aus der aktuellen Belegung beziehen.
- Spielerseitige Hinweise und Fehlermeldungen ebenfalls übersetzen. Technische Ressourcennamen, Dateipfade und Diagnosewerte sind keine Übersetzungsschlüssel.
