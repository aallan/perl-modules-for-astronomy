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
#     $Id: Parse.pm,v 1.2 2002/03/15 05:26:13 aa Exp $

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
gent from the discovery nod, it takes an eSTAR::RTML object as input
returning an object with parsed

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION $SELF /;

use Net::Domain qw(hostname hostdomain);
use File::Spec;
use Carp;

'$Revision: 1.2 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Parse.pm,v 1.2 2002/03/15 05:26:13 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $message = new eSTAR::RTML::Parse( $rtml );

returns a reference to an message object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { BUFFER      => undef,
                      DTD         => undef,
                      TYPE        => undef,
                      CONTACT     => {},
                      IA          => {},
                      PROJECT     => {},
                      TELESCOPE   => {},
                      LOCATION    => {},
                      OBSERVATION => {}, 
                                            }, $class;

  # Configure the object
  $block->configure( @_ );

  return $block;

}

# M E T H O D S -------------------------------------------------------------

=back

=head2 Main Methods

=over 4

=item B<rtml>

Populate the pre-parsed RTML document tree using an eSTAR::RTML object

   $message->rtml( $rtml_object );

and parse the tree.

=cut

sub rtml {
  my $self = shift;
  my $rtml = shift;
 
  # populate the document tree (icky)
  $self->{BUFFER} = $rtml->return_tree();
  
  # parse the document tree
  _parse_rtml();

}

# A C C E S S O R   M E T H O D S --------------------------------------------

=back

=head2 Main Methods

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


# C O N F I G U R E ----------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as an argument

  $message->configure( %options );

Does nothing if the array is not supplied.

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

# T I M E   A T   T H E   B A R  --------------------------------------------

=back

=begin __PRIVATE_METHODS__

=head2 Private methods

These methods are for internal use only.

=over 4

=item B<_parse_rtml>

Private method to parse the RTML document.

=cut

