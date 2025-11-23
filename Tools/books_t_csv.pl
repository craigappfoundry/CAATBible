#!/usr/bin/env perl
use strict;
use warnings;

my $output_file = 'CAAT_verses.csv';
my $id = 1;

# Find all matching files in current directory
my @files = sort glob('[0-9][0-9] *.txt');

die "No matching files found (expected format: '01 Genesis.txt')\n" unless @files;

open my $out, '>', $output_file or die "Cannot open $output_file: $!\n";
print $out "id,book_id,chapter,verse,text\n";

for my $file (@files) {
	# Extract book_id from filename (e.g., "20 Proverbs.txt" -> 20)
	my ($book_id) = $file =~ /^(\d+)/;
	$book_id = int($book_id);  # Remove leading zeros
	
	open my $fh, '<', $file or do {
		warn "Cannot open $file: $!\n";
		next;
	};
	
	my $chapter = 0;
	my $current_verse = 0;
	my $current_text = '';
	
	while (my $line = <$fh>) {
		chomp $line;
		
		# Skip empty lines
		next if $line =~ /^\s*$/;
		
		# Check for chapter heading
		if ($line =~ /^Chapter\s+(\d+)\s*$/i) {
			# Save previous verse if exists
			if ($current_verse > 0 && $current_text ne '') {
				write_verse($out, $id++, $book_id, $chapter, $current_verse, $current_text);
			}
			$chapter = int($1);
			$current_verse = 0;
			$current_text = '';
			next;
		}
		
		# Check for new verse (line starting with number)
		if ($line =~ /^(\d+)\s+(.*)$/) {
			# Save previous verse if exists
			if ($current_verse > 0 && $current_text ne '') {
				write_verse($out, $id++, $book_id, $chapter, $current_verse, $current_text);
			}
			$current_verse = int($1);
			$current_text = trim($2);
		}
		# Continuation of current verse
		elsif ($current_verse > 0) {
			my $trimmed = trim($line);
			if ($trimmed ne '') {
				$current_text .= ' ' . $trimmed;
			}
		}
		# Otherwise ignore (book name, etc.)
	}
	
	# Don't forget the last verse in the file
	if ($current_verse > 0 && $current_text ne '') {
		write_verse($out, $id++, $book_id, $chapter, $current_verse, $current_text);
	}
	
	close $fh;
}

close $out;
print "Wrote " . ($id - 1) . " verses to $output_file\n";

sub trim {
	my $s = shift;
	$s =~ s/^\s+//;
	$s =~ s/\s+$//;
	return $s;
}

sub csv_field {
	my $text = shift;
	# Quote if contains comma, quote, or newline
	if ($text =~ /[",\n\r]/) {
		# Escape quotes by doubling them
		$text =~ s/"/""/g;
		return '"' . $text . '"';
	}
	return $text;
}

sub write_verse {
	my ($fh, $id, $book_id, $chapter, $verse, $text) = @_;
	# Trim any extra whitespace that may have accumulated
	$text = trim($text);
	# Collapse multiple spaces into one
	$text =~ s/\s+/ /g;
	print $fh "$id,$book_id,$chapter,$verse," . csv_field($text) . "\n";
}
