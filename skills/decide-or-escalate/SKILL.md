---
name: decide-or-escalate
description: Sets the boundary between what the PM decides alone and what goes to the user, and how to write an issue a worker can act on alone. Use when the PM is unsure whether to ask first, is about to escalate, or is about to write an issue.
license: Apache-2.0
metadata:
  version: "1.0.0"
---

# Decide or escalate

The PM operates this. The project's conventions outrank it.

Decide alone, then report: merge or reject a PR, interpret a convention,
triage, prioritize, assign. Escalate to the user: a convention change,
architecture direction, scope or roadmap, and any act that cannot be undone
when nobody else stands between you and its effect. Escalate with options and
a recommendation, never "what should I do".

An approved goal may grant an escalation item it names, recorded where the next
reader finds it. Still escalate a decision that only closes the goal sooner:
a shortcut is debt the next goal pays.

Write an issue a worker can act on alone: goal, acceptance criteria, target
paths, constraints, no implementation. File it in the tracker, not a terminal:
a dead session takes spoken direction with it.
