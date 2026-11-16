---
name: review-craft
description: Scans a codebase read-only for workmanship and code quality problems, namely folder structure, outdated or legacy code, reinventing the wheel, shell scripts doing a build tool's job, and declining tools, and returns a plain-text candidate list for the PM to triage. Use when QA is invoked to review craft, modernise a project, or look for better tools and idioms.
license: Apache-2.0
metadata:
  version: "1.0.1"
---

# Review craft

QA operates this; every step is a read. You change no file and file no issue:
the PM triages the list, accepting, prioritizing or dropping each candidate.
`agents/qa.md` §Authority holds your limits.

## Lenses

- **Folder structure**: a layout that departs from the language's or
  framework's standard one, or mixes responsibilities.
- **Dated code**: deprecated APIs, and code not written in the language's
  current idiom.
- **Hand-rolled wheels**: code doing what a widely used open-source tool or
  library does, such as a hand-written test harness where a well-known test
  framework exists.
- **Shell glue**: shell scripts doing what a build tool, task runner or CI
  should.
- **Declining tools**: a tool in use that is declining or has a markedly better
  successor.

## Judging a finding

You hold no ban and no preferred tool. A shell script that fits its job is not
a finding, and neither is a hand-written piece smaller and clearer than the
library that would replace it. Judge each case; a rule applied without looking
only adds triage noise.

Every finding carries:

- (a) the concrete alternative, with a current web source;
- (b) why it is better in this code, at `file:line`.

A finding missing either is dropped, not marked Speculative, because a
recommendation from memory may already be stale. "Current" is established by
search in this session: official documentation, a deprecation notice or a
successor announcement. Where web search is unavailable, report the scan as
not run, since dropping every finding would look like a clean result.

## Procedure

1. **Read the standard first.** Find the project's conventions through its
   entry point, and its decision records. Note every choice that documents a
   reason.
2. **Choose where to look.** Take a direction the invocation names. Otherwise
   read the layout, the manifests and the commit history for the files that keep
   changing.
3. **Walk each lens** and note a suspect with its `file:line`, read in this
   session.
4. **Check the fit.** Would the alternative do what the code does today with
   less code, less upkeep or fewer failures there?
5. **Search the web** for the alternative's current status and for the
   suspect's own. Record the URL.
6. **Respect documented reasons.** A choice with a documented reason is a
   re-review candidate only when new evidence overturns that reason: cite both,
   or drop it.
7. **Flag direction.** A candidate that would swap the project's stack, such as
   its language, framework or runtime, is architecture direction. Mark it
   `Direction for the user: yes`; the PM escalates it and does not decide it.

## Output

Plain text, in your report to the PM. One block per candidate:

    Candidate N: <name>
    Lens: <one of the lenses>
    Paths: <target paths>
    Alternative: <the concrete tool or method>
    Source: <URL, and what it says>
    Why here: <why better in this code, file:line, file:line>
    Documented reason: <project doc and the new evidence, or none>
    Direction for the user: yes | no

End with the one candidate you would take first and why.
