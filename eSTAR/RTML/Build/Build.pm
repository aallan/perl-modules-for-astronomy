package eSTAR::RTML::Build;

# ---------------------------------------------------------------------------

#+
#  Name:
#    eSTAR::RTML::Build

#  Purposes:
#    Perl module to construct RTML messages

#  Language:
#    Perl module

#  Description:
#    This module creates outgoing RTML messages needed by the intelligent
#    agent to communicate with the Discovery Node.

#  Authors:
#    Alasdair Allan (aa@astro.ex.ac.uk)

#  Revision:
#     $Id: Build.pm,v 1.21 2006/06/08 22:45:16 aa Exp $

#  Copyright:
#     Copyright (C) 200s University of Exeter. All Rights Reserved.

#-

# ---------------------------------------------------------------------------

=head1 NAME

eSTAR::RTML::Build - module which creates valid RTML messages

=head1 SYNOPSIS

   $message = new eSTAR::RTML::Build( Host        => $ia_host,
                                      Port        => $ia_port,
                                      ID          => $id,
                                      User        => $user_name,
                                      Name        => $real_name,
                                      Institution => $institution,
                                      Email       => $email_address );


=head1 DESCRIPTION

The module builds RTML messages which will be sent over GlobusIO from the
intelligent agent to the dscovery node. Two types of messages can be
constructed, these being score and observation request documents.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use vars qw/ $VERSION /;

use Socket;
use Net::Domain qw(hostname hostdomain);
use File::Spec;
use Carp;

use XML::Writer;
use XML::Writer::String;

'$Revision: 1.21 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Build.pm,v 1.21 2006/06/08 22:45:16 aa Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $message = new eSTAR::RTML::Build( Host        => $ia_host,
                                     Port        => $ia_port,
                                     ID          => $id,
                                     User        => $user_name,
                                     Name        => $real_name,
                                     Institution => $institution,
                                     Email       => $email_address);

returns a reference to an object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { WRITER  => undef,
                      BUFFER  => undef,
                      OPTIONS => {} }, $class;

  # Configure the object
  $block->configure( @_ );

  return $block;

}

# M E T H O D S -------------------------------------------------------------

=back

=head2 RTML Methods

=over 4

=item B<score_observation>

Build a score document

   $status = $message->score_observation( Target        => $target_name,
                                          TargetIdent   => "Observation",
                                          RA            => $ra,
                                          Dec           => $dec,
                                          Equinox       => $equinox,
                                          Exposure      => $seconds,
                                          Snr           => $snr,
                                          Flux          => $mag,
                                          Filter        => $filter,
                                          GroupCount    => $obs_per_group,
                                          SeriesCount   => $obs_per_series,
                                          Interval      => $interval,
                                          Tolerance     => $tolerance,
                                          TimeConstraint => [ $start_date,
                                                              $end_date ],
					  Priority      => $obs_priority );

Use "Exposure", or "Snr" and "Flux", but not both.

=cut

sub score_observation {
  my $self = shift;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / Target TargetType TargetIdent RA Dec Equinox Exposure
                Snr Flux Filter GroupCount SeriesCount Interval Tolerance
                TimeConstraint Priority / ) {
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

  # open the document
  $self->{WRITER}->xmlDecl( 'US-ASCII' );
  $self->{WRITER}->doctype( 'RTML', '', ${$self->{OPTIONS}}{DTD} );

  # open the RTML document
  # ======================
  $self->{WRITER}->startTag( 'RTML',
                             'version' => '2.2',
                             'type' => 'score' );

  # IntelligentAgent Tag
  # --------------------

  # identify the IA
  $self->{WRITER}->startTag( 'IntelligentAgent',
                             'host' => ${$self->{OPTIONS}}{HOST},
                             'port' =>  ${$self->{OPTIONS}}{PORT} );

  # unique IA identity sting
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{ID} );

  $self->{WRITER}->endTag( 'IntelligentAgent' );

  # Telescope Tag
  # -------------
  $self->{WRITER}->emptyTag( 'Telescope' );

  # Contact Tag
  # -----------
  $self->{WRITER}->startTag( 'Contact', 'PI' => 'true' );

     $self->{WRITER}->startTag( 'User');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{USER} );
     $self->{WRITER}->endTag( 'User' );

     $self->{WRITER}->startTag( 'Name');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{NAME} );
     $self->{WRITER}->endTag( 'Name' );

     $self->{WRITER}->startTag( 'Institution');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{INSTITUTION} );
     $self->{WRITER}->endTag( 'Institution' );

     $self->{WRITER}->startTag( 'Email');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{EMAIL} );
     $self->{WRITER}->endTag( 'Email' );

  $self->{WRITER}->endTag( 'Contact' );

  # Project Tag
  # -------------
  $self->{WRITER}->emptyTag( 'Project' );

  # Observation tag
  # ---------------
  $self->{WRITER}->startTag( 'Observation', 'status' => 'ok' );

     $self->{WRITER}->startTag( 'Target',
                                'type' => ${$self->{OPTIONS}}{TARGETTYPE},
                                'ident' => ${$self->{OPTIONS}}{TARGETIDENT} );

        $self->{WRITER}->startTag( 'TargetName' );
        $self->{WRITER}->characters( ${$self->{OPTIONS}}{TARGET} );
        $self->{WRITER}->endTag( 'TargetName' );

        $self->{WRITER}->startTag( 'Coordinates', 'type' => 'equatorial' );

           $self->{WRITER}->startTag( 'RightAscension',
                                    'format' => 'hh mm ss.s', units => 'hms' );
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{RA} );
           $self->{WRITER}->endTag( 'RightAscension' );

           $self->{WRITER}->startTag( 'Declination',
                                    'format' => 'sdd mm ss.s', units => 'dms' );

           if ( ${$self->{OPTIONS}}{DEC} =~ m/^\+/ ) {
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{DEC} );
           } else {
              if ( ${$self->{OPTIONS}}{DEC} =~ m/-/ ) {
                $self->{WRITER}->characters( ${$self->{OPTIONS}}{DEC} );
              } else {
                $self->{WRITER}->characters( "+" . ${$self->{OPTIONS}}{DEC} );
              }
           }
           $self->{WRITER}->endTag( 'Declination' );

           $self->{WRITER}->startTag( 'Equinox'  );
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{EQUINOX} );
           $self->{WRITER}->endTag( 'Equinox' );

        $self->{WRITER}->endTag( 'Coordinates' );

        if( defined ${$self->{OPTIONS}}{SNR} ) {

           if( defined ${$self->{OPTIONS}}{FILTER} ) {
              $self->{WRITER}->startTag( 'Flux',
               'type' => 'continuum', 'units' => 'mag',
               'wavelength' => ${$self->{OPTIONS}}{FILTER} );
           } else {
              $self->{WRITER}->startTag( 'Flux',
               'type' => 'continuum', 'units' => 'mag', 'wavelength' => 'V' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{FLUX} );
           $self->{WRITER}->endTag( 'Flux' );
        }

     $self->{WRITER}->endTag( 'Target' );


     $self->{WRITER}->startTag( 'Device', 'type' => 'camera' );

           $self->{WRITER}->startTag( 'Filter' );

           if( defined ${$self->{OPTIONS}}{FILTER} ) {
              $self->{WRITER}->startTag( 'FilterType');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{FILTER} );
              $self->{WRITER}->endTag( 'FilterType' );
           } else {
              $self->{WRITER}->startTag( 'FilterType' );
              $self->{WRITER}->characters( 'V' );
              $self->{WRITER}->endTag( 'FilterType' );
           }

           $self->{WRITER}->endTag( 'Filter' );
     $self->{WRITER}->endTag( 'Device' );

     my $priority;
     if( defined ${$self->{OPTIONS}}{PRIORITY} ) {
        $priority = ${$self->{OPTIONS}}{PRIORITY};
     } else {
        $priority = 3;
     }

     $self->{WRITER}->startTag( 'Schedule', 'priority' => $priority );

        if( defined ${$self->{OPTIONS}}{SNR} ) {
           $self->{WRITER}->startTag( 'Exposure', 'type' => 'snr' );
           if( defined ${$self->{OPTIONS}}{GROUPCOUNT} &&
               ${$self->{OPTIONS}}{GROUPCOUNT} > 1 ) {
              $self->{WRITER}->startTag( 'Count');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{GROUPCOUNT} );
              $self->{WRITER}->endTag( 'Count' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{SNR} );
        } else {
           $self->{WRITER}->startTag( 'Exposure',
                                   'type' => 'time', 'units' => 'seconds' );
           if( defined ${$self->{OPTIONS}}{GROUPCOUNT} &&
               ${$self->{OPTIONS}}{GROUPCOUNT} > 1 ) {
              $self->{WRITER}->startTag( 'Count');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{GROUPCOUNT} );
              $self->{WRITER}->endTag( 'Count' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{EXPOSURE} );
        }
        $self->{WRITER}->endTag( 'Exposure' );

        if( defined ${$self->{OPTIONS}}{STARTDATETIME} &&
            defined ${$self->{OPTIONS}}{ENDDATETIME} ) {

             $self->{WRITER}->startTag( 'TimeConstraint' );
             $self->{WRITER}->startTag( 'StartDateTime' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{STARTDATETIME} );
             $self->{WRITER}->endTag( 'StartDateTime' );
             $self->{WRITER}->startTag( 'EndDateTime' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{ENDDATETIME} );
             $self->{WRITER}->endTag( 'EndDateTime' );
             $self->{WRITER}->endTag( 'TimeConstraint' );
        }

        if ( defined ${$self->{OPTIONS}}{SERIESCOUNT} &&
             defined ${$self->{OPTIONS}}{INTERVAL} &&
             defined ${$self->{OPTIONS}}{TOLERANCE} ) {

             $self->{WRITER}->startTag( 'SeriesConstraint' );

             $self->{WRITER}->startTag( 'Count' );
             $self->{WRITER}->characters(${$self->{OPTIONS}}{SERIESCOUNT});
             $self->{WRITER}->endTag( 'Count' );

             $self->{WRITER}->startTag( 'Interval' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{INTERVAL});
             $self->{WRITER}->endTag( 'Interval' );

             $self->{WRITER}->startTag( 'Tolerance' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{TOLERANCE});
             $self->{WRITER}->endTag( 'Tolerance' );

             $self->{WRITER}->endTag( 'SeriesConstraint' );

        }



     $self->{WRITER}->endTag( 'Schedule' );

  $self->{WRITER}->endTag( 'Observation' );


  # close the RTML document
  # =======================
  $self->{WRITER}->endTag( 'RTML' );
  $self->{WRITER}->end();

  # return a good status (GLOBUS_TRUE)
  return 1;

}


