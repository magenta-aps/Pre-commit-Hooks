#!/usr/bin/env perl
# SPDX-FileCopyrightText: Magenta ApS
#
# SPDX-License-Identifier: MPL-2.0

use strict;
use warnings;
use utf8;

my @changed_lines;
while (my $line = <STDIN>) {
    next unless $line =~ m!^\d+!;
    if (index($line, ',') != -1) {
	my ($first_line, $no_of_lines) = split ',', $line;
	push @changed_lines, ($first_line + $_) for 0..$no_of_lines;
    } else {
	push @changed_lines, int $line;
    }
}

print "@changed_lines";
