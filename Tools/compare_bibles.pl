#!/usr/bin/env perl
use strict;
use warnings;

die "Usage: $0 <bible1.csv> <bible2.csv>\n" unless @ARGV == 2;

my ($file1, $file2) = @ARGV;
my $books_file = 'CAAT_books.csv';
my $output_file = 'compare_report.txt';

# Load book names
my %book_names;
open my $bfh, '<', $books_file or die "Cannot open $books_file: $!\n";
my $header = <$bfh>;  # Skip header
while (my $line = <$bfh>) {
	chomp $line;
	my ($id, $name) = split /,/, $line;
	$book_names{$id} = $name;
}
close $bfh;

# Load verses from each file
my $verses1 = load_verses($file1);
my $verses2 = load_verses($file2);

# Find differences
my @only_in_1;
my @only_in_2;

for my $key (keys %$verses1) {
	push @only_in_1, $key unless exists $verses2->{$key};
}

for my $key (keys %$verses2) {
	push @only_in_2, $key unless exists $verses1->{$key};
}

# Sort by book_id, chapter, verse
@only_in_1 = sort_verses(@only_in_1);
@only_in_2 = sort_verses(@only_in_2);

# Write report
open my $out, '>', $output_file or die "Cannot open $output_file: $!\n";

print $out "Bible Verse Comparison Report\n";
print $out "=" x 50 . "\n\n";
print $out "File 1: $file1\n";
print $out "File 2: $file2\n\n";

print $out "-" x 50 . "\n";
print $out "Verses in $file1 but NOT in $file2: " . scalar(@only_in_1) . "\n";
print $out "-" x 50 . "\n";
if (@only_in_1) {
	for my $key (@only_in_1) {
		print $out format_verse($key) . "\n";
	}
} else {
	print $out "(none)\n";
}

print $out "\n";
print $out "-" x 50 . "\n";
print $out "Verses in $file2 but NOT in $file1: " . scalar(@only_in_2) . "\n";
print $out "-" x 50 . "\n";
if (@only_in_2) {
	for my $key (@only_in_2) {
		print $out format_verse($key) . "\n";
	}
} else {
	print $out "(none)\n";
}

close $out;
print "Report written to $output_file\n";

sub load_verses {
	my $file = shift;
	my %verses;
	
	open my $fh, '<', $file or die "Cannot open $file: $!\n";
	my $header = <$fh>;  # Skip header
	
	while (my $line = <$fh>) {
		chomp $line;
		# Parse CSV - handle quoted fields
		my ($id, $book_id, $chapter, $verse) = parse_csv_line($line);
		my $key = "$book_id,$chapter,$verse";
		$verses{$key} = 1;
	}
	
	close $fh;
	return \%verses;
}

sub parse_csv_line {
	my $line = shift;
	my @fields;
	
	while ($line =~ /(?:^|,)("(?:[^"]|"")*"|[^,]*)/g) {
		my $field = $1;
		# Remove surrounding quotes and unescape doubled quotes
		if ($field =~ /^"(.*)"$/s) {
			$field = $1;
			$field =~ s/""/"/g;
		}
		push @fields, $field;
	}
	
	return @fields;
}

sub sort_verses {
	my @keys = @_;
	return sort {
		my ($a_book, $a_ch, $a_vs) = split /,/, $a;
		my ($b_book, $b_ch, $b_vs) = split /,/, $b;
		$a_book <=> $b_book || $a_ch <=> $b_ch || $a_vs <=> $b_vs;
	} @keys;
}

sub format_verse {
	my $key = shift;
	my ($book_id, $chapter, $verse) = split /,/, $key;
	my $book_name = $book_names{$book_id} // "Book $book_id";
	return "$book_name $chapter:$verse ($book_id,$chapter,$verse)";
}