=item B<score_response>

Build a score response document

   $status = $message->score_response( Target        => $target_name,
                                       TargetIdent    => "Observation",
                                       RA            => $ra,
                                       Dec           => $dec,
                                       Equinox       => $equinox,
                                       Exposure      => $seconds,
                                       Snr           => $snr,
                                       Flux          => $mag,
                                       Score         => $score,
                                       Time          => $completion_time,
                                       Filter        => filter,
                                          GroupCount    => $obs_per_group,
                                          SeriesCount   => $obs_per_series,
                                          Interval      => $interval,
                                          Tolerance     => $tolerance,
                                          TimeConstraint => [ $start_date,
                                                              $end_date ],
					  Priority      => $obs_priority   );

Use "Exposure", or "Snr" and "Flux", but not both.

=cut

sub score_response {
  my $self = shift;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / Target TargetType TargetIdent RA Dec Equinox Exposure
                    Snr Flux Score Time Filter GroupCount SeriesCount
                    Interval Tolerance TimeConstraint Priority / ) {

     # print "Calling " . lc($key) ."()\n";
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

  # open the document
  $self->{WRITER}->xmlDecl( 'US-ASCII' );
  $self->{WRITER}->doctype( 'RTML', '', ${$self->{OPTIONS}}{DTD} );

  # open the RTML document
  # ======================
  $self->{WRITER}->startTag( 'RTML',
                             'version' => '2.1',
                             'type' => 'score' );

  # IntelligentAgent Tag
  # --------------------

  # identify the IA
  $self->{WRITER}->startTag( 'IntelligentAgent',
                             'host' => ${$self->{OPTIONS}}{HOST},
                             'port' =>  ${$self->{OPTIONS}}{PORT} );

  # unique IA identity sting
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{ID} );

  $self->{WRITER}->endTag( 'IntelligentAgent' );

  # Telescope Tag
  # -------------
  $self->{WRITER}->emptyTag( 'Telescope' );

  # Contact Tag
  # -----------
  $self->{WRITER}->startTag( 'Contact', 'PI' => 'true' );

     $self->{WRITER}->startTag( 'User');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{USER} );
     $self->{WRITER}->endTag( 'User' );

     $self->{WRITER}->startTag( 'Name');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{NAME} );
     $self->{WRITER}->endTag( 'Name' );

     $self->{WRITER}->startTag( 'Institution');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{INSTITUTION} );
     $self->{WRITER}->endTag( 'Institution' );

     $self->{WRITER}->startTag( 'Email');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{EMAIL} );
     $self->{WRITER}->endTag( 'Email' );

  $self->{WRITER}->endTag( 'Contact' );

  # Project Tag
  # -------------
  $self->{WRITER}->emptyTag( 'Project' );

  # Observation tag
  # ---------------
  $self->{WRITER}->startTag( 'Observation', 'status' => 'ok' );

     $self->{WRITER}->startTag( 'Target',
                                'type' => ${$self->{OPTIONS}}{TARGETTYPE},
                                'ident' => ${$self->{OPTIONS}}{TARGETIDENT} );

        $self->{WRITER}->startTag( 'TargetName' );
        $self->{WRITER}->characters( ${$self->{OPTIONS}}{TARGET} );
        $self->{WRITER}->endTag( 'TargetName' );

        $self->{WRITER}->startTag( 'Coordinates', 'type' => 'equatorial' );

           $self->{WRITER}->startTag( 'RightAscension',
                                    'format' => 'hh mm ss.s', units => 'hms' );
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{RA} );
           $self->{WRITER}->endTag( 'RightAscension' );

           $self->{WRITER}->startTag( 'Declination',
                                    'format' => 'sdd mm ss.s', units => 'dms' );
           if ( ${$self->{OPTIONS}}{DEC} =~ m/^\+/ ) {
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{DEC} );
           } else {
              if ( ${$self->{OPTIONS}}{DEC} =~ m/-/ ) {
                $self->{WRITER}->characters( ${$self->{OPTIONS}}{DEC} );
              } else {
                $self->{WRITER}->characters( "+" . ${$self->{OPTIONS}}{DEC} );
              }
           }
           $self->{WRITER}->endTag( 'Declination' );

           $self->{WRITER}->startTag( 'Equinox'  );
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{EQUINOX} );
           $self->{WRITER}->endTag( 'Equinox' );

        $self->{WRITER}->endTag( 'Coordinates' );

        if( defined ${$self->{OPTIONS}}{SNR} ) {

           if( defined ${$self->{OPTIONS}}{FILTER} ) {
              $self->{WRITER}->startTag( 'Flux',
               'type' => 'continuum', 'units' => 'mag',
               'wavelength' => ${$self->{OPTIONS}}{FILTER} );
           } else {
              $self->{WRITER}->startTag( 'Flux',
               'type' => 'continuum', 'units' => 'mag', 'wavelength' => 'V' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{FLUX} );
           $self->{WRITER}->endTag( 'Flux' );
        }

     $self->{WRITER}->endTag( 'Target' );

     $self->{WRITER}->startTag( 'Device', 'type' => 'camera' );

           $self->{WRITER}->startTag( 'Filter' );

           if( defined ${$self->{OPTIONS}}{FILTER} ) {
              $self->{WRITER}->startTag( 'FilterType');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{FILTER} );
              $self->{WRITER}->endTag( 'FilterType' );
           } else {
              $self->{WRITER}->startTag( 'FilterType' );
              $self->{WRITER}->characters( 'V' );
              $self->{WRITER}->endTag( 'FilterType' );
           }

           $self->{WRITER}->endTag( 'Filter' );
     $self->{WRITER}->endTag( 'Device' );


     my $priority;
     if( defined ${$self->{OPTIONS}}{PRIORITY} ) {
        $priority = ${$self->{OPTIONS}}{PRIORITY};
     } else {
        $priority = 3;
     }

     $self->{WRITER}->startTag( 'Schedule', 'priority' => $priority );

        if( defined ${$self->{OPTIONS}}{SNR} ) {
           $self->{WRITER}->startTag( 'Exposure', 'type' => 'snr' );
           if( defined ${$self->{OPTIONS}}{GROUPCOUNT} &&
               ${$self->{OPTIONS}}{GROUPCOUNT} > 1 ) {
              $self->{WRITER}->startTag( 'Count');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{GROUPCOUNT} );
              $self->{WRITER}->endTag( 'Count' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{SNR} );
        } else {
           $self->{WRITER}->startTag( 'Exposure',
                                   'type' => 'time', 'units' => 'seconds' );
           if( defined ${$self->{OPTIONS}}{GROUPCOUNT} &&
               ${$self->{OPTIONS}}{GROUPCOUNT} > 1 ) {
              $self->{WRITER}->startTag( 'Count');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{GROUPCOUNT} );
              $self->{WRITER}->endTag( 'Count' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{EXPOSURE} );
        }
        $self->{WRITER}->endTag( 'Exposure' );

        if( defined ${$self->{OPTIONS}}{STARTDATETIME} &&
            defined ${$self->{OPTIONS}}{ENDDATETIME} ) {

             $self->{WRITER}->startTag( 'TimeConstraint' );
             $self->{WRITER}->startTag( 'StartDateTime' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{STARTDATETIME} );
             $self->{WRITER}->endTag( 'StartDateTime' );
             $self->{WRITER}->startTag( 'EndDateTime' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{ENDDATETIME} );
             $self->{WRITER}->endTag( 'EndDateTime' );
             $self->{WRITER}->endTag( 'TimeConstraint' );
        }

        if ( defined ${$self->{OPTIONS}}{SERIESCOUNT} &&
             defined ${$self->{OPTIONS}}{INTERVAL} &&
             defined ${$self->{OPTIONS}}{TOLERANCE} ) {

             $self->{WRITER}->startTag( 'SeriesConstraint' );

             $self->{WRITER}->startTag( 'Count' );
             $self->{WRITER}->characters(${$self->{OPTIONS}}{SERIESCOUNT});
             $self->{WRITER}->endTag( 'Count' );

             $self->{WRITER}->startTag( 'Interval' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{INTERVAL});
             $self->{WRITER}->endTag( 'Interval' );

             $self->{WRITER}->startTag( 'Tolerance' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{TOLERANCE});
             $self->{WRITER}->endTag( 'Tolerance' );

             $self->{WRITER}->endTag( 'SeriesConstraint' );

        }

     $self->{WRITER}->endTag( 'Schedule' );

  $self->{WRITER}->endTag( 'Observation' );

  # Score Tags
  # ----------
  $self->{WRITER}->startTag( 'Score' );
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{SCORE} );
  $self->{WRITER}->endTag( 'Score' );
  $self->{WRITER}->startTag( 'CompletionTime' );
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{COMPLETIONTIME} );
  $self->{WRITER}->endTag( 'CompletionTime' );

  # close the RTML document
  # =======================
  $self->{WRITER}->endTag( 'RTML' );
  $self->{WRITER}->end();

  # return a good status (GLOBUS_TRUE)
  return 1;

}

