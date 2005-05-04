package eSTAR::RTML::Parse;

# ---------------------------------------------------------------------------

#+ 
#  Name:
#    eSTAR::RTML::Parse

#  Purposes:
#    Perl module to parse RTML messages

#  Language:
#    Perl module

#  Description:
#    This module parses incoming RTML messages recieved by the intelligent
#    agent from the discovery node.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Parse.pm,v 1.21 2005/05/04 16:39:22 aa Exp $

#  Copyright:
#     Copyright (C) 200s University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

eSTAR::RTML::Parse - module which parses valid RTML messages

=head1 SYNOPSIS

   $message = new eSTAR::RTML::Parse( RTML => $rtml );
 

=head1 DESCRIPTION

The module parses incoming RTML messages recieved by the intelligent
gent from the discovery node, it takes an eSTAR::RTML object as input
returning an object with parsed RTML. The object has various query
methods enabled allowing the user to grab tag values simply.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION $SELF /;

use Net::Domain qw(hostname hostdomain);
use File::Spec;
use Carp;

'$Revision: 1.21 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Parse.pm,v 1.21 2005/05/04 16:39:22 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $message = new eSTAR::RTML::Parse( RTML => $rtml );

returns a reference to an message object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { BUFFER      => undef,
                      DTD         => undef,
                      TYPE        => undef  }, $class;

  # Configure the object
  $block->configure( @_ );

  return $block;

}



# A C C E S S O R   M E T H O D S --------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<dtd>

Return the DTD version of the RTML document

  $version = $rtml->dtd();

=cut

sub dtd {
  my $self = shift;
  return $self->{DTD};
}

=item B<type>

Return the type of the RTML document

  $type = $rtml->type();

=cut

sub type {
  my $self = shift;
  return $self->{TYPE};
}

=item B<score>

Return the Score tag from the RTML document

  $score = $rtml->score();

=cut

sub score {
  my $self = shift;
  return ${$self->{SCORE}}{tag_value};
}

=item B<time>

Return the CompletionTime from of the RTML document

  $completion_time = $rtml->time();

=cut

sub time {
  my $self = shift;
  return ${$self->{COMPLETIONTIME}}{tag_value};
}

=item B<fitsheaders>

Return the FITS headers from the RTML as an array reference

  $hdu = $rtml->fitsheaders();

=cut

sub fitsheaders {
  my $self = shift;
  return ${${$self->{OBSERVATION}}{Fitsheader}}{tag_value};
}

=item B<catalogue>

Return the Cluster format catalogue as an array reference

  $catalog = $rtml->catalogue();

=cut

sub catalogue {
  my $self = shift;
  return ${${$self->{OBSERVATION}}{Objectlist}}{tag_value};
}

=item B<dataimage>

Return the URL of the data image

  $url = $rtml->dataimage();

=cut
sub dataimage {
  my $self = shift;
  return ${${$self->{OBSERVATION}}{Imagedata}}{tag_value};
}

=item B<id>

Return the unqiue ID of the observation

  $unique_id = $rtml->id();

=cut
sub id {
  my $self = shift;
  return ${$self->{INTELLIGENTAGENT}}{tag_value};
}

=item B<name>

Return the real name of the observer

  $real_name = $rtml->name();

=cut

sub name {
  my $self = shift;
  return ${${$self->{CONTACT}}{Name}}{tag_value};
}

=item B<user>

Return the user name of the observer

  $user = $rtml->user();

=cut
sub user {
  my $self = shift;
  return ${${$self->{CONTACT}}{User}}{tag_value};
}

=item B<institution>

Return the institution that the observer has claimed affiliation to,

  $inst = $rtml->institution();

=cut
sub institution {
  my $self = shift;
  return ${${$self->{CONTACT}}{Institution}}{tag_value};
}

=item B<email>

Return the email address of the observer

  $email = $rtml->email();

=cut
sub email {
  my $self = shift;
  return ${${$self->{CONTACT}}{Email}}{tag_value};
}

=item B<target>

Return the name of the target

  $target_name = $rtml->target();

=cut
sub target {
  my $self = shift;
  return ${${${$self->{OBSERVATION}}{Target}}{Targetname}}{tag_value};
}


=item B<targetident>

Return the type of observation we want to make the document

  $observation_ident = $rtml->targetident();

=cut
sub targetident {
  my $self = shift;  
  return ${${$self->{OBSERVATION}}{Target}}{ident};
}

=item B<targettype>

Return the type of observation we want to make the document

  $type = $rtml->targettype();

=cut
sub targettype {
  my $self = shift;  
  return ${${$self->{OBSERVATION}}{Target}}{type};
}

