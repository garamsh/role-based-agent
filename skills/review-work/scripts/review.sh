#!/bin/sh
# The git steps of review-work: verify the tree that will land, and land only
# the tree verified. Run from inside the repository under review.
set -eu

usage() {
  cat >&2 <<'EOF'
usage: review.sh record   <base-ref> <head-ref>
       review.sh worktree <base> <head> <dir>
       review.sh guard    <base> <head> <base-ref> <head-ref>
       review.sh authors  <base> <head>
       review.sh landed   <landed-commit> <tree> <base> <head>
exit:  0 pass, 1 refused, 2 usage or git error, 3 merge conflict
EOF
  exit 2
}

die() { printf 'review.sh: error: %s\n' "$1" >&2; exit 2; }

commit() {
  git rev-parse --verify --quiet "$1^{commit}" || die "not a commit: $1"
}

# merge-tree exits 1 for a conflict and higher for a failure; left to set -e
# the two would read alike, and a conflict is a verdict on the pull request
# where a failure is not.
merge() {
  _st=0
  _out=$(git merge-tree --write-tree --name-only "$1" "$2") || _st=$?
  case $_st in
    0) printf '%s\n' "$_out" ;;
    1) printf 'review.sh: CONFLICT merging %s onto %s; conflicted paths:\n' "$2" "$1" >&2
       printf '%s\n' "$_out" | sed '1d; /^$/,$d' >&2
       exit 3 ;;
    *) die "git merge-tree exited $_st" ;;
  esac
}

# One identity per line: the author and every Co-authored-by trailer, which
# git matches without regard to the key's case.
identities() {
  _ids=$(git log "$@" --format='%an <%ae>%n%(trailers:key=Co-authored-by,valueonly)') ||
    die "git log $* failed"
  printf '%s\n' "$_ids" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; /^$/d' | sort -u
}

# --no-merges: a merge that brought the branch up to date carries no one's
# change, and its author is whoever pressed the button.
authors() { identities --no-merges "$1..$2"; }

case ${1:-} in
  record)
    [ $# -eq 3 ] || usage
    b=$(commit "$2"); h=$(commit "$3"); t=$(merge "$b" "$h")
    printf 'base=%s\nhead=%s\ntree=%s\n' "$b" "$h" "$t" ;;

  worktree)
    [ $# -eq 4 ] || usage
    b=$(commit "$2"); h=$(commit "$3"); t=$(merge "$b" "$h")
    [ ! -e "$4" ] || die "$4 already exists"
    # A worktree checks out a commit, not a tree; both parents make the
    # commit read as the merge it stands for.
    c=$(git commit-tree "$t" -p "$b" -p "$h" -m "review-work: verify $h onto $b") ||
      die "git commit-tree failed"
    git worktree add --detach "$4" "$c" >&2 || die "git worktree add $4 failed"
    printf 'tree=%s\ncommit=%s\nworktree=%s\n' "$t" "$c" "$4" ;;

  guard)
    [ $# -eq 5 ] || usage
    b=$(commit "$2"); h=$(commit "$3"); nb=$(commit "$4"); nh=$(commit "$5")
    moved=0
    if [ "$nb" != "$b" ]; then
      printf 'review.sh: REFUSED: base moved: %s is %s, verified %s\n' "$4" "$nb" "$b" >&2
      moved=1
    fi
    if [ "$nh" != "$h" ]; then
      printf 'review.sh: REFUSED: head moved: %s is %s, verified %s\n' "$5" "$nh" "$h" >&2
      moved=1
    fi
    [ "$moved" -eq 0 ] || { echo 'review.sh: do not merge; record and verify again' >&2; exit 1; }
    printf 'base=%s\nhead=%s\n' "$b" "$h" ;;

  authors)
    [ $# -eq 3 ] || usage
    b=$(commit "$2"); h=$(commit "$3")
    authors "$b" "$h" ;;

  landed)
    [ $# -eq 5 ] || usage
    l=$(commit "$2"); b=$(commit "$4"); h=$(commit "$5")
    t=$(git rev-parse --verify --quiet "$3^{tree}") || die "not a tree: $3"
    # As with merge-tree, 1 is an answer and anything higher is a failure.
    _st=0; git merge-base --is-ancestor "$b" "$l" || _st=$?
    case $_st in
      0) ;;
      1) printf 'review.sh: REFUSED: %s does not descend from verified base %s\n' "$l" "$b" >&2; exit 1 ;;
      *) die "git merge-base exited $_st" ;;
    esac
    bad=0
    lt=$(git rev-parse "$l^{tree}")
    if [ "$lt" != "$t" ]; then
      printf 'review.sh: REFUSED: landed tree %s, verified %s\n' "$lt" "$t" >&2
      bad=1
    fi
    want=$(authors "$b" "$h")
    # base..landed covers every merge method: the squash commit alone, or the
    # merge commit with the branch commits it brought.
    have=$(identities "$b..$l")
    missing=$(printf '%s\n' "$want" | while IFS= read -r a; do
      [ -n "$a" ] || continue
      printf '%s\n' "$have" | grep -Fqx -- "$a" || printf '%s\n' "$a"
    done)
    if [ -n "$missing" ]; then
      printf 'review.sh: REFUSED: authors missing from what landed:\n%s\n' "$missing" >&2
      bad=1
    fi
    [ "$bad" -eq 0 ] || exit 1
    printf 'landed=%s\ntree=%s\n' "$l" "$lt" ;;

  *) usage ;;
esac
