---
name: project-context
description: Load, save, or verify the compact FantasyMon session handoff when starting a session, preparing a session change, or checking context drift. Use task-specific source checks rather than a full repository audit.
---

# Project Context

## Aufruf und gemeinsame Grenzen

- `$project-context LOAD`: Kontext lesen; keine Dateien ändern.
- `$project-context SAVE`: ausschließlich die bestehende Übergabe aktualisieren.
- `$project-context VERIFY`: Übergabe lesend mit dem Repository abgleichen.
- Ohne Modus standardmäßig LOAD verwenden und den gewählten Modus nennen.
  Eine ausdrücklich gewünschte Übergabeaktualisierung entspricht SAVE.
  Eine ausdrücklich gewünschte reine Konsistenzprüfung entspricht VERIFY.

Arbeitsverzeichnis ist der FantasyMon-Projektroot. Die Übergabe liegt unter
[docs/SESSION_HANDOFF.md](../../../docs/SESSION_HANDOFF.md), die Projektregeln in
[AGENTS.md](../../../AGENTS.md). Bereits in dieser Session gelesene Quellen nicht
erneut vollständig laden. Bei fachlicher Unklarheit gilt zusätzlich der bestehende
[requirements-review-Skill](../requirements-review/SKILL.md).

Dieser Skill autorisiert keine Gameplay-, Architektur-, Branch-, Commit-, Merge-
oder Push-Aktionen. Keine neuen Abhängigkeiten, vollständigen Gesprächsprotokolle,
Geheimnisse oder langen Codeauszüge in die Übergabe aufnehmen.

## Quellen und Kennzeichnungen

- **IMPLEMENTED:** Mit aktuellem Code/Resources nachgewiesen; passende Pfade nennen.
  Git zeigt außerdem, ob dieser Zustand committed oder nur lokal vorhanden ist.
- **DECIDED:** Ausdrücklicher Beschluss des Projektverantwortlichen, mit Beleg aus
  verbindlichem Fachdokument oder identifizierbarer ausdrücklicher Nutzeranweisung.
  Kein Vorschlag, Mockup oder implementierter Prototyp allein begründet DECIDED.
- **PROPOSED:** Unbestätigte Idee oder Empfehlung; keine Freigabe zur Umsetzung.
- **OPEN:** Ungeklärte Regel, fehlender Beleg oder widersprüchlicher Stand.

Code und Git entscheiden über Implementierungsbehauptungen; ausdrückliche
Projektentscheidungen entscheiden über gewünschtes Gameplay. Eine beschlossene,
noch nicht implementierte Funktion ist kein Widerspruch. Testwerte und technische
Grenzen nicht als endgültige Balance darstellen. Bei widersprechenden Aussagen
beide Quellen benennen und bei wesentlichen Entscheidungen gezielt nachfragen;
keine eigene Gameplay-Entscheidung als DECIDED speichern.

## LOAD — Einstieg mit kleinem Kontext

1. Zuerst AGENTS.md, diese Anleitung und die kompakte Übergabe lesen. Die
   grundlegenden dort verlangten Skill-Regeln berücksichtigen; nicht vorsorglich
   sämtliche verlinkten Designdokumente, Tests oder Quelldateien öffnen.
2. Aktuellen lokalen Stand kurz prüfen: `git status --short --branch`,
   `git rev-parse --short HEAD` und bei Bedarf `git log -3 --oneline`.
   Kein automatischer Fetch, Checkout oder Branchwechsel. Lokale origin-Refs
   nicht als frisch abgefragten Serverstand ausgeben.
3. Übergabe-Snapshot mit HEAD/Arbeitsbaum vergleichen. Bei Abweichung zunächst
   nur betroffene Pfade ermitteln, etwa über `git diff --name-status <snapshot> HEAD`
   und `git diff --name-only`; untracked/staged Änderungen ebenfalls beachten.
   Nur für den aktuellen Auftrag relevante Abschnitte/Dateien gezielt nachladen.
   Ist der Snapshot-Commit unbekannt, die Einschränkung nennen statt History umzubauen.
4. Kurz zusammenfassen: Stand, Branch/lokale Änderungen, zentrale Grenzen und
   nächste offene Entscheidung. Ältere Testberichte als historische Nachweise
   kennzeichnen, nicht als frisch bestandene Tests ausgeben.

Fehlt die Übergabe, dies melden und einen begrenzten SAVE vorschlagen. LOAD nicht
ungefragt zu einer vollständigen Repository-Analyse oder Schreibaktion ausweiten.

## SAVE — geprüfte Übergabe ersetzen, nicht anhängen

1. Bestehende Übergabe, aktuelle Nutzerentscheidungen und Git-Snapshot prüfen.
   Nicht allein aus dem Gespräch rekonstruieren. Vorhandene Einträge mit den
   tatsächlich betroffenen Dateien abgleichen; unberührte Inhalte nicht blind löschen.
2. Neue Implementierungen anhand gezielter Diffs/Codeprüfung bestätigen. Beschlüsse
   getrennt von Implementierung, Vorschlägen und offenen Details festhalten.
   Unklare Gameplay-Regeln erfragen; bis zur Klärung ausdrücklich OPEN belassen.
3. `docs/SESSION_HANDOFF.md` innerhalb der vorhandenen neun Bereiche aktualisieren:
   Überblick/Stand; Architektur; implementierte Funktionen; beschlossene Zukunft;
   offene Entscheidungen/Vorschläge; Probleme/Grenzen; Git; nächste Schritte;
   Dokumente/Testbefehle. Richtwert höchstens 250 Zeilen.
4. Veraltete Aussagen nach Prüfung ersetzen statt einen Verlauf anzuhängen.
   Umfangreiche Regeln und Typecharts nur verlinken. Quellenpfade, Prüfbasis-Commit
   und Datum angeben. Git-Angaben ausdrücklich als Snapshot behandeln; durch SAVE
   selbst entstandene Dokumentationsänderungen nicht als sauberen Arbeitsbaum ausgeben.
5. Testergebnisse nur mit Ausführungs-/Logbeleg aufnehmen und kennzeichnen, ob sie
   in dieser Session neu liefen. Fehlende Exporttemplates und ungetestete native
   Builds nicht durch erfolgreiche Pakettests als erledigt darstellen.
6. Links, Statuskennzeichnungen und Konsistenz prüfen; `git diff --check` ausführen.
   Kurz berichten, was aktualisiert und was ungeklärt blieb. Andere Dokumente,
   AGENTS.md, Skills und Code nur bei separat erteiltem Auftrag ändern.

## VERIFY — gezielter Abgleich ohne Schreiben

1. Übergabe und lokalen Git-Stand wie bei LOAD prüfen.
2. Die in der Übergabe behaupteten Komponenten/Schnittstellen anhand der genannten
   Quellen gezielt prüfen. Nach Snapshot-Änderungen und Hinweisen auf veraltete
   Regeln suchen; nicht routinemäßig jedes Asset oder jede Repository-Datei lesen.
3. Ergebnis nach **bestätigt**, **abweichend/veraltet** und **nicht belegt/fehlend**
   gliedern, mit betroffenen Pfaden. Implementierungsstand und gewünschte Regeln
   getrennt bewerten. Für neue Testausführungen deren tatsächlichen Umfang nennen.
4. Wesentliche Unklarheiten gemäß requirements-review gezielt nachfragen. Keine
   fehlenden Entscheidungen erfinden. Korrekturen benennen; zur Aktualisierung
   SAVE verwenden, statt VERIFY stillschweigend in einen Schreibmodus umzuwandeln.
