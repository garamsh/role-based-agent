---
name: review-architecture
description: Scans a codebase read-only for deepening opportunities, where shallow modules could become deep ones, and returns a plain-text candidate list for the PM to triage. Use when QA is invoked to look for architectural friction, testability or navigability problems, or refactoring candidates in the project or a named area.
license: Apache-2.0
metadata:
  version: "1.0.0"
---

# Review architecture

QA operates this; every step is a read. You change no file and create no
glossary or ADR. You file no issue from this scan: the PM triages the list,
accepting, prioritizing or dropping each candidate, and a chosen one becomes
a worker's issue. `agents/qa.md` §Authority holds your limits. A candidate
that proposes a change to a rule or a settled decision is a proposal, never a
finding.

## Vocabulary

Use these terms exactly. "Component", "service", "API" and "boundary" each
mean something different to each reader, and a candidate in loose words cannot
be checked.

- **Module**: anything with an interface and an implementation, at any scale.
- **Interface**: everything a caller must know: signature, invariants, order,
  errors, configuration, performance.
- **Depth**: behaviour a caller can exercise per unit of interface learnt.
  Deep means much behind a small interface; shallow means an interface nearly
  as complex as the body.
- **Seam**: where behaviour can change without editing in place; where a
  module's interface lives.
- **Adapter**: a concrete thing satisfying an interface at a seam.
- **Leverage**: what callers get from depth. **Locality**: what maintainers
  get: change, bugs and knowledge concentrate in one place.

## Principles

- Depth belongs to the interface, not the implementation: a deep module may
  hold small parts behind internal seams.
- **Deletion test**: imagine deleting the module. If complexity vanishes, it
  was a pass-through; if it reappears across N callers, it earned its keep.
  A candidate must pass as "deleting would concentrate complexity".
- The interface is the test surface: if a test must reach past it, the module
  is the wrong shape.
- One adapter is a hypothetical seam; two are a real one. A seam where
  nothing varies is indirection.

## Procedure

1. **Read the standard first.** Find the project's conventions through its
   entry point. Read its glossary and its decision records, if any, for the
   area you scan. Name modules in the glossary's words. A settled decision is
   not a candidate: surface one only when the friction is real enough to
   reopen it, and name it.
2. **Choose where to look.** Take a direction the invocation names. Otherwise
   read the commit history far enough to find the hot spots, the files that
   keep changing, and start there, since deepening pays by making future
   change easier. Scattered changes mean widen the net.
3. **Walk the code and note friction**, without fixed heuristics:
   - understanding one concept means bouncing between many small modules;
   - a shallow module whose interface rivals its body;
   - pure functions extracted only for tests while the real bugs hide in how
     they are called (no locality);
   - tightly coupled modules leaking across their seams;
   - code untested, or hard to test through its interface.
4. **Apply the deletion test** to each suspect.
5. **Classify the dependencies** of each surviving candidate; the category
   fixes how the deepened module is tested across its seam:
   - *In-process*: pure computation or in-memory state. Merge the modules and
     test through the new interface; no adapter.
   - *Local-substitutable*: a local stand-in exists (an embedded database, an
     in-memory filesystem). Test with the stand-in; the seam stays internal.
   - *Remote but owned*: your own service across a network. Define a port at
     the seam; production uses a transport adapter, tests an in-memory one.
   - *True external*: a third party. Inject it as a port; tests use a mock
     adapter.

   Propose a port only where two adapters are justified. Tests on the
   deepened module replace the old tests of the shallow modules rather than
   layer over them, and assert outcomes through the interface so they survive
   a refactor.
6. **Verify each claim** at `file:line`, read in this session. A suspicion you
   could not verify goes in marked Speculative.

## Output

Plain text, in your report to the PM; no file, no HTML. Propose no interface
shape yet. One block per candidate:

    Candidate N: <name, in glossary words>
    Paths: <target paths>
    Problem: <one sentence>
    Solution: <one sentence>
    Evidence: <file:line, file:line>
    Strength: Strong | Worth exploring | Speculative
    Conflicts: <the ADR or convention it contradicts, or none>

End with the one candidate you would take first and why. Say when you found
nothing: a scan that reports nothing looks the same as one that died.
