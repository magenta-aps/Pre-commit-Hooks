#!/usr/bin/env bash
# SPDX-FileCopyrightText: Magenta ApS
#
# SPDX-License-Identifier: MPL-2.0

##### REDMINE ISSUE NO. CHECKER #####
# A small script that verifies the presence of a redmine ticket no. in the commit msg header
# If not present, will try to find issue no. in current branch name and add to commit msg header
# Optionally respects fixup! and squash! commits
# If all params are set to true, script will operate silently on fail & on success
# Use with caution. Suggestions/improvements/feedback -> emt@magenta.dk

### Known issues/limitations ###
# Requires GNU grep - not tested on MacOS/BSD although a ggrep workaround has been implemented
# Funky behaviour when committing while in detached HEAD state (nothing breaks, though)
# Only checks for existing ticket no. in first line of commit msg (can be changed)

# Check if user has GNU grep, look for ggrep if not
if ! grep -V | grep -q GNU; then
  printf "Your version of grep is not GNU grep. Falling back to ggrep ... "
  command -v ggrep >/dev/null 2>&1 || { echo >&2 "ggrep is not installed.  Aborting."; exit 0; }
  alias grep="ggrep" # If the above didn't exit early, we should be good
  echo "OK"
fi

### CONFIGURATION ###
# Set this to always assume a non-existing issue no. is an issue (pun intended)
SKIP_QUESTION=true

# If a five-digit number has been found in the branch name, auto-replace commit msg header
SKIP_CONFIRMATION=true

# Skip output
QUIET_MODE=true

# Don't abort commit if unable to find issue no. in .git/HEAD
IGNORE_NON_MATCH=true

# Don't modify fixup commits that will be autosquashed
IGNORE_FIXUPS=true


### SCRIPT ###
# Helper function for skipping output
function ekko() {
    if [ ! $QUIET_MODE = true ]; then
        echo "$1"
    fi
}

# Set PATTERN to look for [#12345] and optionally fixup! and squash!
PATTERN="\[#\d{5}\]"
if [ $IGNORE_FIXUPS = true ]; then
    PATTERN="(\[#\d{5}\]|fixup\!|squash\!)"
fi

# Check for pattern in first line of commit msg (use cat instead of head to check entire msg)
if ! head -n 1 "$1" | grep -q -P "$PATTERN"; then

    # Ask user whether this is an issue
    if [ ! $SKIP_QUESTION = true ]; then
	read -p "You're about to add a commit without an issue #, are you sure? [y|n] " -n 1 -r < /dev/tty
    	echo
    	if ! echo "$REPLY" | grep -E '^[Nn]$' > /dev/null; then
            ekko "Ok, committing as usual"
            exit 0
        fi
    fi

    # Capture ticket no. from branch name
    TICKET=$(git rev-parse --abbrev-ref HEAD | grep -P -o "(\d{5})")

    # Handle non-match
    if [ -z "$TICKET" ]; then
        if [ ! $IGNORE_NON_MATCH = true ]; then
            ekko "Could not find ticket no. in HEAD, aborting"
            exit 1
        else
            ekko "Could not find ticket no., ignoring error"
            exit 0
        fi
    fi

    NEW_COMMIT_MSG=$(sed -r "1s;^(\w+:\s)?;\1[#$TICKET] ;" "$1")
    ekko "Found ticket no. in branch name. Here is your new commit message header:"
    ekko "$NEW_COMMIT_MSG"

    # Optionally ask user for confirmation
    if [ ! $SKIP_CONFIRMATION = true ]; then
        read -p "Confirm [y|n] " -n 1 -r < /dev/tty
        echo
        if echo "$REPLY" | grep -E '^[Nn]$' > /dev/null; then
            echo "Ok, aborting commit"
            exit 1
        fi
    fi
    sed -r -i "1s;^(\w+:\s)?;\1[#$TICKET] ;" "$1"
fi
