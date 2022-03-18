#!/usr/bin/env bash
# SPDX-FileCopyrightText: Magenta ApS
#
# SPDX-License-Identifier: MPL-2.0

# Run perlcritic on perl scripts.
# By default perlcritic looks for .perlcriticrc in the current directory
# (repository root) and in the home directory. If no configuration file is
# found then it uses --stern and --verbose 8.

set -eux

cmd=perlcritic
if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "This check needs ${cmd} from https://github.com/Perl-Critic/Perl-Critic."
    exit 1
fi

cfg=.perlcriticrc
opts=("--quiet" "--color")
if [[ ! -r "${cfg}" ]] && [[ ! -r "$HOME/${cfg}" ]]; then
    echo "No ${cfg} found"
    exit 1
fi

declare -a exclusions=(
"Perl::Critic::Policy::Modules::RequireExplicitPackage" # as we do not have the entire file, evaluating this rule makes no sense
"Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict" # as we do not have the entire file, evaluating this rule makes no sense
"Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings" # as we do not have the entire file, evaluating this rule makes no sense
"Perl::Critic::Policy::Modules::RequireEndWithOne" # as we do not have the entire file, evaluating this rule makes no sense
)
for exclusion in "${exclusions[@]}"
do
    opts+=("--exclude="$exclusion)
done


failed=false
filtered_input=$(git diff --staged --color=always | perl -wlne 'print $1 if /^\e\[32m\+\e\[m\e\[32m(.*)\e\[m$/' )
output=$(echo $filtered_input | "${cmd}" "${opts[@]}")
# filtered = $(perl -wlne 'print $1 if /^\e\[32m\+\e\[m\e\[32m(.*)\e\[m$/')

if [[ ! -z "${output}" ]]; then
    echo "${output}"
    failed=true
fi

if [[ $failed == "true" ]]; then
    exit 1
fi
