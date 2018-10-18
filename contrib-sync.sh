#!/bin/bash
# # # # # # # # # # #
# contrib-sync https://github.com/jasonk/contrib-sync
# Copyright 2018 Jason Kohles <email@jasonkohles.com>
# License: MIT
# # # # # # # # # # #

### CONFIGURATION OPTIONS ###
# These options will be passed to git log and are used to determine
# what commits will be imported from the target repositories.  If you
# want to see what commits will get synced for a particular repository,
# go to that repo and run `git log` with the options you set here.
GIT_LOG_OPTIONS=(
  # You might want to change the value here, if you have commits that
  # show up differently from what is in your git config.  For example,
  # I have some where the author is listed as "Jason Kohles" and some
  # where it's "Kohles, Jason", so I use --author="Kohles" here
  # (though this probably won't work as well if your name is Smith!)
  --author="$(git config user.name)"

  # If you run this frequently you could change this to a shorter
  # value to make the script run faster.  This script won't duplicate
  # commits, so you don't have to worry about setting an exact value
  # here, this just controls how far back it looks in your repos for
  # commits.  You probably want to comment this option out the first
  # time you run it, to import your entire history.
  --since="1 month ago"
)
# This is a list of directories to examine when looking for commits.
# You can list repos directly here, or provide a directory that
# contains repos.  For each directory in this list, if that directory
# contains a .git directory then it will be inspected for commits.  If
# it doesn't contain a .git directory then all of it's subdirectories
# that contain .git directories will be inspected (only one deep, it's
# not recursive)
REPOS=(
  ~/my-repos
)

### END OF CONFIGURATION ###
set -e

datecmd="$(command -v gdate date | head -1)"

git log --oneline --format="%s" > existing.txt

warn() {
  echo "$@" 1>&2
}
die() {
  warn "$@"
  exit 1
}

get_commits_for_repo() {
  local DIR="$1"
  if [ ! -d "$DIR/.git" ]; then
    warn "Skipping $DIR - It is not a git repository"
    return
  fi
  # This attempts to prevent some commits from getting double-counted,
  # by ignoring repos that have a github.com remote.  Since GitHub is
  # counting these repos directly when they get pushed you probably
  # don't want to replicate their commits.
  if git -C "$DIR" remote -v | grep -q 'github\.com'; then
    warn "Skipping $DIR - It has a github.com remote"
    return
  fi
  git -C "$DIR" --no-pager log --all --oneline --no-merges \
    --pretty="tformat:%at %H" "${GIT_LOG_OPTIONS[@]}"
}

(
  for I in "${REPOS[@]}"; do
    if [ ! -d "$I" ]; then
      warn "Skipping $I - Not a directory"
      continue
    fi
    if [ -d "$I/.git" ]; then
      get_commits_for_repo "$I"
    else
      for J in "$I"/*; do
        if [ -d "$J/.git" ]; then get_commits_for_repo "$J"; fi
      done
    fi
  done
) | sort -n | while read -r TIME HASH; do
  DATE="$("$datecmd" -R --date="@$TIME")"
  if grep -Eq "$HASH" existing.txt; then
    echo "SKIPPING: $TIME $HASH $DATE"
  else
    echo "ADDING: $TIME $HASH $DATE"
    echo "$HASH" >> existing.txt
    GIT_COMMITTER_DATE="$DATE" GIT_AUTHOR_DATE="$DATE" \
      git commit --allow-empty -m "$HASH"
  fi
done
