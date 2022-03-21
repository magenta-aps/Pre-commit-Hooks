#!/usr/bin/env perl
# SPDX-FileCopyrightText: Magenta ApS
#
# SPDX-License-Identifier: MPL-2.0

use strict;
use warnings;
use utf8;

my %wanted_lines = map { $_ => 1 } @ARGV;

while (my $line = <STDIN>) {
    chomp($line);
    print STDERR "Line: $line\n";
    my $line_no = $line =~ m!(\d+):!;
    next unless $wanted_lines{$line_no};
    print "$line\n";
}