=item B<request_observation>

Build a request document

   $status = $message->request_observation( Target     => $target_name,
                                            TargetIdent => "Observation",
                                            RA         => $ra,
                                            Dec        => $dec,
                                            Equinox    => $equinox,
                                            Score      => $score,
                                            Time       => $completion_time,
                                            Exposure   => $exposure,
                                            Snr        => $snr,
                                            Flux       => $mag,
                                            Filter     => filter,
                                          GroupCount    => $obs_per_group,
                                          SeriesCount   => $obs_per_series,
                                          Interval      => $interval,
                                          Tolerance     => $tolerance,
                                          TimeConstraint => [ $start_date,
                                                              $end_date ],
					  Priority      => $obs_priority   );

Use "Exposure", or "Snr" and "Flux", but not both. );

=cut

sub request_observation {
  my $self = shift;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / Target TargetType TargetIdent RA Dec Equinox Score Time
                Exposure Snr Flux Filter GroupCount SeriesCount
                    Interval Tolerance TimeConstraint Priority / ) {
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

  # open the document
  $self->{WRITER}->xmlDecl( 'US-ASCII' );
  $self->{WRITER}->doctype( 'RTML', '', ${$self->{OPTIONS}}{DTD} );

  # open the RTML document
  # ======================
  $self->{WRITER}->startTag( 'RTML',
                             'version' => '2.1',
                             'type' => 'request' );

  # IntelligentAgent Tag
  # --------------------

  # identify the IA
  $self->{WRITER}->startTag( 'IntelligentAgent',
                             'host' =>  ${$self->{OPTIONS}}{HOST},
                             'port' =>  ${$self->{OPTIONS}}{PORT} );

  # unique IA identity sting
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{ID} );

  $self->{WRITER}->endTag( 'IntelligentAgent' );

  # Telescope Tag
  # -------------
  $self->{WRITER}->emptyTag( 'Telescope' );

  # Contact Tag
  # -----------
  $self->{WRITER}->startTag( 'Contact', 'PI' => 'true' );

     $self->{WRITER}->startTag( 'User');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{USER} );
     $self->{WRITER}->endTag( 'User' );

     $self->{WRITER}->startTag( 'Name');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{NAME} );
     $self->{WRITER}->endTag( 'Name' );

     $self->{WRITER}->startTag( 'Institution');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{INSTITUTION} );
     $self->{WRITER}->endTag( 'Institution' );

     $self->{WRITER}->startTag( 'Email');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{EMAIL} );
     $self->{WRITER}->endTag( 'Email' );

  $self->{WRITER}->endTag( 'Contact' );

  # Project Tag
  # -------------
  $self->{WRITER}->emptyTag( 'Project' );

  # Observation tag
  # ---------------
  $self->{WRITER}->startTag( 'Observation', 'status' => 'ok' );

     $self->{WRITER}->startTag( 'Target', ,
                                'type' => ${$self->{OPTIONS}}{TARGETTYPE},
                                'ident' => ${$self->{OPTIONS}}{TARGETIDENT} );

        $self->{WRITER}->startTag( 'TargetName' );
        $self->{WRITER}->characters( ${$self->{OPTIONS}}{TARGET} );
        $self->{WRITER}->endTag( 'TargetName' );

        $self->{WRITER}->startTag( 'Coordinates', 'type' => 'equatorial' );

           $self->{WRITER}->startTag( 'RightAscension',
                                    'format' => 'hh mm ss.s', units => 'hms' );
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{RA} );
           $self->{WRITER}->endTag( 'RightAscension' );

           $self->{WRITER}->startTag( 'Declination',
                                    'format' => 'sdd mm ss.s', units => 'dms' );
           if ( ${$self->{OPTIONS}}{DEC} =~ m/^\+/ ) {
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{DEC} );
           } else {
              if ( ${$self->{OPTIONS}}{DEC} =~ m/-/ ) {
                $self->{WRITER}->characters( ${$self->{OPTIONS}}{DEC} );
              } else {
                $self->{WRITER}->characters( "+" . ${$self->{OPTIONS}}{DEC} );
              }
           }
           $self->{WRITER}->endTag( 'Declination' );

           $self->{WRITER}->startTag( 'Equinox'  );
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{EQUINOX} );
           $self->{WRITER}->endTag( 'Equinox' );

        $self->{WRITER}->endTag( 'Coordinates' );

        if( defined ${$self->{OPTIONS}}{SNR} ) {

           if( defined ${$self->{OPTIONS}}{FILTER} ) {
              $self->{WRITER}->startTag( 'Flux',
               'type' => 'continuum', 'units' => 'mag',
               'wavelength' => ${$self->{OPTIONS}}{FILTER} );
           } else {
              $self->{WRITER}->startTag( 'Flux',
               'type' => 'continuum', 'units' => 'mag', 'wavelength' => 'V' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{FLUX} );
           $self->{WRITER}->endTag( 'Flux' );
        }

     $self->{WRITER}->endTag( 'Target' );

     $self->{WRITER}->startTag( 'Device', 'type' => 'camera' );

           $self->{WRITER}->startTag( 'Filter' );

           if( defined ${$self->{OPTIONS}}{FILTER} ) {
              $self->{WRITER}->startTag( 'FilterType');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{FILTER} );
              $self->{WRITER}->endTag( 'FilterType' );
           } else {
              $self->{WRITER}->startTag( 'FilterType' );
              $self->{WRITER}->characters( 'V' );
              $self->{WRITER}->endTag( 'FilterType' );
           }

           $self->{WRITER}->endTag( 'Filter' );
     $self->{WRITER}->endTag( 'Device' );


     my $priority;
     if( defined ${$self->{OPTIONS}}{PRIORITY} ) {
        $priority = ${$self->{OPTIONS}}{PRIORITY};
     } else {
        $priority = 3;
     }

     $self->{WRITER}->startTag( 'Schedule', 'priority' => $priority );

        if( defined ${$self->{OPTIONS}}{SNR} ) {
           $self->{WRITER}->startTag( 'Exposure', 'type' => 'snr' );
           if( defined ${$self->{OPTIONS}}{GROUPCOUNT} &&
               ${$self->{OPTIONS}}{GROUPCOUNT} > 1 ) {
              $self->{WRITER}->startTag( 'Count');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{GROUPCOUNT} );
              $self->{WRITER}->endTag( 'Count' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{SNR} );
        } else {
           $self->{WRITER}->startTag( 'Exposure',
                                   'type' => 'time', 'units' => 'seconds' );
           if( defined ${$self->{OPTIONS}}{GROUPCOUNT} &&
               ${$self->{OPTIONS}}{GROUPCOUNT} > 1 ) {
              $self->{WRITER}->startTag( 'Count');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{GROUPCOUNT} );
              $self->{WRITER}->endTag( 'Count' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{EXPOSURE} );
        }
        $self->{WRITER}->endTag( 'Exposure' );

        if( defined ${$self->{OPTIONS}}{STARTDATETIME} &&
            defined ${$self->{OPTIONS}}{ENDDATETIME} ) {

             $self->{WRITER}->startTag( 'TimeConstraint' );
             $self->{WRITER}->startTag( 'StartDateTime' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{STARTDATETIME} );
             $self->{WRITER}->endTag( 'StartDateTime' );
             $self->{WRITER}->startTag( 'EndDateTime' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{ENDDATETIME} );
             $self->{WRITER}->endTag( 'EndDateTime' );
             $self->{WRITER}->endTag( 'TimeConstraint' );
        }

        if ( defined ${$self->{OPTIONS}}{SERIESCOUNT} &&
             defined ${$self->{OPTIONS}}{INTERVAL} &&
             defined ${$self->{OPTIONS}}{TOLERANCE} ) {

             $self->{WRITER}->startTag( 'SeriesConstraint' );

             $self->{WRITER}->startTag( 'Count' );
             $self->{WRITER}->characters(${$self->{OPTIONS}}{SERIESCOUNT});
             $self->{WRITER}->endTag( 'Count' );

             $self->{WRITER}->startTag( 'Interval' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{INTERVAL});
             $self->{WRITER}->endTag( 'Interval' );

             $self->{WRITER}->startTag( 'Tolerance' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{TOLERANCE});
             $self->{WRITER}->endTag( 'Tolerance' );

             $self->{WRITER}->endTag( 'SeriesConstraint' );

        }

     $self->{WRITER}->endTag( 'Schedule' );

  $self->{WRITER}->endTag( 'Observation' );

  # Score Tags
  # ----------
  $self->{WRITER}->startTag( 'Score' );
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{SCORE} );
  $self->{WRITER}->endTag( 'Score' );
  $self->{WRITER}->startTag( 'CompletionTime' );
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{COMPLETIONTIME} );
  $self->{WRITER}->endTag( 'CompletionTime' );


  # close the RTML document
  # =======================
  $self->{WRITER}->endTag( 'RTML' );
  $self->{WRITER}->end();

  # return a good status (GLOBUS_TRUE)
  return 1;

}

