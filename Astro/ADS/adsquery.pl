#!/usr/bin/perl -w

=head1 NAME

 adsquery - tool to query ADS and print out the result

=head1 SYNOPSIS

  adsquery --author="Jenness,T."

=head1 DESCRIPTION

Command line interface to the C<Astro::ADS> classes.
Given some query parameters (such as author) a query is sent
to the ADS and the result is sent to standard output.

=head1 ARGUMENTS

The following arguments are recognized:

=over 4

=item B<--help>

Print a usage message.

=item B<--man>

List the full documentation.

=item B<--version>

The version number.

=item B<--author>

Specify the author to use for the query. Multiple authors can
be specified simply by using the option more than once.

  adsquery --author="Author1" --author="Author2"

=item B<--count>

Simply counts the number of papers that match the query
and exits.

=item B<--useor>

Use OR logic with the author list. Default is to AND the authors
for the query.

=item B<--xml>

Output the results in XML where the element names are the
same as the query fields. The top level element is 
E<lt>ADSResultE<gt>. Default is to print a tabulated ASCII
result.

=item B<--debug>

Turn on debug messages. Default is off.

=back

=cut

use strict;

use Pod::Usage;
use Getopt::Long;

use Astro::ADS::Query;

use vars qw/ $VERSION /;
$VERSION = (qw$Revision: 1.1 $ )[1];

# Init options
my ($help, $man, $version, %opt);
$opt{author} = [];
GetOptions( "help"     => \$help,
	    "man"      => \$man,
	    "version"  => \$version,
	    "author=s" => $opt{author},
	    "useor"    => \$opt{useor},
	    "xml"      => \$opt{xml},
	    "count"    => \$opt{count},
	    "debug"    => \$opt{debug},
	  );

# deal with options that abort
pod2usage(-verbose => 1)  if ($help);
pod2usage(-verbose => 2)  if ($man);

if ($version) {
  print "adsquery Version $VERSION\n";
  exit;
}

# Now form a query
my $query = new Astro::ADS::Query( Authors => $opt{author} );

# Set the author logic
if ($opt{useor}) {
  $query->authorlogic("OR");
} else {
  $query->authorlogic("AND");
}

print "Connecting to ADS\n" if $opt{debug};
my $result = $query->querydb();

print "Received ",scalar($result->papers)," papers\n" if $opt{debug};

if ($opt{count}) {
  print scalar($result->papers),"\n";
  exit;
}



# If we are using XML output print outer element
print "<ADSResult>\n" if $opt{xml};

# Print out each of the papers
if ($opt{xml}) {
  print $result->summary(format => "XML");
} else {
  print "$result";
}

=head1 AUTHORS

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2001 Tim Jenness. All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

