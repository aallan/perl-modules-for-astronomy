package eSTAR::LDAP::Search;

require 5.005_62;
use strict;
use vars qw/ $VERSION /;
use warnings;
use Net::LDAP;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
'$Revision: 1.2 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);


####
# constructor - takes these arguments:

#  host - the hostname of the machine that the mds is running on to do
#         the query against

#  port - the mds port number (if undef, then the default port will
#         be used (2135)

#  branchpoint - Location in DIT from which to start the search. The
#                default is "o=eSTAR"

#  filter - mds search filter

#  timeout - time in seconds before the command will time out (can be omitted
#            or filled with undef to get the default of 30 seconds)

# example1: $mds = eSTAR::LDAP::Search->new(
#                            "computator.ncsa.uiuc.edu","2000",
#                            "o=Grid","(objectclass=GlobusLoadInformation)",
#                            $timeout);
# all options filled in

# example2: $mds = eSTAR::LDAP::Search->new(
#                            "computator.ncsa.uiuc.edu",undef,
#                            "o=Grid","(objectclass=GlobusLoadInformation)",
#                             undef);
#
# both optional parameters left out, but with undef in as placeholders

# example3: $mds = eSTAR::LDAP::Search->new(
#                             "computator.ncsa.uiuc.edu",undef,
#                             "o=Grid","(objectclass=GlobusLoadInformation)");
#
# both optional paramters left out, but timeout was left off entirely
####

sub new {
   my $class  = shift;
   my $self = bless({},$class);
   my $arg = &_options;

   $self->{'entries'} = []; # A reference to an array

   $self->{'host'}   = $arg->{host};
   $self->{'branch'} = $arg->{branch};
   $self->{'filter'} = $arg->{filter};

   #gotta have these args
   if(
         !defined($self->{'host'}  )
      || !defined($self->{'branch'})
      || !defined($self->{'filter'})
     ) {
      return undef;
   }

   ###set the optional args if need be
   if(defined($arg->{'port'})) { $self->{'port'} = $arg->{'port'};}
   else { $self->{'port'} = 2135; }
   if(defined($arg->{'timeout'})) { $self->{'timeout'} = $arg->{'timeout'};}
   else { $self->{'timeout'} = 30; }

   return $self;

}

sub _options {
  my %ret = @_;
  my $once = 0;
  for my $v (grep { /^-/ } keys %ret) {
    require Carp;
    $once++ or Carp::carp("deprecated use of leading - for options");
    $ret{substr($v,1)} = $ret{$v};
  }

  $ret{control} = [ map { (ref($_) =~ /[^A-Z]/) ? $_->to_asn : $_ }
                      ref($ret{control}) eq 'ARRAY'
                        ? @{$ret{control}}
                        : $ret{control}
                  ]
    if exists $ret{control};

  \%ret;
}



###
# runs the actual search on the ldap db, then returns an array of entries
# or undef if it failed for some reason.
###
sub execute {
   my $self = shift;
   my $ldap = Net::LDAP->new(
                             $self->{'host'},
                             port => "$self->{'port'}",
                             timeout =>  "$self->{'timeout'}"
                             );
   if(!defined($ldap)) { ldap_error($!); }
   $ldap->bind() || bind_error($!);

   my $mesg = $ldap->search (  # perform a search
                             base   => "$self->{'branch'}",
                             filter => "$self->{'filter'}"
                            );

   ####
   # ok search done, now lets grab the error, and stuff the output
   # into our internal datastructure
   ####
   $self->{'error'} = $mesg->error;
   $self->{'count'} = $mesg->count;


   $self->set_entries($mesg->all_entries);

   $ldap->unbind;   # take down session

   return $self->get_entries();
}

sub get_branch {
  my $self = shift;
  return $self->{'branch'};
}

sub set_branch {
  my $self = shift;
  my $branch = shift;
  if(!defined($branch)) { return undef; }
  $self->{'branch'} = $branch;
  return $branch;
}

sub get_filter {
  my $self = shift;
  return $self->{'filter'};
}

sub set_filter {
  my $self = shift;
  my $filter = shift;
  if(!defined($filter)) { return undef; }
  $self->{'filter'} = $filter;
  return $filter;
}

sub set_entries {
   my $self = shift;
   my @entries = @_;
   foreach (@entries) { push(@{$self->{'entries'}} , $_); }
}

sub get_entries {
   my $self = shift;
   my $aref = $self->{'entries'};
   return @$aref;
}

sub ldap_error {
  my $self = shift;
  my $err  = shift;
  warn "LDAP constructor error: $err\n";
  return undef;
}

sub bind_error {
   my $self = shift;
   my $err = shift;
   warn "could not bind: $err\n";
   return undef;
}

sub get_error {
   my $self = shift;
   return $self->{'error'};
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

eSTAR::LDAP::Search - Perl extension for doing GIS/GIIS/GRIS searches
 on the MDS's on machines to find out grid type data about that machine.

=head1 SYNOPSIS

  use eSTAR::LDAP::Search;
  ###$timeout is optional
  $gis = eSTAR::LDAP::Search->new($host,$port,$branchpoint,$filter,[$timeout]);
  $gis->execute();
  $timeout = 120;
  $gis = eSTAR::LDAP::Search->new("dn1.ex.ac.uk","2000",
                                 "o=eSTAR","(objectclass=*)", $timeout);
  my @entries = $gis->execute();
  my $entry;
  foreach $entry (@entries) {
     my @atts = $entry->attributes;
     print "\n\n";
     foreach (@atts) {
       print "$_="; my $val = $entry->get_value($_);
       print "$val\n";
    }
  }

=head1 DESCRIPTION

eSTAR::LDAP::Search is a perl module for making grid-info-search type queries against a globus mds (GIS) system. The execute() function returns an array of Net::LDAP::Entry objects, which you can get the attributes of and get_value on or do whatever it is you want to with.

=head2 EXPORT

None by default.


=head1 AUTHOR

Stephen Mock, mock@sdsc.edu

=head1 SEE ALSO

Net::LDAP, Net::LDAP::Entry

=cut
