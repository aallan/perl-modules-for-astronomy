package Astro::Catalog::Query::SkyCat;

=head1 NAME

Astro::Catalog::Query::SkyCat - Generate SkyCat catalogue query clients

=head1 SYNOPSIS

=head1 DESCRIPTION

On load, automatically parse the SkyCat server specification file
from C<~/.skycat/skycat.cfg>, if available, and dynamically 
generate query classes that can send queries to each catalog
server and parse the results.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use vars qw/ $VERSION $FOLLOW_DIRS $DEBUG /;

use Carp;
use File::Spec;
use LWP::UserAgent;
use Net::Domain qw(hostname hostdomain);


$VERSION = '0.01';
$DEBUG = 1;

# Controls whether we follow 'directory' config entries and recursively
# expand those. Default to false at the moment.
$FOLLOW_DIRS = 1;

# This is the content of the config file
my %CONFIG;

=head1 METHODS

=head2 Constructor

=item B<new>

Simple constructor. Forces read of config file if one can be found and
the config has not been read previously. If no config file can be located
the query object can not be instantiated since it will not know the
location of any servers.

 $q = new Astro::Catalog::Query::SkyCat( config => '/tmp/skycat.cfg',

Currently only one config file is supported at any given time.
If a config file is changed (see the C<cfg_file> class method)
the current config is overwritten automatically.

=cut

sub new {
  croak "Not Yet implemented\n";
}

=head2 Class methods

These methods are not associated with any particular object.

=item B<cfg_file>

Location of the skycat config file. Default location is
C<$SKYCAT_CFG>, if defined, else C<$HOME/.skycat/skycat.cfg>.

=cut

{
  my $cfg_file = (exists $ENV{SKYCAT_CFG} ? $ENV{SKYCAT_CFG} :
		  File::Spec->catfile( $ENV{HOME}, ".skycat", "skycat.cfg"));

  sub cfg_file {
    my $class = shift;
    if (@_) {
      $cfg_file = shift;
      $class->_load_config() || ($cfg_file = undef);
    }
    return $cfg_file;
  }

}

=begin __PRIVATE_METHODS__

=over 4

=item B<_load_config>

Class method to load the skycat config information into
the class and configure the modules.

  $class->_load_config() or die "Error loading config";

The config file name is obtained from the C<cfg_file> method.
Returns true if the file was read successfully and contained at
least one catalog server. Otherwise returns false.

=cut

sub _load_config {
  my $class = shift;
  my $cfg = $class->cfg_file;

  if (!defined $cfg) {
    warnings::warnif("Config file not specified (undef)");
    return;
  }

  unless (-e $cfg) {
    my $xcfg = (defined $cfg ? $cfg : "<undefined>" );
    return;
  }

  my $fh;
  unless (open $fh, "<$cfg") {
    warnings::warnif( "Specified config file, $cfg, could not be opened: $!");
    return;
  }

  # Need to read the contents into an array
  my @lines = <$fh>;

  # Process the config file and extract the raw content
  my @configs = $class->_extract_raw_info( \@lines );

  # Close file
  close( $fh ) or do {
    warnings::warnif("Error closing config file, $cfg: $!");
    return;
  };

  # Process each entry. Mainly URL processing
  for my $entry ( @configs ) {

    # Extract info from the 'url'. We need to extract the following info:
    #  - Host name and port
    #  - remaining url path
    #  - all the CGI options including the static options
    # Note that at the moment we do not do token replacement (the
    # rest of the REST architecture expects to get the above
    # information separately). This might well prove to be silly
    # since we can trivially replace the tokens without having to
    # reconstruct the url. Of course, this does allow us to provide
    # mandatory keywords. $url =~ s/\%ra/$ra/;
    if ($entry->{url} =~ /^http:\/\/([\w\.]+(?::\d+)?)\/([\w\/-]+\?)(.*)\s*/) {
      $entry->{remote_host} = $1;
      $entry->{url_path} = $2;
      my $options = $3;

      # if first character is & we append that to url_path since it
      # is an empty argument
      $entry->{url_path} .= "&" if $options =~ s/^\&//;

      my @opt = split(/&/, $options);
      my %all;
      for my $o (@opt) {
	my ($key, $value) = split("=", $o);
	$all{$key} = $value;

	# For tokenized options we need to convert them
	# to some indication that 'radmax' is required from the
	# presence of %r2. For other options that have fixed values
	# we need to store them for later

      }
      $entry->{options} = \%all;
    }

  }

  # Debug
  use Data::Dumper;
  print Dumper(\@configs);

}

=item B<_extract_raw_info>

Go through a skycat.cfg file and extract the raw unprocessed entries
into an array of hashes. The actual content of the file is passed
in as a reference to an array of lines.

  @entries = $class->_extract_raw_info( \@lines );

This routine is separate from the main load routine to allow recursive
calls to remote directory entries.

=cut

sub _extract_raw_info {
  my $class = shift;
  my $lines = shift;

  # Now read in the contents
  my $current; # Current server spec
  my @configs; # Somewhere temporary to store the entries

  for my $line (@$lines) {

    # Skip comment lines and blank lines
    next if $line =~ /^\s*\#/;
    next if $line =~ /^\s*$/;

    if ($line =~ /^(\w+):\s*(.*?)\s*$/) {
      # This is content
      my $key = $1;
      my $value = $2;
      # Assume that serv_type is always first 
      if ($key eq 'serv_type') {
	# Store previous config if it contains something
	# If it actually contains information on a serv_type of
	# directory we can follow the URL and recursively expand
	# the content
	push(@configs, $class->_dir_check( $current ));

	# Clear the config and store the serv_type
	$current = { $key => $value  };

      } else {
	# Just store the key value pair
	$current->{$key} = $value;
      }

    } else {
      # do not know what this line signifies since it is
      # not a comment and not a content line
      warnings::warnif("Unexpected line in config file: $line\n");
    }

  }

  # Last entry will still be in %$current so store it if it contains
  # something.
  push(@configs, $class->_dir_check( $current ));

  # Return the entries
  return @configs;
}

=item B<_dir_check>

If the supplied hash reference has content, look at the content
and decide whether you simply want to keep that content or 
follow up directory specifications by doing a remote URL call
and expanding that directory specification to many more remote
catalogue server configs.

 @configs = $class->_dir_check( \%current );

Returns the supplied argument, additional configs derived from
that argument or nothing at all.

Do not follow a 'directory' link if we have already followed a link with
the same short name. This prevents infinite recursion when the catalog
pointed to by 'catalogs@eso' itself contains a reference to 'catalogs@eso'.

=cut

my %followed_dirs;
sub _dir_check {
  my $class = shift;
  my $current = shift;

  if (defined $current && %$current) {
    if ($current->{serv_type} eq 'directory') {
      # Get the content of the URL unless we are not
      # reading directories
      if ($FOLLOW_DIRS && defined $current->{url} && 
	  !exists $followed_dirs{$current->{short_name}}) {
	print "Following directory link to ". $current->{short_name}."\n" if $DEBUG;

	# Indicate that we have followed this link
	$followed_dirs{$current->{short_name}} = $current->{url};

	# Retrieve the url, pass that array to the raw parser and then
	# return any new configs to our caller
	# Must force scalar context to get array ref
	# back rather than a simple list.
	return $class->_extract_raw_info(scalar $class->_get_url( $current->{url} ));
      }
    } else {
      # Not a 'directory' so this is a simple config entry. Simply return it.
      return ($current);
    }
  }

  # return empty list since we have no value
  return ();
}


=item B<_get_url>

Returns the content of the remote URL supplied as argument. In scalar
context returns reference to array of lines. In list context returns
the lines in a list.

 \@lines = $class->_get_url( $url );
 @lines = $class->_get_url( $url );

=cut

sub _get_url {
  my $class = shift;
  my $url = shift;

  # This should be reused from Transport::REST
  # build request
  my $ua = new LWP::UserAgent( timeout => 30 );
  my $HOST = hostname();
  my $DOMAIN = hostdomain();
  $ua->agent( __PACKAGE__ . "/$VERSION ()");
  my $request = new HTTP::Request('GET', $url);

  # grab page from web
  my $reply = $ua->request($request);

  my $content;
  if ( ${$reply}{"_rc"} eq 200 ) {
    # Success
    $content = ${$reply}{"_content"};
  } else {
    # Got nothing
    warnings::warnif("Failed to follow directory link: $url\n");
  }

  # Need an array
  my @lines;
  @lines = split("\n", $content) if defined $content;

  if (wantarray) {
    return @lines;
  } else {
    return \@lines;
  }
}

=item B<_token_mapping>

Provide a mapping of tokens found in SkyCat config files to the
internal values used generically by Astro::Catalog::Query classes.

 %map = $class->_token_mappings;

Keys are skycat tokens.

=cut

sub _token_mapping {
  return (
	  id => 'id',

	  ra => 'ra',
	  dec => 'dec',

	  # Arcminutes
	  r1 => 'radmin',
	  r2 => 'radmax',
	  w  => 'width',
	  h  => 'height',

	  n => 'number',

	  # which filter???
	  m1 => 'magfaint',
	  m2 => 'magbright',

	  # Not Yet Supported
	  cols => undef,
	  'mime-type' => undef,
	 );
}

=back

=end __PRIVATE_METHODS__

=head1 NOTES

'directory' entries are not followed by default although the class
can be configured to do so by setting 

 $Astro::Catalog::Query::SkyCat::FOLLOW_DIRS = 1;

to true.

This class could simply read the catalog config file and allow queries
on explicit servers directly rather than going to the trouble of
auto-generating a class per server. This has the advantage of allowing
a user to request USNO data from different servers rather than generating
a single USNO class. ie

  my $q = new Astro::Catalog::Query::SkyCat( catalog => 'usnoa@eso',
                                             target => 'HL Tau',
                                             radius => 5 );

as opposed to

    my $q = new Astro::Catalog::Query::USNOA( target => 'HL Tau',
                                              radius => 5 );

What to do with catalogue mirrors is an open question. Of course,
convenience wrapper classes could be made available that simply delegate
the calls to the SkyCat class.

=head1 SEE ALSO

SkyCat FTP server. [URL goes here]

SSN75 [http://www.starlink.rl.ac.uk/star/docs/ssn75.htx//ssn75.html]
by Clive Davenhall.

=head1 BUGS

At the very least for testing, an up-to-date skycat.cfg file
should be distributed with this module. Whether it should be
used by this module once installed is an open question (since
many people will not have a version in the standard location).

=head1 COPYRIGHT

Copyright (C) 2001-2003 University of Exeter and Particle Physics and
Astronomy Research Council. All Rights Reserved.

This program was written as part of the eSTAR project and is free
software; you can redistribute it and/or modify it under the terms of
the GNU Public License.

=head1 AUTHORS

Tim Jenness E<lt>tjenness@cpan.orgE<gt>,
Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>

=cut

1;
