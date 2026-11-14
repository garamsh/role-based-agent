---
name: meet-deadline
description: Runs a goal against a deadline for the PM by cutting waiting, never quality — a goal branch, review-only PRs, one final verification, shared indexes updated once. Use when a goal is urgent, has a deadline, must finish by today, or the user says to skip waiting on per-PR verification.
license: Apache-2.0
metadata:
  version: "1.0.0"
---

# Meet a deadline

The PM operates this; every step is the PM's. It is `delegate-goal`'s run for
a goal whose urgency is deadline. It trades waiting time only: on a naru run
of 47 PRs, per-PR verification was 27% of the 77-hour span, while review found
real defects in about half the PRs.

1. **Branch.** Cut a goal branch from the default branch; every worker's PR
   targets it. The default branch takes nothing until step 7, so it stays
   verified throughout.
2. **Disjoint paths.** Give workers pairwise-disjoint paths, and tell them not
   to rebase on each other. Both real conflicts on that run were in one shared
   index, and each rebase forces a re-review.
3. **Shared indexes.** Files many PRs touch belong to the PM alone, updated
   once, after the last PR merges. Workers leave them untouched.
4. **Review only.** Review each PR into the goal branch with `review-pr` and
   merge on approve, without verification. Every finding is still a finding.
   Verifying each PR on a branch that moves with every merge would repeat the
   12 re-verifications after the base moved (3.7 hours).

   `review-pr` changes at these steps:
   - Step 2: skip the worktree and verification.
   - Step 6: report verification as `deferred to final check`, not passed.
   - Step 8: skip `guard`, which protects a verified tree none exists of.
     Still run `authors`, and keep every author in the squash.
   - Step 9: skip the tree comparison; confirm the authors landed.

   Steps 1, 3, 4, 5 and 7 apply unchanged, the independent reviewer and the
   short path included.
5. **Final check.** After the last PR merges and the indexes are updated,
   fetch. If the default branch moved, merge it into the goal branch first.
   Run the changed paths and their dependents where the project defines how
   to find them; where it does not, run the full suite. Never guess a subset.
   Run it once.
6. **Failures.** Trace each failure to the PR that caused it and fix it on the
   goal branch, then re-run what the fix touched and its dependents.
7. **Land.** Run `review-pr` steps 8 and 9 with the goal branch as head. If the
   default branch moved since step 5, go back to step 5: verify the tree that
   will land. The default branch takes exactly the verified tree.

## Not shortcuts

`agents/pm.md` §Deciding's three-way test still applies. A design that makes
only the feature work, a skipped test or a stubbed path does not pass, however
near the deadline: it is debt the next goal pays. When the deadline cannot be
met without one, escalate; the user cuts scope.