=item B<ra>

Return the R.A. of the target

  $ra = $rtml->ra();

=cut
sub ra {
  my $self = shift;
  return ${${${$self->{OBSERVATION}}{Target}}{Coordinates}}{RightAscension};
}

=item B<dec>

Return the Dec. of the target

  $dec = $rtml->dec();

=cut
sub dec {
  my $self = shift;
  return ${${${$self->{OBSERVATION}}{Target}}{Coordinates}}{Declination};
}

=item B<exposure>

Return the exposure time required

  $exposure_time = $rtml->exposure();

=cut
sub exposure {
  my $self = shift;
  return ${${${$self->{OBSERVATION}}{Schedule}}{Exposure}}{tag_value};
}

=item B<snr>

Return the signal-to-noise ratio required

  $snr = $rtml->snr();

=cut

sub snr {
  my $self = shift;
  return ${${${$self->{OBSERVATION}}{Schedule}}{Exposure}}{tag_value};
}

=item B<flux>

Return the Flux defining the signal-to-noise ratio required

  $flux = $rtml->flux();

=cut
sub flux {
  my $self = shift;
  return ${${${$self->{OBSERVATION}}{Target}}{Coordinates}}{Flux};
}

=item B<equinox>

Return the equinox of the RA and Dec

  $equinox = $rtml->equinox();

=cut
sub equinox {
  my $self = shift;  
  return ${${${$self->{OBSERVATION}}{Target}}{Coordinates}}{Equinox};
}


=item B<filter>

Return the filter type of the observation

  $filter = $rtml->filter();

=cut
sub filter {
  my $self = shift;  
  return ${${${$self->{OBSERVATION}}{Device}}{Filter}}{FilterType};
 
}

=item B<host>

Return the host of the IA origininating the document

  $host = $rtml->host();

=cut
sub host {
  my $self = shift;  
  return ${$self->{INTELLIGENTAGENT}}{host};
}


=item B<port>

Return the port of the IA origininating the document

  $host = $rtml->port();

=cut
sub port {
  my $self = shift;  
  return ${$self->{INTELLIGENTAGENT}}{port};
}


=item B<group_count>

Return the group count of the observation


=cut
sub group_count {
  my $self = shift;  
  return ${${${$self->{OBSERVATION}}{Schedule}}{Exposure}}{Count};
 
}


=item B<series_count>

Return the series count of the observation


=cut

sub series_count {
  my $self = shift;  
  return ${${${$self->{OBSERVATION}}{Schedule}}{Seriesconstraint}}{Count};
 
}

=item B<interval>

Return the interval between monitoring groups 


=cut

sub interval {
  my $self = shift;  
  return ${${${$self->{OBSERVATION}}{Schedule}}{Seriesconstraint}}{Interval};
 
}

=item B<tolerance>

Return the interval between monitoring groups 


=cut

sub tolerance {
  my $self = shift;  
  return ${${${$self->{OBSERVATION}}{Schedule}}{Seriesconstraint}}{Tolerance};
 
}

# C O N F I G U R E ----------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as an argument

  $message->configure( %options );

Does nothing if the hash is not supplied. This is called directly from
the constructor during object creation

=cut

sub configure {
  my $self = shift;

  # CONFIGURE FROM ARGUEMENTS
  # -------------------------
  $SELF = $self;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / RTML / ) {
      my $method = lc($key);
         # normal configuration methods (if needed)
         $self->$method( $args{$key} ) if exists $args{$key};
  }

}

# M E T H O D S -------------------------------------------------------------

=item B<rtml>

Populate the pre-parsed RTML document tree using an eSTAR::RTML object

   $message->rtml( $rtml_object );

and parse the tree. This method is called directly from the configure
method if an RTML key and value is supplied to the %options hash.

=cut

sub rtml {
  my $self = shift;
  my $rtml = shift;
 
  # populate the document tree (icky)
  $self->{BUFFER} = $rtml->return_tree();
  
  # parse the document tree using provate methods.
  _parse_rtml();

}

=item B<freeze>

Method to return a blessed reference to the object so that we can store
ths object on disk using Data::Dumper module.

=cut

sub freeze {
  my $self = shift;
  return bless $self, 'eSTAR::RTML::Parse';
}


# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=head1 COPYRIGHT

Copyright (C) 2002 University of Exeter. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut


=begin __PRIVATE_METHODS__

=head2 Private Methods

These methods are for internal use only.

=over 4

=item B<_parse_rtml>

Private method to parse the RTML document. I can't see why you'd want to call
this from outside the C<eSTAR::RTML::Parse> module, since its called via the
rtml() method directly during construction of the object.

