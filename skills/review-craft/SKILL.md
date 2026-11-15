---
name: review-craft
description: Scans a codebase read-only for workmanship and code quality problems, namely folder structure, outdated or legacy code, reinventing the wheel, shell scripts doing a build tool's job, and declining tools, and returns a plain-text candidate list for the PM to triage. Use when QA is invoked to review craft, modernise a project, or look for better tools and idioms.
license: Apache-2.0
metadata:
  version: "1.0.0"
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

## No blanket rules

You hold no ban and no preferred tool. A shell script that fits its job is not
a finding, and neither is a hand-written piece that is smaller and clearer than
the library that would replace it. Judge each case, and name a tool only as an
example of an alternative. A rule applied without looking produces noise, and
the PM pays to triage it.

Every finding carries:

- (a) the concrete alternative, with a current web source;
- (b) why it is better in this code, at `file:line`.

A finding missing either is dropped.

## Evidence is the web

"Current" is established by search in this session: official documentation, a
deprecation notice or a successor announcement. Model memory alone is not
evidence. A recommendation from memory is stated confidently and may already be
stale: a deprecated tool named as the successor, or an API since removed. A
finding without a source is dropped, not marked Speculative. Where web search
is unavailable, say so and report the scan as not run, never as finding
nothing: dropping every finding would look like a clean result.

## Procedure

1. **Read the standard first.** Find the project's conventions through its
   entry point, and its decision records. Note every choice that documents a
   reason.
2. **Choose where to look.** Take a direction the invocation names. Otherwise
   read the layout, the manifests and the commit history for the files that keep
   changing.
3. **Walk each lens** and note a suspect with its `file:line`, read in this
   session.
4. **Check the fit.** Ask whether the alternative would do what the code does
   today with less code, less upkeep or fewer failures there.
5. **Search the web** for the alternative's current status and for the
   suspect's own. Record the URL.
6. **Respect documented reasons.** A choice the project documents a reason for
   is a re-review candidate only when new evidence overturns that reason. Cite
   both the project document and the new evidence. Without new evidence, drop
   it.
7. **Flag direction.** A candidate that would swap the project's stack, such as
   its language, framework or runtime, is architecture direction. Mark it
   `Direction for the user: yes`; the PM escalates it and does not decide it.

## Output

Plain text, in your report to the PM; no file, no HTML. One block per
candidate:

    Candidate N: <name>
    Lens: <one of the lenses>
    Paths: <target paths>
    Alternative: <the concrete tool or method>
    Source: <URL, and what it says>
    Why here: <why better in this code, file:line, file:line>
    Documented reason: <project doc and the new evidence, or none>
    Direction for the user: yes | no

End with the one candidate you would take first and why. Say when you found
nothing: a scan that reports nothing looks the same as one that died.
