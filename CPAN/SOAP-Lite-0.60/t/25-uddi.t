#!/bin/env perl 

BEGIN {
  unless(grep /blib/, @INC) {
    chdir 't' if -d 't';
    unshift @INC, '../lib' if -d '../lib';
  }
}

use strict;
use Test;

use UDDI::Lite 
  import => 'UDDI::Data',
  import => 'UDDI::Lite',
  proxy => 'http://uddi.microsoft.com/inquire';

my($a, $s, $r, $serialized, $deserialized);

# ------------------------------------------------------
use SOAP::Test;

$s = SOAP::Lite->uri('http://something/somewhere')->proxy('http://uddi.microsoft.com/inquire')->on_fault(sub{});
eval { $s->transport->timeout($SOAP::Test::TIMEOUT = $SOAP::Test::TIMEOUT) };
$r = $s->test_connection;

unless (defined $r && defined $r->envelope) {
  print "1..0 # Skip: ", $s->transport->status, "\n"; 
  exit;
}
# ------------------------------------------------------

plan tests => 17;

{
  $a = bindingTemplate([
    accessPoint('someurl'), 
    tModelInstanceDetails( 
      tModelInstanceInfo(
        description('some tModel')
      )->tModelKey('UUID:C1ACF26D-9672-4404-9D70-39B756E62AB4')
    )
  ])->bindingKey('');

  ok(ref $a eq 'UDDI::Data');
  ok($a->accessPoint eq 'someurl');
  ok($a->tModelInstanceDetails->tModelInstanceInfo->description eq 'some tModel');
  ok($a->bindingKey eq '');

  $a = tModelInstanceInfo;
  ok(ref $a eq 'UDDI::Data');

  my @syntaxes = map { UDDI::Serializer->serialize($_) } (

    # syntax 1
    findQualifiers(findQualifier('sortByNameAsc',
                                 'caseSensitiveMatch')), 

    # syntax 2
    findQualifiers([findQualifier('sortByNameAsc'),
                    findQualifier('caseSensitiveMatch')]), 

    # syntax 3
    # WARNING! don't forget to put brakets if you use with 
    # and this is not the last expression in the list
    with(findQualifiers => 
      findQualifier('sortByNameAsc'),
      findQualifier('caseSensitiveMatch'),
    ),

    # syntax 4
    findQualifiers->with( 
      findQualifier('sortByNameAsc'),
      findQualifier('caseSensitiveMatch'),
    ),

    # syntax 5
    with findQualifiers => 
      findQualifier => 'sortByNameAsc',
      findQualifier => 'caseSensitiveMatch',
  );

  # all syntaxes should give the same serialized string
  for (1..4) {
    ok($syntaxes[0] eq $syntaxes[$_]);
  }

  @syntaxes = map { UDDI::Serializer->serialize($_) } (

    # syntax 1
    do {
      my $tmodels = tModelInstanceDetails(
        tModelInstanceInfo(
          description('some tModel')
        )->tModelKey('UUID:C1ACF26D-9672-4404-9D70-39B756E62AB4')
      );
      bindingTemplate([
        accessPoint('someurl'), 
        $tmodels
      ])->bindingKey('');
    },

    # syntax 2
    bindingTemplate([
      accessPoint('someurl'), 
      tModelInstanceDetails( 
        tModelInstanceInfo(
          description('some tModel')
        )->tModelKey('UUID:C1ACF26D-9672-4404-9D70-39B756E62AB4')
      )
    ])->bindingKey(''),

    # syntax 3
    do {
      my $tmodels = tModelInstanceDetails(
        tModelInstanceInfo(
          description('some tModel')
        )->tModelKey('UUID:C1ACF26D-9672-4404-9D70-39B756E62AB4')
      );

      with bindingTemplate => 
        accessPoint('someurl'), 
        $tmodels,
        bindingKey => ''
    },

    # syntax 4
    with bindingTemplate => 
      accessPoint('someurl'), 
      tModelInstanceDetails => 
        tModelInstanceInfo(
          description('some tModel')
        )->tModelKey('UUID:C1ACF26D-9672-4404-9D70-39B756E62AB4'),
      bindingKey(''),
  );

  # all syntaxes should give the same serialized string
  for (1..3) {
    ok($syntaxes[0] eq $syntaxes[$_]);
  }
}

{
# UDDI access
  print "UDDI access test(s)...\n";

  my $proxy = 'http://uddi.microsoft.com/inquire';
  my $uddi = new UDDI::Lite proxy => $proxy;

  my @parameters = (
    findQualifiers(findQualifier('sortByNameAsc',
                                 'caseSensitiveMatch')), 
    name('M'),
  );

  ok(ref $parameters[0] eq 'UDDI::Data');

  $r = $uddi->find_business({maxRows => 1}, @parameters)->result;

  ok(defined $r);
  ok(@{[$r->businessInfos->businessInfo]} == 1); # test for maxRows

  $r = $uddi->find_business(@parameters)->result;

  for ($r->businessInfos->businessInfo) {    
    print $_->name, "\n";    
    if ($_->name eq "Microsoft Corporation") {	
      my $key = $_->businessKey;	
      print "$key\n";	
      ok($key =~ /.{8}-.{4}-.{4}-.{4}-.{12}/);

      my $e = $uddi->get_businessDetail($key)->result->businessEntity;	
      my @services = $e->businessServices->businessService;	
      ok(@services > 1);

      for (@services) {	    
        print "  ", $_->name, "\n";	
      }    
    }
  }
}