=item B<confirm_response>

Build a confirm response document

   $status = $message->confirm_response( Target        => $target_name,
                                         TargetIdent   => "Observation",
                                         RA            => $ra,
                                         Dec           => $dec,
                                         Equinox       => $equinox,
                                         Exposure      => $seconds,
                                         Snr           => $snr,
                                         Flux          => $mag,
                                         Score         => $score,
                                         Time          => $completion_time,
                                         Filter        => filter,
                                          GroupCount    => $obs_per_group,
                                          SeriesCount   => $obs_per_series,
                                          Interval      => $interval,
                                          Tolerance     => $tolerance,
                                          TimeConstraint => [ $start_date,
                                                              $end_date ],
					  Priority      => $obs_priority  );

Use "Exposure", or "Snr" and "Flux", but not both.

=cut

sub confirm_response {
  my $self = shift;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / Target TargetType TargetIdent RA Dec Equinox Exposure
                    Snr Flux Score Time Filter GroupCount SeriesCount
                    Interval Tolerance TimeConstraint Priority / ) {

     # print "Calling " . lc($key) ."()\n";
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

  # open the document
  $self->{WRITER}->xmlDecl( 'US-ASCII' );
  $self->{WRITER}->doctype( 'RTML', '', ${$self->{OPTIONS}}{DTD} );

  # open the RTML document
  # ======================
  $self->{WRITER}->startTag( 'RTML',
                             'version' => '2.1',
                             'type' => 'confirmation' );

  # IntelligentAgent Tag
  # --------------------

  # identify the IA
  $self->{WRITER}->startTag( 'IntelligentAgent',
                             'host' => ${$self->{OPTIONS}}{HOST},
                             'port' =>  ${$self->{OPTIONS}}{PORT} );

  # unique IA identity sting
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{ID} );

  $self->{WRITER}->endTag( 'IntelligentAgent' );

  # Telescope Tag
  # -------------
  $self->{WRITER}->emptyTag( 'Telescope' );

  # Contact Tag
  # -----------
  $self->{WRITER}->startTag( 'Contact', 'PI' => 'true' );

     $self->{WRITER}->startTag( 'User');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{USER} );
     $self->{WRITER}->endTag( 'User' );

     $self->{WRITER}->startTag( 'Name');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{NAME} );
     $self->{WRITER}->endTag( 'Name' );

     $self->{WRITER}->startTag( 'Institution');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{INSTITUTION} );
     $self->{WRITER}->endTag( 'Institution' );

     $self->{WRITER}->startTag( 'Email');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{EMAIL} );
     $self->{WRITER}->endTag( 'Email' );

  $self->{WRITER}->endTag( 'Contact' );

  # Project Tag
  # -------------
  $self->{WRITER}->emptyTag( 'Project' );

  # Observation tag
  # ---------------
  $self->{WRITER}->startTag( 'Observation', 'status' => 'ok' );

     $self->{WRITER}->startTag( 'Target', ,
                                'type' => ${$self->{OPTIONS}}{TARGETTYPE},
                                'ident' => ${$self->{OPTIONS}}{TARGETIDENT} );

        $self->{WRITER}->startTag( 'TargetName' );
        $self->{WRITER}->characters( ${$self->{OPTIONS}}{TARGET} );
        $self->{WRITER}->endTag( 'TargetName' );

        $self->{WRITER}->startTag( 'Coordinates', 'type' => 'equatorial' );

           $self->{WRITER}->startTag( 'RightAscension',
                                    'format' => 'hh mm ss.s', units => 'hms' );
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{RA} );
           $self->{WRITER}->endTag( 'RightAscension' );

           $self->{WRITER}->startTag( 'Declination',
                                    'format' => 'sdd mm ss.s', units => 'dms' );
           if ( ${$self->{OPTIONS}}{DEC} =~ m/^\+/ ) {
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{DEC} );
           } else {
              if ( ${$self->{OPTIONS}}{DEC} =~ m/-/ ) {
                $self->{WRITER}->characters( ${$self->{OPTIONS}}{DEC} );
              } else {
                $self->{WRITER}->characters( "+" . ${$self->{OPTIONS}}{DEC} );
              }
           }
           $self->{WRITER}->endTag( 'Declination' );

           $self->{WRITER}->startTag( 'Equinox'  );
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{EQUINOX} );
           $self->{WRITER}->endTag( 'Equinox' );

        $self->{WRITER}->endTag( 'Coordinates' );

        if( defined ${$self->{OPTIONS}}{SNR} ) {

           if( defined ${$self->{OPTIONS}}{FILTER} ) {
              $self->{WRITER}->startTag( 'Flux',
               'type' => 'continuum', 'units' => 'mag',
               'wavelength' => ${$self->{OPTIONS}}{FILTER} );
           } else {
              $self->{WRITER}->startTag( 'Flux',
               'type' => 'continuum', 'units' => 'mag', 'wavelength' => 'V' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{FLUX} );
           $self->{WRITER}->endTag( 'Flux' );
        }

     $self->{WRITER}->endTag( 'Target' );

     $self->{WRITER}->startTag( 'Device', 'type' => 'camera' );

           $self->{WRITER}->startTag( 'Filter' );

           if( defined ${$self->{OPTIONS}}{FILTER} ) {
              $self->{WRITER}->startTag( 'FilterType');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{FILTER} );
              $self->{WRITER}->endTag( 'FilterType' );
           } else {
              $self->{WRITER}->startTag( 'FilterType' );
              $self->{WRITER}->characters( 'V' );
              $self->{WRITER}->endTag( 'FilterType' );
           }

           $self->{WRITER}->endTag( 'Filter' );
     $self->{WRITER}->endTag( 'Device' );


     my $priority;
     if( defined ${$self->{OPTIONS}}{PRIORITY} ) {
        $priority = ${$self->{OPTIONS}}{PRIORITY};
     } else {
        $priority = 3;
     }

     $self->{WRITER}->startTag( 'Schedule', 'priority' => $priority );

        if( defined ${$self->{OPTIONS}}{SNR} ) {
           $self->{WRITER}->startTag( 'Exposure', 'type' => 'snr' );
           if( defined ${$self->{OPTIONS}}{GROUPCOUNT} &&
               ${$self->{OPTIONS}}{GROUPCOUNT} > 1 ) {
              $self->{WRITER}->startTag( 'Count');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{GROUPCOUNT} );
              $self->{WRITER}->endTag( 'Count' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{SNR} );
        } else {
           $self->{WRITER}->startTag( 'Exposure',
                                   'type' => 'time', 'units' => 'seconds' );
           if( defined ${$self->{OPTIONS}}{GROUPCOUNT} &&
               ${$self->{OPTIONS}}{GROUPCOUNT} > 1 ) {
              $self->{WRITER}->startTag( 'Count');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{GROUPCOUNT} );
              $self->{WRITER}->endTag( 'Count' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{EXPOSURE} );
        }
        $self->{WRITER}->endTag( 'Exposure' );

        if( defined ${$self->{OPTIONS}}{STARTDATETIME} &&
            defined ${$self->{OPTIONS}}{ENDDATETIME} ) {

             $self->{WRITER}->startTag( 'TimeConstraint' );
             $self->{WRITER}->startTag( 'StartDateTime' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{STARTDATETIME} );
             $self->{WRITER}->endTag( 'StartDateTime' );
             $self->{WRITER}->startTag( 'EndDateTime' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{ENDDATETIME} );
             $self->{WRITER}->endTag( 'EndDateTime' );
             $self->{WRITER}->endTag( 'TimeConstraint' );
        }

        if ( defined ${$self->{OPTIONS}}{SERIESCOUNT} &&
             defined ${$self->{OPTIONS}}{INTERVAL} &&
             defined ${$self->{OPTIONS}}{TOLERANCE} ) {

             $self->{WRITER}->startTag( 'SeriesConstraint' );

             $self->{WRITER}->startTag( 'Count' );
             $self->{WRITER}->characters(${$self->{OPTIONS}}{SERIESCOUNT});
             $self->{WRITER}->endTag( 'Count' );

             $self->{WRITER}->startTag( 'Interval' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{INTERVAL});
             $self->{WRITER}->endTag( 'Interval' );

             $self->{WRITER}->startTag( 'Tolerance' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{TOLERANCE});
             $self->{WRITER}->endTag( 'Tolerance' );

             $self->{WRITER}->endTag( 'SeriesConstraint' );

        }

     $self->{WRITER}->endTag( 'Schedule' );

  $self->{WRITER}->endTag( 'Observation' );

  # Score Tags
  # ----------
  $self->{WRITER}->startTag( 'Score' );
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{SCORE} );
  $self->{WRITER}->endTag( 'Score' );
  $self->{WRITER}->startTag( 'CompletionTime' );
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{COMPLETIONTIME} );
  $self->{WRITER}->endTag( 'CompletionTime' );

  # close the RTML document
  # =======================
  $self->{WRITER}->endTag( 'RTML' );
  $self->{WRITER}->end();

  # return a good status (GLOBUS_TRUE)
  return 1;

}