=cut

sub _parse_rtml {
   print "# Parsing RTML document\n#\n";
   
   # grab the RTML document from inside the XML tags
   my @document = @{${$SELF->{BUFFER}}[1]};
   
   # set DTD version and document type tags in object
   $SELF->{DTD} = ${$document[0]}{'version'};
   $SELF->{TYPE} = ${$document[0]}{'type'};
   
   # parse the remainder of the RTML document
   for ( my $i = 3; $i <= $#document; $i++ ) {
      print "# $i = $document[$i] (*)\n";
      
      my @tag = @{$document[$i+1]};
      # parse the tag
      _parse_tag( $document[$i], \@tag );
      
      # increment counter
      $i = $i + 3;
      
   }
   
   # empty buffer 
   $SELF->{BUFFER} = undef;

}

=item B<_parse_tag>

Private method to parse individual tags within the RTML, called from the
private method C<_parse_rtml>. Trust me, you don't want to call this from
outside the C<eSTAR::RTML::Parse> module, it'll almost certainly do odd
things unless you can figure out exactly what sort of array reference you
need to pass in. 

=cut

sub _parse_tag {
  croak 'Parse.pm: _parse_tag() usage error'
    unless scalar(@_) == 2 ;
    
  # read arguements
  my ( $name, $array_reference ) = @_;
  my @array = @$array_reference;

  # grab section
  my @obs = @$array_reference;

  #use Data::Dumper;
  #print Dumper( @obs );
         
  # check for attributes         
  _parse_sub_attrib( $name, \%{$obs[0]} );  
         
  # check for CDATA
  _parse_sub_value( $name, \@obs );  
        
  # loop through sub-tags individually, nearly all have
  # their own sub-tags so need to deal with them individually
         
  for ( my $j = 3; $j <= $#obs; $j++ ) {
     print "#    $j = $obs[$j] <*>\n";
         
     # grab section
     my @generic = @{$obs[$j+1]};
         
     # check for attributes
     _parse_sub_sub_attrib( $name, $obs[$j],
                            \%{$generic[0]} );
         
     # check for CDATA
     _parse_sub_sub_value( $name, $obs[$j], 
                                     \@generic ); 
               
     # loop through sub-tags
     for ( my $k = 3; $k <= $#generic; $k++ ) {
        print "#       $k = $generic[$k] [*]\n";
                  
        # grab sub-tag array reference
        my @array = @{$generic[$k+1]};
        #use Data::Dumper; print Dumper( @array );

        #print "ATTRIBUTE\n$name\n$obs[$j]\n$generic[$k]\n";
        #print "array[0] is $array[0]\n";

        # check for attributes
        _parse_sub_sub_sub_attrib( $name, $obs[$j],
                                   $generic[$k], \%{$array[0]} );
        # loop through sub-tags
        _parse_sub_sub_sub_tag( $name, $obs[$j], 
                                $generic[$k], \@array );
        # check for CDATA
        _parse_sub_sub_sub_value( $name, $obs[$j], 
                                  $generic[$k] , \@array ); 
           
        ##########################################################
        #                                                        #
        # NB: This is where to add another sub loop if we end    #
        #     up having sub-sub-sub-sub tags at any point. The   #
        #     entire thing should really be replaced with a      #
        #     recursive parse routine at some point.             #
        #                                                        #
        #     Unfortunately I'm just to lazy to do it the right  #
        #     way so you'll have to live with this...            #
        #                                                        #
        ##########################################################
         
        # increment counter
        $k = $k + 3;               
      }                             
               
      # increment counter
      $j = $j + 3;
   }

}

# These routines are so private the don't even get POD documentation, I can
# just about see a reason why someone should want to _parse_rtml() from
# outside the module, and maybe (just maybe) _parse_tag(). But they'd have
# to be insane if they wanted to call any of these routines. They do the
# work of the recursive parsing down the XML tree (and yes, I really should
# write something properly recursive to do this when I get time.

# _parse_sub*_tag() routines: these parse the sub tag content

sub _parse_sub_tag {
  croak 'Parse.pm: _parse_sub_tag() usage error'
    unless scalar(@_) == 2 ;

  # read arguements
  my ( $name, $array_reference ) = @_;
  my @array = @$array_reference;
   
  for ( my $j = 3; $j <= $#array; $j++ ) {
     print "#    $j = $array[$j] *\n";
            
     # grab the hash entry
     my $entry = ${$array[$j+1]}[2];
     chomp($entry);
           
     # remove leading spaces
     $entry =~ s/^\s+//;
            
     # remove trailing spaces
     $entry =~ s/\s+$//;
            
     chomp($entry);
            
     # assign the entry
     ${$SELF->{uc($name)}}{$array[$j]} = $entry;
            
     # increment counter
     $j = $j + 3;
   }

}

