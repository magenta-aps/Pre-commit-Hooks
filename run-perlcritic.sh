#!/usr/bin/env bash
# SPDX-FileCopyrightText: Magenta ApS
#
# SPDX-License-Identifier: MPL-2.0

# Run perlcritic on perl scripts.
# By default perlcritic looks for .perlcriticrc in the current directory
# If no configuration file is found, then it exits.
set -u

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cmd=perlcritic
if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "This check needs ${cmd} from https://github.com/Perl-Critic/Perl-Critic."
    exit 1
fi

cfg=.perlcriticrc
opts=("--quiet" "--color" "-verbose=%l: %m\n")
if [[ ! -r "${cfg}" ]]; then
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

RED='\033[0;31m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
failed="false"
for changed_perl_file in "$@"; do
    diff_ranges=$(git diff --staged --unified=0 "$changed_perl_file" |\
	    grep -Po '^\+\+\+ ./\K.*|^@@ -[0-9]+(,[0-9]+)? \+\K[0-9]+(,[0-9]+)?(?= @@)' |\
	    perl "$SCRIPT_DIR/parse_ranges.pl")
    my_output=$("${cmd}" "${opts[@]}" "$changed_perl_file")
    filtered_output=
    if [[ -n "${my_output}" ]]; then
        filtered_output=$(echo "$my_output" | perl "$SCRIPT_DIR/filter_errors.pl" "$diff_ranges")
    fi

    if [[ -n "${filtered_output}" ]]; then
        echo "***************************"
        echo
        echo -e "${ORANGE}Found error(s) in diff of ${CYAN}$changed_perl_file ${NC}"
        echo -e "${RED}${filtered_output}${NC}"
        echo
        failed="true"
    fi
done

if [[ "${failed}" == "true" ]]; then
    exit 1
fi