=item B<update_response>

Build a update response document

   $status = $message->update_response( Target        => $target_name,
                                        TargetIdent   => "Observation",
                                        RA            => $ra,
                                        Dec           => $dec,
                                        Equinox       => $equinox,
                                        Exposure      => $seconds,
                                        Snr           => $snr,
                                        Flux          => $mag,
                                        Score         => $score,
                                        Time          => $completion_time,
                                        Filter        => filter,
                                        Catalogue     => $cluster_catalog,
                                        Headers       => $fits_headers,
                                        ImageURI      => $image_uri,
                                          GroupCount    => $obs_per_group,
                                          SeriesCount   => $obs_per_series,
                                          Interval      => $interval,
                                          Tolerance     => $tolerance,
                                          TimeConstraint => [ $start_date,
                                                              $end_date ],
					  Priority      => $obs_priority   );

Use "Exposure", or "Snr" and "Flux", but not both.

=cut

sub update_response {
  my $self = shift;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / Target TargetType TargetIdent RA Dec Equinox Exposure
                    Snr Flux Score Time Filter Catalogue Headers ImageURI
                     GroupCount SeriesCount Interval
                     Tolerance TimeConstraint Priority / ) {

     # print "Calling " . lc($key) ."()\n";
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

  # open the document
  $self->{WRITER}->xmlDecl( 'US-ASCII' );
  $self->{WRITER}->doctype( 'RTML', '', ${$self->{OPTIONS}}{DTD} );

  # open the RTML document
  # ======================
  $self->{WRITER}->startTag( 'RTML',
                             'version' => '2.1',
                             'type' => 'update' );

  # IntelligentAgent Tag
  # --------------------

  # identify the IA
  $self->{WRITER}->startTag( 'IntelligentAgent',
                             'host' => ${$self->{OPTIONS}}{HOST},
                             'port' =>  ${$self->{OPTIONS}}{PORT} );

  # unique IA identity sting
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{ID} );

  $self->{WRITER}->endTag( 'IntelligentAgent' );

  # Telescope Tag
  # -------------
  $self->{WRITER}->emptyTag( 'Telescope' );

  # Contact Tag
  # -----------
  $self->{WRITER}->startTag( 'Contact', 'PI' => 'true' );

     $self->{WRITER}->startTag( 'User');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{USER} );
     $self->{WRITER}->endTag( 'User' );

     $self->{WRITER}->startTag( 'Name');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{NAME} );
     $self->{WRITER}->endTag( 'Name' );

     $self->{WRITER}->startTag( 'Institution');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{INSTITUTION} );
     $self->{WRITER}->endTag( 'Institution' );

     $self->{WRITER}->startTag( 'Email');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{EMAIL} );
     $self->{WRITER}->endTag( 'Email' );

  $self->{WRITER}->endTag( 'Contact' );

  # Project Tag
  # -------------
  $self->{WRITER}->emptyTag( 'Project' );

  # Observation tag
  # ---------------
  $self->{WRITER}->startTag( 'Observation', 'status' => 'ok' );

     $self->{WRITER}->startTag( 'Target',
                                'type' => ${$self->{OPTIONS}}{TARGETTYPE},
                                'ident' => ${$self->{OPTIONS}}{TARGETIDENT} );

        $self->{WRITER}->startTag( 'TargetName' );
        $self->{WRITER}->characters( ${$self->{OPTIONS}}{TARGET} );
        $self->{WRITER}->endTag( 'TargetName' );

        $self->{WRITER}->startTag( 'Coordinates', 'type' => 'equatorial' );

           $self->{WRITER}->startTag( 'RightAscension',
                                    'format' => 'hh mm ss.s', units => 'hms' );
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{RA} );
           $self->{WRITER}->endTag( 'RightAscension' );

           $self->{WRITER}->startTag( 'Declination',
                                    'format' => 'sdd mm ss.s', units => 'dms' );
           if ( ${$self->{OPTIONS}}{DEC} =~ m/^\+/ ) {
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{DEC} );
           } else {
              if ( ${$self->{OPTIONS}}{DEC} =~ m/-/ ) {
                $self->{WRITER}->characters( ${$self->{OPTIONS}}{DEC} );
              } else {
                $self->{WRITER}->characters( "+" . ${$self->{OPTIONS}}{DEC} );
              }
           }
           $self->{WRITER}->endTag( 'Declination' );

           $self->{WRITER}->startTag( 'Equinox'  );
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{EQUINOX} );
           $self->{WRITER}->endTag( 'Equinox' );

        $self->{WRITER}->endTag( 'Coordinates' );

        if( defined ${$self->{OPTIONS}}{SNR} ) {

           if( defined ${$self->{OPTIONS}}{FILTER} ) {
              $self->{WRITER}->startTag( 'Flux',
               'type' => 'continuum', 'units' => 'mag',
               'wavelength' => ${$self->{OPTIONS}}{FILTER} );
           } else {
              $self->{WRITER}->startTag( 'Flux',
               'type' => 'continuum', 'units' => 'mag', 'wavelength' => 'V' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{FLUX} );
           $self->{WRITER}->endTag( 'Flux' );
        }

     $self->{WRITER}->endTag( 'Target' );

     $self->{WRITER}->startTag( 'Device', 'type' => 'camera' );

           $self->{WRITER}->startTag( 'Filter' );

           if( defined ${$self->{OPTIONS}}{FILTER} ) {
              $self->{WRITER}->startTag( 'FilterType');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{FILTER} );
              $self->{WRITER}->endTag( 'FilterType' );
           } else {
              $self->{WRITER}->startTag( 'FilterType' );
              $self->{WRITER}->characters( 'V' );
              $self->{WRITER}->endTag( 'FilterType' );
           }

           $self->{WRITER}->endTag( 'Filter' );
     $self->{WRITER}->endTag( 'Device' );


     my $priority;
     if( defined ${$self->{OPTIONS}}{PRIORITY} ) {
        $priority = ${$self->{OPTIONS}}{PRIORITY};
     } else {
        $priority = 3;
     }

     $self->{WRITER}->startTag( 'Schedule', 'priority' => $priority );

        if( defined ${$self->{OPTIONS}}{SNR} ) {
           $self->{WRITER}->startTag( 'Exposure', 'type' => 'snr' );
           if( defined ${$self->{OPTIONS}}{GROUPCOUNT} &&
               ${$self->{OPTIONS}}{GROUPCOUNT} > 1 ) {
              $self->{WRITER}->startTag( 'Count');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{GROUPCOUNT} );
              $self->{WRITER}->endTag( 'Count' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{SNR} );
        } else {
           $self->{WRITER}->startTag( 'Exposure',
                                   'type' => 'time', 'units' => 'seconds' );
           if( defined ${$self->{OPTIONS}}{GROUPCOUNT} &&
               ${$self->{OPTIONS}}{GROUPCOUNT} > 1 ) {
              $self->{WRITER}->startTag( 'Count');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{GROUPCOUNT} );
              $self->{WRITER}->endTag( 'Count' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{EXPOSURE} );
        }
        $self->{WRITER}->endTag( 'Exposure' );

        if( defined ${$self->{OPTIONS}}{STARTDATETIME} &&
            defined ${$self->{OPTIONS}}{ENDDATETIME} ) {

             $self->{WRITER}->startTag( 'TimeConstraint' );
             $self->{WRITER}->startTag( 'StartDateTime' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{STARTDATETIME} );
             $self->{WRITER}->endTag( 'StartDateTime' );
             $self->{WRITER}->startTag( 'EndDateTime' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{ENDDATETIME} );
             $self->{WRITER}->endTag( 'EndDateTime' );
             $self->{WRITER}->endTag( 'TimeConstraint' );
        }

        if ( defined ${$self->{OPTIONS}}{SERIESCOUNT} &&
             defined ${$self->{OPTIONS}}{INTERVAL} &&
             defined ${$self->{OPTIONS}}{TOLERANCE} ) {

             $self->{WRITER}->startTag( 'SeriesConstraint' );

             $self->{WRITER}->startTag( 'Count' );
             $self->{WRITER}->characters(${$self->{OPTIONS}}{SERIESCOUNT});
             $self->{WRITER}->endTag( 'Count' );

             $self->{WRITER}->startTag( 'Interval' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{INTERVAL});
             $self->{WRITER}->endTag( 'Interval' );

             $self->{WRITER}->startTag( 'Tolerance' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{TOLERANCE});
             $self->{WRITER}->endTag( 'Tolerance' );

             $self->{WRITER}->endTag( 'SeriesConstraint' );

        }

     $self->{WRITER}->endTag( 'Schedule' );

     # ObjectList
     # ----------
     $self->{WRITER}->startTag( 'ObjectList',
'type' => "cluster", 'number' => "all",
'format' => " fn sn rah ram ras decd decm decs xpos ypos mag magerror magflag");
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{CATALOG} );
     $self->{WRITER}->endTag( 'ObjectList' );

     # ImageData
     # ---------
     $self->{WRITER}->startTag( 'ImageData',
         type => "FITS16", delivery => "url", reduced => "true" );
            $self->{WRITER}->characters( ${$self->{OPTIONS}}{IMAGE_URI} );
     $self->{WRITER}->endTag( 'ImageData' );


     # FITS Headers
     # ------------
     $self->{WRITER}->startTag( 'FITSHeader', type => "all" );
            $self->{WRITER}->characters( ${$self->{OPTIONS}}{HEADERS} );
     $self->{WRITER}->endTag( 'FITSHeader' );


  $self->{WRITER}->endTag( 'Observation' );

  # Score Tags
  # ----------
  $self->{WRITER}->startTag( 'Score' );
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{SCORE} );
  $self->{WRITER}->endTag( 'Score' );
  $self->{WRITER}->startTag( 'CompletionTime' );
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{COMPLETIONTIME} );
  $self->{WRITER}->endTag( 'CompletionTime' );

  # close the RTML document
  # =======================
  $self->{WRITER}->endTag( 'RTML' );
  $self->{WRITER}->end();

  # return a good status (GLOBUS_TRUE)
  return 1;

}