sub _parse_sub_sub_tag {
  croak 'Parse.pm: _parse_sub_sub_tag() usage error'
    unless scalar(@_) == 3 ;

  # read arguements
  my ( $name, $sub_name, $array_reference ) = @_;
  my @array = @$array_reference;
  
  # loop through sub-tags
  for ( my $l = 3; $l <= $#array; $l++ ) {
     print "#          $l = $array[$l] *\n";
                    
     # grab the hash entry
     my $entry = ${$array[$l+1]}[2];
     chomp($entry);
           
     # remove leading spaces
     $entry =~ s/^\s+//;
            
     # remove trailing spaces
     $entry =~ s/\s+$//;
            
     chomp($entry);
             
     # assign the entry
     ${$SELF->{uc($name)}}{ucfirst(lc($sub_name))}{$array[$l]}  = $entry;
     
     # increment counter
     $l = $l + 3;
     
   }  
} 

sub _parse_sub_sub_sub_tag {
  croak 'Parse.pm: _parse_sub_sub_sub_tag() usage error'
    unless scalar(@_) == 4 ;

  # read arguements
  my ( $name, $sub_name, $subsub_name, $array_reference ) = @_;
  my @array = @$array_reference;
  
  # loop through sub-tags
  for ( my $l = 3; $l <= $#array; $l++ ) {
     print "#          $l = $array[$l] *\n";
                    
     # grab the hash entry
     my $entry = ${$array[$l+1]}[2];
     chomp($entry);
           
     # remove leading spaces
     $entry =~ s/^\s+//;
            
     # remove trailing spaces
     $entry =~ s/\s+$//;
            
     chomp($entry);
             
     # assign the entry
     ${$SELF->{uc($name)}}
       {ucfirst(lc($sub_name))}
       {ucfirst(lc($subsub_name))}{$array[$l]} = $entry;
     
     # increment counter
     $l = $l + 3;
   }  
} 
sub _parse_sub_sub_sub_sub_tag {
  croak 'Parse.pm: _parse_sub_sub_sub_sub_tag() usage error'
    unless scalar(@_) == 5 ;

  # read arguements
  my ( $name, $sub_name, $subsub_name, $subsubsub_name, $array_reference ) = @_;
  my @array = @$array_reference;
  
  # loop through sub-tags
  for ( my $l = 3; $l <= $#array; $l++ ) {
     print "#          $l = $array[$l] *\n";
                    
     # grab the hash entry
     my $entry = ${$array[$l+1]}[2];
     chomp($entry);
           
     # remove leading spaces
     $entry =~ s/^\s+//;
            
     # remove trailing spaces
     $entry =~ s/\s+$//;
            
     chomp($entry);
             
     # assign the entry
     ${$SELF->{uc($name)}}
       {ucfirst(lc($sub_name))}
       {ucfirst(lc($subsub_name))}
       {ucfirst(lc($subsubsub_name))}{$array[$l]} = $entry;
     
     # increment counter
     $l = $l + 3;
   }  
} 

# _parse_sub*_attrib() routines: these parse the sub tag attributes

sub _parse_sub_attrib { 
  croak 'Parse.pm: _parse_sub_attrib() usage error'
    unless scalar(@_) == 2 ;

  # read arguements
  my ( $name, $hash_reference ) = @_;
  my %hash = %$hash_reference;

  # loop through hash and drop all the keys into the parsed output
  # as hash items in the list. This isn't really neat, perhaps a 
  # hash of hashs would be better?
  foreach my $key ( sort keys %hash ) {
     ${$SELF->{uc($name)}}{$key} = $hash{$key};
  }
  
}

sub _parse_sub_sub_attrib { 
  croak 'Parse.pm: _parse_sub_sub_attrib() usage error'
    unless scalar(@_) == 3 ;

  # read arguements
  my ( $name, $sub_name, $hash_reference ) = @_;
  my %hash = %$hash_reference;

  # loop through hash and drop all the keys into the parsed output
  # as hash items in the list. This isn't really neat, perhaps a 
  # hash of hashs would be better?
  foreach my $key ( sort keys %hash ) {
     ${$SELF->{uc($name)}}{ucfirst(lc($sub_name))}{$key} = $hash{$key};
  }
  
}

