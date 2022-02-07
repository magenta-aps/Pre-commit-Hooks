#!/usr/bin/env bash
# SPDX-FileCopyrightText: Magenta ApS
#
# SPDX-License-Identifier: MPL-2.0
COMMIT_MSG_FILE=$1

# If the GIT_EDITOR is set to ':', it means we are in
# the middle of a merge or another situation where there
# is no user input. In this case, we keep the default
# message proposed by Git.
if [[ "$GIT_EDITOR" == ":" ]]; then
  exit 0
fi

# Get the branch name
ref=$(git rev-parse --abbrev-ref HEAD)
# Look for five consecutive digits in branch name
if [[ $ref =~ ([0-9]{5}) ]]; then
  # Store original commit help text in temp string
  orig_msg=$(<"$COMMIT_MSG_FILE")
  # Extract ticket no. from regex match and wrap in [#]
  ticket="[#${BASH_REMATCH[1]}]"
  # Bring it all together
  echo "$ticket " > "$COMMIT_MSG_FILE"
  echo "$orig_msg" >> "$COMMIT_MSG_FILE"
fi