=item B<complete_response>

Build a complete response document

   $status = $message->complete_response( Target        => $target_name,
                                          TargetIdent    => "Observation",
                                        RA            => $ra,
                                        Dec           => $dec,
                                        Equinox       => $equinox,
                                        Exposure      => $seconds,
                                        Snr           => $snr,
                                        Flux          => $mag,
                                        Score         => $score,
                                        Time          => $completion_time,
                                        Filter        => filter,
                                        Catalogue     => $cluster_catalog,
                                        Headers       => $fits_headers,
                                        ImageURI      => $image_uri,
                                          GroupCount    => $obs_per_group,
                                          SeriesCount   => $obs_per_series,
                                          Interval      => $interval,
                                          Tolerance     => $tolerance,
                                          TimeConstraint => [ $start_date,
                                                              $end_date ],
					  Priority      => $obs_priority   );

Use "Exposure", or "Snr" and "Flux", but not both.

=cut

sub complete_response {
  my $self = shift;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / Target TargetType TargetIdent RA Dec Equinox Exposure
                    Snr Flux Score Time Filter Catalogue Headers ImageURI
                    GroupCount SeriesCount Interval
                    Tolerance TimeConstraint Priority / ) {

     # print "Calling " . lc($key) ."()\n";
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

  # open the document
  $self->{WRITER}->xmlDecl( 'US-ASCII' );
  $self->{WRITER}->doctype( 'RTML', '', ${$self->{OPTIONS}}{DTD} );

  # open the RTML document
  # ======================
  $self->{WRITER}->startTag( 'RTML',
                             'version' => '2.1',
                             'type' => 'observation' );

  # IntelligentAgent Tag
  # --------------------

  # identify the IA
  $self->{WRITER}->startTag( 'IntelligentAgent',
                             'host' => ${$self->{OPTIONS}}{HOST},
                             'port' =>  ${$self->{OPTIONS}}{PORT} );

  # unique IA identity sting
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{ID} );

  $self->{WRITER}->endTag( 'IntelligentAgent' );

  # Telescope Tag
  # -------------
  $self->{WRITER}->emptyTag( 'Telescope' );

  # Contact Tag
  # -----------
  $self->{WRITER}->startTag( 'Contact', 'PI' => 'true' );

     $self->{WRITER}->startTag( 'User');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{USER} );
     $self->{WRITER}->endTag( 'User' );

     $self->{WRITER}->startTag( 'Name');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{NAME} );
     $self->{WRITER}->endTag( 'Name' );

     $self->{WRITER}->startTag( 'Institution');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{INSTITUTION} );
     $self->{WRITER}->endTag( 'Institution' );

     $self->{WRITER}->startTag( 'Email');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{EMAIL} );
     $self->{WRITER}->endTag( 'Email' );

  $self->{WRITER}->endTag( 'Contact' );

  # Project Tag
  # -------------
  $self->{WRITER}->emptyTag( 'Project' );

  # Observation tag
  # ---------------
  $self->{WRITER}->startTag( 'Observation', 'status' => 'ok' );

     $self->{WRITER}->startTag( 'Target', ,
                                'type' => ${$self->{OPTIONS}}{TARGETTYPE},
                                'ident' => ${$self->{OPTIONS}}{TARGETIDENT} );

        $self->{WRITER}->startTag( 'TargetName' );
        $self->{WRITER}->characters( ${$self->{OPTIONS}}{TARGET} );
        $self->{WRITER}->endTag( 'TargetName' );

        $self->{WRITER}->startTag( 'Coordinates', 'type' => 'equatorial' );

           $self->{WRITER}->startTag( 'RightAscension',
                                    'format' => 'hh mm ss.s', units => 'hms' );
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{RA} );
           $self->{WRITER}->endTag( 'RightAscension' );

           $self->{WRITER}->startTag( 'Declination',
                                    'format' => 'sdd mm ss.s', units => 'dms' );
           if ( ${$self->{OPTIONS}}{DEC} =~ m/^\+/ ) {
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{DEC} );
           } else {
              if ( ${$self->{OPTIONS}}{DEC} =~ m/-/ ) {
                $self->{WRITER}->characters( ${$self->{OPTIONS}}{DEC} );
              } else {
                $self->{WRITER}->characters( "+" . ${$self->{OPTIONS}}{DEC} );
              }
           }
           $self->{WRITER}->endTag( 'Declination' );

           $self->{WRITER}->startTag( 'Equinox'  );
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{EQUINOX} );
           $self->{WRITER}->endTag( 'Equinox' );

        $self->{WRITER}->endTag( 'Coordinates' );

        if( defined ${$self->{OPTIONS}}{SNR} ) {

           if( defined ${$self->{OPTIONS}}{FILTER} ) {
              $self->{WRITER}->startTag( 'Flux',
               'type' => 'continuum', 'units' => 'mag',
               'wavelength' => ${$self->{OPTIONS}}{FILTER} );
           } else {
              $self->{WRITER}->startTag( 'Flux',
               'type' => 'continuum', 'units' => 'mag', 'wavelength' => 'V' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{FLUX} );
           $self->{WRITER}->endTag( 'Flux' );
        }

     $self->{WRITER}->endTag( 'Target' );

     $self->{WRITER}->startTag( 'Device', 'type' => 'camera' );

           $self->{WRITER}->startTag( 'Filter' );

           if( defined ${$self->{OPTIONS}}{FILTER} ) {
              $self->{WRITER}->startTag( 'FilterType');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{FILTER} );
              $self->{WRITER}->endTag( 'FilterType' );
           } else {
              $self->{WRITER}->startTag( 'FilterType' );
              $self->{WRITER}->characters( 'V' );
              $self->{WRITER}->endTag( 'FilterType' );
           }

           $self->{WRITER}->endTag( 'Filter' );
     $self->{WRITER}->endTag( 'Device' );


     my $priority;
     if( defined ${$self->{OPTIONS}}{PRIORITY} ) {
        $priority = ${$self->{OPTIONS}}{PRIORITY};
     } else {
        $priority = 3;
     }

     $self->{WRITER}->startTag( 'Schedule', 'priority' => $priority );

        if( defined ${$self->{OPTIONS}}{SNR} ) {
           $self->{WRITER}->startTag( 'Exposure', 'type' => 'snr' );
           if( defined ${$self->{OPTIONS}}{GROUPCOUNT} &&
               ${$self->{OPTIONS}}{GROUPCOUNT} > 1 ) {
              $self->{WRITER}->startTag( 'Count');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{GROUPCOUNT} );
              $self->{WRITER}->endTag( 'Count' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{SNR} );
        } else {
           $self->{WRITER}->startTag( 'Exposure',
                                   'type' => 'time', 'units' => 'seconds' );
           if( defined ${$self->{OPTIONS}}{GROUPCOUNT} &&
               ${$self->{OPTIONS}}{GROUPCOUNT} > 1 ) {
              $self->{WRITER}->startTag( 'Count');
              $self->{WRITER}->characters( ${$self->{OPTIONS}}{GROUPCOUNT} );
              $self->{WRITER}->endTag( 'Count' );
           }
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{EXPOSURE} );
        }
        $self->{WRITER}->endTag( 'Exposure' );

        if( defined ${$self->{OPTIONS}}{STARTDATETIME} &&
            defined ${$self->{OPTIONS}}{ENDDATETIME} ) {

             $self->{WRITER}->startTag( 'TimeConstraint' );
             $self->{WRITER}->startTag( 'StartDateTime' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{STARTDATETIME} );
             $self->{WRITER}->endTag( 'StartDateTime' );
             $self->{WRITER}->startTag( 'EndDateTime' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{ENDDATETIME} );
             $self->{WRITER}->endTag( 'EndDateTime' );
             $self->{WRITER}->endTag( 'TimeConstraint' );
        }

        if ( defined ${$self->{OPTIONS}}{SERIESCOUNT} &&
             defined ${$self->{OPTIONS}}{INTERVAL} &&
             defined ${$self->{OPTIONS}}{TOLERANCE} ) {

             $self->{WRITER}->startTag( 'SeriesConstraint' );

             $self->{WRITER}->startTag( 'Count' );
             $self->{WRITER}->characters(${$self->{OPTIONS}}{SERIESCOUNT});
             $self->{WRITER}->endTag( 'Count' );

             $self->{WRITER}->startTag( 'Interval' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{INTERVAL});
             $self->{WRITER}->endTag( 'Interval' );

             $self->{WRITER}->startTag( 'Tolerance' );
             $self->{WRITER}->characters( ${$self->{OPTIONS}}{TOLERANCE});
             $self->{WRITER}->endTag( 'Tolerance' );

             $self->{WRITER}->endTag( 'SeriesConstraint' );

        }

     $self->{WRITER}->endTag( 'Schedule' );

     # ObjectList
     # ----------
     $self->{WRITER}->startTag( 'ObjectList',
'type' => "cluster", 'number' => "all",
'format' => " fn sn rah ram ras decd decm decs xpos ypos mag magerror magflag");
           $self->{WRITER}->characters( ${$self->{OPTIONS}}{CATALOG} );
     $self->{WRITER}->endTag( 'ObjectList' );

     # ImageData
     # ---------
     $self->{WRITER}->startTag( 'ImageData',
         type => "FITS16", delivery => "url", reduced => "true" );
            $self->{WRITER}->characters( ${$self->{OPTIONS}}{IMAGE_URI} );
     $self->{WRITER}->endTag( 'ImageData' );


     # FITS Headers
     # ------------
     $self->{WRITER}->startTag( 'FITSHeader', type => "all" );
            $self->{WRITER}->characters( ${$self->{OPTIONS}}{HEADERS} );
     $self->{WRITER}->endTag( 'FITSHeader' );


  $self->{WRITER}->endTag( 'Observation' );

  # Score Tags
  # ----------
  $self->{WRITER}->startTag( 'Score' );
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{SCORE} );
  $self->{WRITER}->endTag( 'Score' );
  $self->{WRITER}->startTag( 'CompletionTime' );
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{COMPLETIONTIME} );
  $self->{WRITER}->endTag( 'CompletionTime' );

  # close the RTML document
  # =======================
  $self->{WRITER}->endTag( 'RTML' );
  $self->{WRITER}->end();

  # return a good status (GLOBUS_TRUE)
  return 1;

}

