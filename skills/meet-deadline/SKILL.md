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
of 47 PRs, per-PR verification was 27% of the 77-hour span, while about half of
review's findings were real defects.

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

   Of `review-pr`, skip step 2's worktree and verification, and step 8's wait
   for CI or update-branch. Step 6 reports verification as `deferred to final
   check`, not passed. The rest applies, `record`, `guard`, `authors`, `landed`
   and the independent reviewer included: `guard` still refuses a head pushed
   after review. When it refuses only because another goal PR merged,
   re-record; nothing is re-verified.
5. **Final check.** After the last PR merges and the indexes are updated,
   fetch. If the default branch moved, merge it into the goal branch. Run
   `review-pr` step 2 on that pair: the changed paths and their dependents
   where the project defines how to find them; where it does not, the full
   suite. Never guess a subset.
6. **Failures.** Trace each failure to the PR that caused it. A worker fixes
   it in a PR into the goal branch, reviewed as in step 4; then re-run what it
   touched and its dependents.
7. **Land.** Open the goal branch's PR into the default branch and take
   `review-pr` steps 6 to 9. Verification counts as passed only for the
   recorded tree. If the default branch moved, go back to step 5: verify the
   tree that will land. The default branch takes exactly the verified tree.

## Not shortcuts

`agents/pm.md` §Deciding's three-way test still applies. A design that makes
only the feature work, a skipped test or a stubbed path does not pass, however
near the deadline: it is debt the next goal pays. When the deadline cannot be
met without one, escalate; the user cuts scope.
