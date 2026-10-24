---
name: requirements-review
description: Critically review ambiguous requirements, challenge assumptions, and clarify consequential design decisions before implementing changes in FantasyMon.
---

# Requirements Review

## Goal

Ensure that the correct feature is implemented, rather than simply implementing the first possible interpretation of a request.

## Workflow

1. Read relevant project documentation and inspect existing implementations.
2. Identify the user's intended outcome.
3. Check for ambiguous requirements, contradictions, missing information, and technical risks.
4. Distinguish confirmed requirements from assumptions and recommendations.
5. Ask focused questions when unresolved decisions could materially change the implementation.
6. Suggest simpler or more maintainable alternatives when appropriate.
7. Wait for clarification before making significant gameplay or architecture decisions.

## When to Ask Questions

Ask before implementing when:

- A gameplay mechanic has multiple plausible interpretations.
- A requirement contradicts existing project documentation.
- A decision affects the game's architecture or future extensibility.
- The request would require inventing important gameplay rules.
- An implementation could destroy or overwrite existing work.

## When NOT to Ask Questions

Proceed without clarification when:

- The instruction is unambiguous.
- Existing documentation already answers the question.
- The decision is minor, reversible, and follows project conventions.

## Communication

- Communicate with the project owner in German.
- Be constructively critical, not blindly agreeable.
- Explain important trade-offs concisely.
- Ask at most three focused questions at a time.
- Do not overwhelm the user with unnecessary technical details.
- Never treat silence as approval of a major design decision.

## Important

Critical thinking must not become an obstacle to development. The purpose is to prevent wrong assumptions while maintaining efficient progress.