=item B<reject_response>

Build a reject document

   $status = $message->reject_response( );

=cut

sub reject_response {
  my $self = shift;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / / ) {

     # print "Calling " . lc($key) ."()\n";
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

  # open the document
  $self->{WRITER}->xmlDecl( 'US-ASCII' );
  $self->{WRITER}->doctype( 'RTML', '', ${$self->{OPTIONS}}{DTD} );

  # open the RTML document
  # ======================
  $self->{WRITER}->startTag( 'RTML',
                             'version' => '2.1',
                             'type' => 'reject' );

  # IntelligentAgent Tag
  # --------------------

  # identify the IA
  $self->{WRITER}->startTag( 'IntelligentAgent',
                             'host' => ${$self->{OPTIONS}}{HOST},
                             'port' =>  ${$self->{OPTIONS}}{PORT} );

  # unique IA identity sting
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{ID} );

  $self->{WRITER}->endTag( 'IntelligentAgent' );

  # Contact Tag
  # -----------
  $self->{WRITER}->startTag( 'Contact', 'PI' => 'true' );

     $self->{WRITER}->startTag( 'User');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{USER} );
     $self->{WRITER}->endTag( 'User' );

     $self->{WRITER}->startTag( 'Name');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{NAME} );
     $self->{WRITER}->endTag( 'Name' );

     $self->{WRITER}->startTag( 'Institution');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{INSTITUTION} );
     $self->{WRITER}->endTag( 'Institution' );

     $self->{WRITER}->startTag( 'Email');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{EMAIL} );
     $self->{WRITER}->endTag( 'Email' );

  $self->{WRITER}->endTag( 'Contact' );

  # close the RTML document
  # =======================
  $self->{WRITER}->endTag( 'RTML' );
  $self->{WRITER}->end();

  # return a good status (GLOBUS_TRUE)
  return 1;

}


=item B<failure_response>

Build a fail document

   $status = $message->failure_response( );

=cut

sub failure_response {
  my $self = shift;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / / ) {

     # print "Calling " . lc($key) ."()\n";
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

  # open the document
  $self->{WRITER}->xmlDecl( 'US-ASCII' );
  $self->{WRITER}->doctype( 'RTML', '', ${$self->{OPTIONS}}{DTD} );

  # open the RTML document
  # ======================
  $self->{WRITER}->startTag( 'RTML',
                             'version' => '2.1',
                             'type' => 'failed' );

  # IntelligentAgent Tag
  # --------------------

  # identify the IA
  $self->{WRITER}->startTag( 'IntelligentAgent',
                             'host' => ${$self->{OPTIONS}}{HOST},
                             'port' =>  ${$self->{OPTIONS}}{PORT} );

  # unique IA identity sting
  $self->{WRITER}->characters( ${$self->{OPTIONS}}{ID} );

  $self->{WRITER}->endTag( 'IntelligentAgent' );

  # Contact Tag
  # -----------
  $self->{WRITER}->startTag( 'Contact', 'PI' => 'true' );

     $self->{WRITER}->startTag( 'User');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{USER} );
     $self->{WRITER}->endTag( 'User' );

     $self->{WRITER}->startTag( 'Name');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{NAME} );
     $self->{WRITER}->endTag( 'Name' );

     $self->{WRITER}->startTag( 'Institution');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{INSTITUTION} );
     $self->{WRITER}->endTag( 'Institution' );

     $self->{WRITER}->startTag( 'Email');
     $self->{WRITER}->characters( ${$self->{OPTIONS}}{EMAIL} );
     $self->{WRITER}->endTag( 'Email' );

  $self->{WRITER}->endTag( 'Contact' );

  # close the RTML document
  # =======================
  $self->{WRITER}->endTag( 'RTML' );
  $self->{WRITER}->end();

  # return a good status (GLOBUS_TRUE)
  return 1;

}

=item B<dump_rtml>

Dumps the contents of the RTML buffer in memory to a scalar

   $string = $message->dump_rtml();

=cut

sub dump_rtml {
  my $self = shift;
  return $self->{BUFFER}->value();

}

# A C C E S S O R   M  E T H O D S ------------------------------------------
=back

=head2 Accessor Methods

=over 4

=item B<port>

Sets (or returns) the port which the Discovey Node should send RTML
messages to (ie the port on which the IA is listening).

   $message->port( '8080' );
   $port = $message->port();

defautls to 8000.

=cut

sub port {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{PORT} = shift;
  }

  # return the current port
  return ${$self->{OPTIONS}}{PORT};
}

=item B<host>

Sets (or returns) the machine on which the IA is running

   $message->host( $hostname );
   $host = $message->host();

defaults to the current machine's IP address

=cut

sub host {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{HOST} = shift;
  }

  # return the current port
  return ${$self->{OPTIONS}}{HOST};
}

=item B<id>

Sets (or returns) the unique ID for the Intelligent Agent request

   $message->id( 'IATEST0001:CT1:0013' );
   $id = $message->id();

note that there is NO DEFAULT, a unique ID for the score/observing
request must be supplied, see the eSTAR Communications and the ERS
command set documents for further details.

=cut

sub id {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{ID} = shift;
  }

  # return the current ID
  return ${$self->{OPTIONS}}{ID};
}

=item B<user>

Sets (or returns) the user name of the observer

   $message->user( 'aa' );
   $user = $message->user();

=cut

sub user {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{USER} = shift;
  }

  # return the current ID
  return ${$self->{OPTIONS}}{USER};
}

=item B<name>

Sets (or returns) the name of the observer

   $message->name( 'Alasdair Allan' );
   $name = $message->name();

=cut

sub name {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{NAME} = shift;
  }

  # return the current ID
  return ${$self->{OPTIONS}}{NAME};
}

=item B<institution>

Sets (or returns) the Institution of the observer

   $message->institution( 'University of Exeter' );
   $dept_name = $message->institution();

=cut

sub institution {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{INSTITUTION} = shift;
  }

  # return the current ID
  return ${$self->{OPTIONS}}{INSTITUTION};
}