sub _parse_sub_sub_sub_attrib { 
  croak 'Parse.pm: _parse_sub_sub_sub_attrib() usage error'
    unless scalar(@_) == 4 ;

  # read arguements
  my ( $name, $sub_name, $subsub_name, $hash_reference ) = @_;
  my %hash = %$hash_reference;

  #use Data::Dumper; print "ATTRIB " . Dumper(%hash) . "\n";
  
  # loop through hash and drop all the keys into the parsed output
  # as hash items in the list. This isn't really neat, perhaps a 
  # hash of hashs would be better?
  foreach my $key ( sort keys %hash ) {

     #print "ATTRIB $key = $hash{$key}\n";
     #print "ATTRIB $name, $sub_name, $subsub_name, $key\n";
     ${$SELF->{uc($name)}}
        {ucfirst(lc($sub_name))}
        {ucfirst(lc($subsub_name))}{$key} = $hash{$key};
  }
  
}


sub _parse_sub_sub_sub_sub_attrib { 
  croak 'Parse.pm: _parse_sub_sub_sub_sub_attrib() usage error'
    unless scalar(@_) == 5 ;

  # read arguements
  my ( $name, $sub_name, $subsub_name, $subsubsub_name, $hash_reference ) = @_;
  my %hash = %$hash_reference;

  #use Data::Dumper; print "ATTRIB " . Dumper(%hash) . "\n";
  
  # loop through hash and drop all the keys into the parsed output
  # as hash items in the list. This isn't really neat, perhaps a 
  # hash of hashs would be better?
  foreach my $key ( sort keys %hash ) {

     #print "ATTRIB $key = $hash{$key}\n";
     #print "ATTRIB $name, $sub_name, $subsub_name, $subsubsub_name, $key\n";
     ${$SELF->{uc($name)}}
        {ucfirst(lc($sub_name))}
        {ucfirst(lc($subsub_name))}
        {ucfirst(lc($subsubsub_name))}{$key} = $hash{$key};
  }
  
}

# _parse_sub*_value() routines: these grab the tags CDATA

sub _parse_sub_value {
  croak 'Parse.pm: _parse_sub_value() usage error'
    unless scalar(@_) == 2 ;

  # read arguements
  my ( $name, $array_reference ) = @_;
  my @array = @$array_reference;
       
  # grab tag value
  if( defined $array[2] ) { 
     my $entry = $array[2];
     $entry =~ s/^\s+//;
     $entry =~ s/\s+$//;
     chomp($entry);
     
     if( $entry ne '' ) {
        ${$SELF->{uc($name)}}{'tag_value'} = $entry;
     }   
  }
}  

sub _parse_sub_sub_value {
  croak 'Parse.pm: _parse_sub_sub_value() usage error'
    unless scalar(@_) == 3 ;

  # read arguements
  my ( $name, $sub_name, $array_reference ) = @_;
  my @array = @$array_reference;
       
  # grab tag value
  if( defined $array[2] ) { 
     my $entry = $array[2];
     $entry =~ s/^\s+//;
     $entry =~ s/\s+$//;
     chomp($entry);
     if( $entry ne '' ) {
        ${$SELF->{uc($name)}}{ucfirst(lc($sub_name))}{'tag_value'} = $entry;
     }   
  }
}

sub _parse_sub_sub_sub_value {
  croak 'Parse.pm: _parse_sub_sub_sub_value() usage error'
    unless scalar(@_) == 4 ;

  # read arguements
  my ( $name, $sub_name, $subsub_name, $array_reference ) = @_;
  my @array = @$array_reference;
       
  # grab tag value
  if( defined $array[2] ) { 
     my $entry = $array[2];
     $entry =~ s/^\s+//;
     $entry =~ s/\s+$//;
     chomp($entry);
     if( $entry ne '' ) {
        ${$SELF->{uc($name)}}
           {ucfirst(lc($sub_name))}
           {ucfirst(lc($subsub_name))}{'tag_value'} = $entry;
     }      
  }
}

sub _parse_sub_sub_sub_sub_value {
  croak 'Parse.pm: _parse_sub_sub_sub_sub_value() usage error'
    unless scalar(@_) == 5 ;

  # read arguements
  my ( $name, $sub_name, $subsub_name, $subsubsub_name, $array_reference ) = @_;
  my @array = @$array_reference;
       
  # grab tag value
  if( defined $array[2] ) { 
     my $entry = $array[2];
     $entry =~ s/^\s+//;
     $entry =~ s/\s+$//;
     chomp($entry);
     if( $entry ne '' ) {
        ${$SELF->{uc($name)}}
           {ucfirst(lc($sub_name))}
           {ucfirst(lc($subsub_name))}
           {ucfirst(lc($subsubsub_name))}{'tag_value'} = $entry;
     }      
  }
}

# L A S T  O R D E R S ------------------------------------------------------

1;                                                                  