sub _parse_rtml {
   
   # grab the RTML document from inside the XML tags
   my @document = @{${$SELF->{BUFFER}}[1]};
   
   # set DTD version and document type tags in object
   $SELF->{DTD} = ${$document[0]}{'version'};
   $SELF->{TYPE} = ${$document[0]}{'type'};
   
   # parse the remainder of the RTML document
   for ( my $i = 3; $i <= $#document; $i++ ) {
      print "# $i = $document[$i]";
      
      # CONTACT TAG
      # -----------
      if( $document[$i] eq 'Contact' ) {
         print "*\n";
         
         # grab section
         my @contact = @{$document[$i+1]};
         
         # check for attributes
         if( defined ${$contact[0]}{'PI'} ) {
            ${$SELF->{CONTACT}}{'PI'} = ${$contact[0]}{'PI'};
         }   
         
         # loop through sub-tags
         for ( my $j = 3; $j <= $#contact; $j++ ) {
            print "#    $j = $contact[$j]*\n";
            
            # grab the hash entry
            my $entry = ${$contact[$j+1]}[2];
            chomp($entry);
           
            # remove leading spaces
            $entry =~ s/^\s+//;
            
            # remove trailing spaces
            $entry =~ s/\s+$//;
            
            chomp($entry);
            
            # assign the entry
            ${$SELF->{CONTACT}}{$contact[$j]} = $entry;
            
            # increment counter
            $j = $j + 3;
         }
      }
      
      # LOCATION TAG
      # ------------
      elsif( $document[$i] eq 'Location' ) {
         print "*\n";
         
         # grab section
         my @location = @{$document[$i+1]};
         
         # loop through sub-tags
         for ( my $j = 3; $j <= $#location; $j++ ) {
            print "#    $j = $location[$j]*\n";
            
            # grab the hash entry
            my $entry = ${$location[$j+1]}[2];
            chomp($entry);
           
            # remove leading spaces
            $entry =~ s/^\s+//;
            
            # remove trailing spaces
            $entry =~ s/\s+$//;
            
            chomp($entry);
            
            # assign the entry
            ${$SELF->{LOCATION}}{$location[$j]} = $entry;
            
            # increment counter
            $j = $j + 3;
         }
      }
      
      # INTELLIGENT AGENT TAG
      # ---------------------
      elsif( $document[$i] eq 'IntelligentAgent' ) {
         print "*\n";
         
         # grab section
         my @agent = @{$document[$i+1]};
         
         # check for attributes
         if( defined ${$agent[0]}{'host'} ) {
            ${$SELF->{IA}}{'host'} = ${$agent[0]}{'host'};
         }
         if( defined ${$agent[0]}{'port'} ) {
            ${$SELF->{IA}}{'port'} = ${$agent[0]}{'port'};
         }
         
         # check for CDATA
         if( defined $agent[2] ) { 
         
            # clean up CDATA
            my $entry = $agent[2];           
            $entry =~ s/^\s+//;            
            $entry =~ s/\s+$//;
            chomp($entry);
            
            # push into object
            ${$SELF->{IA}}{'identity'} = $entry;
         }
            
         # loop through sub-tags
         for ( my $j = 3; $j <= $#agent; $j++ ) {
            print "#    $j = $agent[$j]*\n";
            
            # grab the hash entry
            my $entry = ${$agent[$j+1]}[2];
            chomp($entry);
           
            # remove leading spaces
            $entry =~ s/^\s+//;
            
            # remove trailing spaces
            $entry =~ s/\s+$//;
            
            chomp($entry);
            
            # assign the entry
            ${$SELF->{IA}}{$agent[$j]} = $entry;
            
            # increment counter
            $j = $j + 3;
         }
      }      
      
      # PROJECT TAG
      # -----------
      elsif( $document[$i] eq 'Project' ) {
         print "*\n";
         
         # grab section
         my @project = @{$document[$i+1]};
         
         # loop through sub-tags
         for ( my $j = 3; $j <= $#project; $j++ ) {
            print "#    $j = $project[$j]*\n";
            
            # grab the hash entry
            my $entry = ${$project[$j+1]}[2];
            chomp($entry);
           
            # remove leading spaces
            $entry =~ s/^\s+//;
            
            # remove trailing spaces
            $entry =~ s/\s+$//;
            
            chomp($entry);
            
            # assign the entry
            ${$SELF->{PROJECT}}{$project[$j]} = $entry;
            
            # increment counter
            $j = $j + 3;
         }
      }      
      
      # OBSERVATION TAG
      # ---------------
      elsif( $document[$i] eq 'Observation' ) {
         print "*\n";
         
         # grab section
         my @obs = @{$document[$i+1]};
         
         # check for attributes
         if( defined ${$obs[0]}{'status'} ) {
            ${$SELF->{OBSERVATION}}{'status'} = ${$obs[0]}{'status'};
         }
         
         # loop through sub-tags
         for ( my $j = 3; $j <= $#obs; $j++ ) {
            print "#    $j = $obs[$j]";
            
            # TARGET
            # ------
            if ( $obs[$j] eq 'Target' ) {
               print "*\n";
           
               # grab section
               my @target = @{$obs[$j+1]};
            
               # check for attributes
               if( defined ${$obs[0]}{'status'} ) {
                 ${$SELF->{OBSERVATION}}{'Target'}{'type'} =
                                              ${$target[0]}{'type'};
               }
               
               # loop through sub-tags
               for ( my $k = 3; $k <= $#target; $k++ ) {
                  print "#       $k = $target[$k]";
            
                  if ( $target[$k] eq 'Flux' ) {
                  
                     # FLUX
                     # ----
                     print "*\n";
                     
                     my @flux = @{$target[$k+1]};
                     
                     # check for attributes
                     if( defined ${$flux[0]}{'type'} ) {
                      ${$SELF->{OBSERVATION}}{'Target'}{'Flux'}{'type'} =
                                              ${$flux[0]}{'type'};
                     }
                     if( defined ${$flux[0]}{'units'} ) {
                      ${$SELF->{OBSERVATION}}{'Target'}{'Flux'}{'units'} =
                                              ${$flux[0]}{'units'};
                     }
                     if( defined ${$flux[0]}{'wavelength'} ) {
                      ${$SELF->{OBSERVATION}}{'Target'}{'Flux'}{'wavelength'} =
                                              ${$flux[0]}{'wavelength'};
                     }
                     
                     # grab tag value
                     if( defined $flux[2] ) { 
                        my $entry = $flux[2];
                        $entry =~ s/^\s+//;
                        $entry =~ s/\s+$//;
                        chomp($entry);
                        ${$SELF->{OBSERVATION}}{'Target'}{'Flux'}{'tag_value'} =
                                               $entry;
                     }
                     
                 
                  } elsif ( $target[$k] eq 'Coordinates' ) {

                    # COORDINATES
                    # -----------
                    print "*\n";
                    
                    # grab section
                    my @coords = @{$target[$k+1]};
                    
                    # check for attributes
                    if( defined ${$obs[0]}{'status'} ) {
                      ${$SELF->{OBSERVATION}}{'Target'}{'Coordinates'}{'type'} =
                                              ${$coords[0]}{'type'};
                    }
                    
                    # loop through sub-tags
                    for ( my $l = 3; $l <= $#coords; $l++ ) {
                       print "#          $l = $coords[$l]*\n";
                    
                       # grab the hash entry
                       my $entry = ${$coords[$l+1]}[2];
                       chomp($entry);
           
                       # remove leading spaces
                       $entry =~ s/^\s+//;
            
                       # remove trailing spaces
                       $entry =~ s/\s+$//;
            
                       chomp($entry);
             
                       # assign the entry
                  ${$SELF->{OBSERVATION}}{'Target'}{'Coordinates'}{$coords[$l]} 
                                                = $entry;
                       
                     
                       # increment counter
                       $l = $l + 3;
                    }                  
                  
                  } elsif ( $target[$k] eq 'Device' ) {
                 
                     # DEVICE
                     # ------
                     print "?\n";




                  } elsif ( $target[$k] eq 'TrackRate' ) {
                      print "*\n";
                    
                     # TRACKRATE
                     # ---------
                     my @rate = @{$target[$k+1]};

                     # check for attributes
                     if( defined ${$rate[0]}{'type'} ) {
                      ${$SELF->{OBSERVATION}}{'Target'}{'TrackRate'}{'type'} =
                                              ${$rate[0]}{'type'};
                     }
                  
                  }
                  
                  # "normal" entry
                  else {
                     print "*\n";
                     
                     # grab the hash entry
                     my $entry = ${$target[$k+1]}[2];
                     chomp($entry);
           
                     # remove leading spaces
                     $entry =~ s/^\s+//;
            
                     # remove trailing spaces
                     $entry =~ s/\s+$//;
            
                     chomp($entry);
             
                     # assign the entry
                     ${$SELF->{OBSERVATION}}{'Target'}{$target[$k]} = $entry;
                  
                  } 
             
                  # increment counter
                  $k = $k + 3;
               }
            }
            
            # SCHEDULE
            # --------
            elsif ( $obs[$j] eq 'Schedule' ) {
               print "%\n";
            
            }
            
            # CALIBRATION
            # -----------
            elsif ( $obs[$j] eq 'Calibration' ) {
               print "%\n";

            }
            
            # UNKOWN
            # ------
            
            else {
               # icky!
               print "?\n";
            }
            
            # increment counter
            $j = $j + 3;
         }
      }           
      
      # UNKOWN TAG
      # ----------
      else {
         # icky!
         print "?\n";
      }
      
      
      
      # increment counter
      $i = $i + 3;
    
      
   }
   
   # empty buffer 
   $SELF->{BUFFER} = undef;

}


=head1 COPYRIGHT

Copyright (C) 2002 University of Exeter. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;                                                                  