=item B<email>

Sets (or returns) the email address of the observer

   $message->email( 'aa@astro.ex.ac.uk' );
   $email_address = $message->email();

=cut

sub email {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{EMAIL} = shift;
  }

  # return the current ID
  return ${$self->{OPTIONS}}{EMAIL};
}

=item B<target>

Sets (or returns) the target name

   $message->email( 'EX Hya' );
   $target_name = $message->target();

=cut

sub target {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{TARGET} = shift;
  }

  # return the current target ID
  return ${$self->{OPTIONS}}{TARGET};
}


=item B<ra>

Sets (or returns) the target RA

   $message->ra( '12 35 65.0' );
   $ra = $message->ra();

must be in the form HH MM SS.S.

=cut

sub ra {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{RA} = shift;
  }

  # return the current target RA
  return ${$self->{OPTIONS}}{RA};
}

=item B<dec>

Sets (or returns) the target DEC

   $message->dec( '+60 35 32' );
   $dec = $message->dec();

must be in the form SDD MM SS.S.

=cut

sub dec {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{DEC} = shift;
  }

  # return the current target DEC
  return ${$self->{OPTIONS}}{DEC};
}

=item B<equinox>

Sets (or returns) the equinox of the target co-ordinates

   $message->equinox( 'B1950' );
   $equnox = $message->equinox();

default is J2000, currently the telescope expects J2000.0 coordinates, no
translation is currently carried out by the library before formatting the
RTML message. It is therefore suggested that the user therefoer provides
their coordinates in J2000.0 as this is merely a placeholder routine.

=cut

sub equinox {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{EQUINOX} = shift;
  }

  # return the current co-ord equinox
  return ${$self->{OPTIONS}}{EQUINOX};
}


=item B<score>

Sets (or returns) the target score

   $message->score( $score );
   $score = $message->score();

the score will be between 0.0 and 1.0

=cut

sub score {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{SCORE} = shift;
  }

  # return the current target score
  return ${$self->{OPTIONS}}{SCORE};
}


=item B<filter>

Sets (or returns) the target filter required

   $message->filter( $filter );
   $filter = $message->filter();

=cut

sub filter {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{FILTER} = shift;
  }

  # return the current filter
  return ${$self->{OPTIONS}}{FILTER};
}

=item B<time>

Sets (or returns) the target completion time

   $message->time( $time );
   $time = $message->time();

the completion time should be of the format YYYY-MM-DDTHH:MM:SS

=cut

sub time {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{COMPLETIONTIME} = shift;
  }

  # return the current target score
  return ${$self->{OPTIONS}}{COMPLETIONTIME};
}

=item B<exposure>

Sets (or returns) the exposure time for the image

   $message->exposure( $time );
   $time = $message->time();

the time should be in seconds, alternatively you can supply a C<flux()> and
C<snr()> rather than a time to expose on target.

=cut

sub exposure {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{EXPOSURE} = shift;
  }

  # return the current target exposure
  return ${$self->{OPTIONS}}{EXPOSURE};
}


=item B<snr>

Sets (or returns) the signal to noise for the image

   $message->snr( $sn );
   $sn = $message->snr();

the signatl to noise ratio  should be a floating point number, alternatively
you can supply a C<exposure()> in seconds.

=cut

sub snr {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{SNR} = shift;
  }

  # return the current target snr
  return ${$self->{OPTIONS}}{SNR};
}


=item B<targettype>

Sets (or returns) the target type for the image

   $message->targettype( $type );
   $type = $message->targettype();

the target type defaults to "normal" if unspecified.

=cut

sub targettype {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{TARGETTYPE} = shift;
  }

  # return the current target type
  return ${$self->{OPTIONS}}{TARGETTYPE};
}

=item B<targetident>

Sets (or returns) the target type for the image

   $message->targetident( $ident );
   $ident = $message->targetident();

the target type defaults to "SingleExposure" if unspecified.

=cut

sub targetident {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{TARGETIDENT} = shift;
  }

  # return the current target type
  return ${$self->{OPTIONS}}{TARGETIDENT};
}
=item B<flux>

Sets (or returns) the flux of teh object needed for signal to noise
calculations for the image

   $message->flux( $mag );
   $mag = $message->flux();

the flux should be a continuum V band magnitude value.

=cut

sub flux {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{FLUX} = shift;
  }

  # return the current flux in magntitudes
  return ${$self->{OPTIONS}}{FLUX};
}

=item B<catalogue>

Sets (or returns) a scalar containing the serialised point source
catalogue for the observations

   $message->catalogue( $catalog );
   $catalog = $message->catalogue();

the catalogue should be in Cluster Format.

=cut

sub catalogue {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{CATALOG} = shift;
  }

  # return the catalog
  return ${$self->{OPTIONS}}{CATALOG};
}

=item B<headers>

Sets (or returns) the FITS Headers associated with the current
observation

   $message->headers( $headerblock );
   $headerblock = $message->headers();

=cut

sub headers {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{HEADERS} = shift;
  }

  return ${$self->{OPTIONS}}{HEADERS};
}

=item B<imageuri>

Sets (or returns) the URI of the FITS image assocaited with the
current observation (message)

   $message->imageuri( $uri );
   $uri = $message->imageuri();

the should be presented as a string, not a URI object.

=cut

sub imageuri {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{IMAGE_URI} = shift;
  }

  # return the current flux in magntitudes
  return ${$self->{OPTIONS}}{IMAGE_URI};
}

=item B<groupcount>

Gets or sets the count on the monitoring group

=cut

sub groupcount {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{GROUPCOUNT} = shift;
  }

  return ${$self->{OPTIONS}}{GROUPCOUNT};

}

=item B<seriescount>

Gets or sets the number of observations (monitor groups) to be taken

=cut

sub  seriescount {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{SERIESCOUNT} = shift;
  }

  return ${$self->{OPTIONS}}{SERIESCOUNT};

}

=item B<interval>

Gets or sets the interval between monitoring groups

=cut

sub  interval {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{INTERVAL} = shift;
    unless ( ${$self->{OPTIONS}}{INTERVAL} =~ "PT" ) {
       ${$self->{OPTIONS}}{INTERVAL} = "PT" . ${$self->{OPTIONS}}{INTERVAL};
    }
  }

  return ${$self->{OPTIONS}}{INTERVAL};

}

=item B<tolerance>

Gets or sets the tolerance we have for the interval spacing

=cut

sub  tolerance {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{TOLERANCE} = shift;
    unless ( ${$self->{OPTIONS}}{TOLERANCE} =~ "PT" ) {
       ${$self->{OPTIONS}}{TOLERANCE} = "PT" . ${$self->{OPTIONS}}{TOLERANCE};
    }
  }

  return ${$self->{OPTIONS}}{TOLERANCE};


}


=item B<time constraint>

Gets or sets the time constraint, takes an array ref.

=cut

sub timeconstraint {
  my $self = shift;

  if (@_) {

    my $ref = shift;
    my @array = @{$ref};

    ${$self->{OPTIONS}}{STARTDATETIME} = $array[0];
    ${$self->{OPTIONS}}{ENDDATETIME} = $array[1];
  }

  return (${$self->{OPTIONS}}{STARTDATETIME},${$self->{OPTIONS}}{ENDDATETIME});


}


=item B<priority>

Gets or sets the priority of the observations (monitor groups) to be taken

=cut

sub  priority {
  my $self = shift;

  if (@_) {
    ${$self->{OPTIONS}}{PRIORITY} = shift;
  }

  return ${$self->{OPTIONS}}{PRIORITY};

}

# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as an argument

  $message->configure( %options );

does nothing if the hash is not supplied.

=cut

sub configure {
  my $self = shift;

  # Create the RTML::Writer object
  # ------------------
  $self->{BUFFER} = new XML::Writer::String();
  $self->{WRITER} = new XML::Writer( OUTPUT      => $self->{BUFFER},
                                     DATA_MODE   => 1,
                                     UNSAFE      => 1,
                                     DATA_INDENT => 4 );

  # DEFAULTS
  # --------

  # use the RTML Namespace as defined by the v2.2 DTD
  ${$self->{OPTIONS}}{DTD} = "http://www.estar.org.uk/documents/rtml2.2.dtd";

  #${$self->{OPTIONS}}{HOST} = hostname() . "." . hostdomain();
  ${$self->{OPTIONS}}{HOST} = "127.0.0.1";
  ${$self->{OPTIONS}}{PORT} = '8000';

  ${$self->{OPTIONS}}{EQUINOX} = 'J2000';


  ${$self->{OPTIONS}}{TARGETTYPE} = 'normal';
  ${$self->{OPTIONS}}{TARGETIDENT} = 'SingleExposure';

  # ARGUEMENTS
  # ----------

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  # Loop over the allowed keys and modify the default query options
  for my $key (qw / Port ID User Name Institution Email Host / ) {
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

}

=item B<freeze>

Method to return a blessed reference to the object so that we can store
ths object on disk using Data::Dumper module.

=cut

sub freeze {
  my $self = shift;
  return bless $self, 'eSTAR::RTML::Build';
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

# L A S T  O R D E R S ------------------------------------------------------

1;
