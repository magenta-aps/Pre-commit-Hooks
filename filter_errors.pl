#!/usr/bin/env perl
# SPDX-FileCopyrightText: Magenta ApS
#
# SPDX-License-Identifier: MPL-2.0

use strict;
use warnings;
use utf8;

my %wanted_lines = map { $_ => 1 } split ' ', $ARGV[0];

while (my $line = <STDIN>) {
    chomp($line);
    my ($line_no) = $line =~ m!(\d+):!;
    next unless $line_no;
    next unless $wanted_lines{$line_no};
    print "$line\n";
}
