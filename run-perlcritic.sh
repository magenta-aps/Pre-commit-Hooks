#!/usr/bin/env bash
# SPDX-FileCopyrightText: Magenta ApS
#
# SPDX-License-Identifier: MPL-2.0

# Run perlcritic on perl scripts.
# By default perlcritic looks for .perlcriticrc in the current directory
# (repository root) and in the home directory. If no configuration file is
# found then it exits.
set -u

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

# additional exclusions for quirks related to using a diff and not entire files
declare -a exclusions=(
"Perl::Critic::Policy::Modules::RequireExplicitPackage" # as we do not have the entire file, evaluating this rule makes no sense
"Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict" # as we do not have the entire file, evaluating this rule makes no sense
"Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings" # as we do not have the entire file, evaluating this rule makes no sense
"Perl::Critic::Policy::Modules::RequireEndWithOne" # as we do not have the entire file, evaluating this rule makes no sense
)
for exclusion in "${exclusions[@]}"
do
    opts+=("--exclude=$exclusion")
done

ORANGE='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
failed="false"
for changed_perl_file in "$@"; do
    diff_input=$(git diff --staged --color=always "$changed_perl_file")
    # filters staged diff to only include changed lines, https://stackoverflow.com/questions/25497881/git-diff-is-it-possible-to-show-only-changed-lines
    # perl -wlne: -w=`warnings`, -l="newline at each line", -n="tells perl to implicitly include a loop as the second option", -e=`execute`
    filtered_input=$( echo "$diff_input"  | perl -wlne 'print $1 if /^\e\[32m\+\e\[m\e\[32m(.*)\e\[m$/' )
    my_output=$(echo "$filtered_input" | "${cmd}" "${opts[@]}")
    if [[ -n "${my_output}" ]]; then
        echo "***************************"
        echo
        echo -e "${ORANGE}Found error(s) in diff of ${CYAN}$changed_perl_file ${NC}"
        echo "${filtered_input}" | cat -n
        echo "${my_output}"
        echo
        failed="true"
    fi
done

if [[ "${failed}" == "true" ]]; then
    exit 1
fi
