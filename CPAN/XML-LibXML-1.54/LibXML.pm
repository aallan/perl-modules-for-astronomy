# $Id: LibXML.pm,v 1.1 2003/07/17 21:56:18 aa Exp $

package XML::LibXML;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS
            $skipDTD $skipXMLDeclaration $setTagCompression
            $MatchCB $ReadCB $OpenCB $CloseCB );
use Carp;

use XML::LibXML::Common qw(:encoding :libxml);

use XML::LibXML::NodeList;
use IO::Handle; # for FH reads called as methods


$VERSION = "1.54";
require Exporter;
require DynaLoader;

@ISA = qw(DynaLoader Exporter);

#-------------------------------------------------------------------------#
# export information                                                      #
#-------------------------------------------------------------------------#
%EXPORT_TAGS = (
                all => [qw(
                           XML_ELEMENT_NODE
                           XML_ATTRIBUTE_NODE
                           XML_TEXT_NODE
                           XML_CDATA_SECTION_NODE
                           XML_ENTITY_REF_NODE
                           XML_ENTITY_NODE
                           XML_PI_NODE
                           XML_COMMENT_NODE
                           XML_DOCUMENT_NODE
                           XML_DOCUMENT_TYPE_NODE
                           XML_DOCUMENT_FRAG_NODE
                           XML_NOTATION_NODE
                           XML_HTML_DOCUMENT_NODE
                           XML_DTD_NODE
                           XML_ELEMENT_DECL
                           XML_ATTRIBUTE_DECL
                           XML_ENTITY_DECL
                           XML_NAMESPACE_DECL
                           XML_XINCLUDE_END
                           XML_XINCLUDE_START
                           encodeToUTF8
                           decodeFromUTF8
                          )],
                libxml => [qw(
                           XML_ELEMENT_NODE
                           XML_ATTRIBUTE_NODE
                           XML_TEXT_NODE
                           XML_CDATA_SECTION_NODE
                           XML_ENTITY_REF_NODE
                           XML_ENTITY_NODE
                           XML_PI_NODE
                           XML_COMMENT_NODE
                           XML_DOCUMENT_NODE
                           XML_DOCUMENT_TYPE_NODE
                           XML_DOCUMENT_FRAG_NODE
                           XML_NOTATION_NODE
                           XML_HTML_DOCUMENT_NODE
                           XML_DTD_NODE
                           XML_ELEMENT_DECL
                           XML_ATTRIBUTE_DECL
                           XML_ENTITY_DECL
                           XML_NAMESPACE_DECL
                           XML_XINCLUDE_END
                           XML_XINCLUDE_START
                          )],
                encoding => [qw(
                                encodeToUTF8
                                decodeFromUTF8
                               )],
               );

@EXPORT_OK = (
              @{$EXPORT_TAGS{all}},
             );

@EXPORT = (
           @{$EXPORT_TAGS{all}},
          );

#-------------------------------------------------------------------------#
# initialization of the global variables                                  #
#-------------------------------------------------------------------------#
$skipDTD            = 0;
$skipXMLDeclaration = 0;
$setTagCompression  = 0;

$MatchCB = undef;
$ReadCB  = undef;
$OpenCB  = undef;
$CloseCB = undef;

#-------------------------------------------------------------------------#
# bootstrapping                                                           #
#-------------------------------------------------------------------------#
bootstrap XML::LibXML $VERSION;

#-------------------------------------------------------------------------#
# parser constructor                                                      #
#-------------------------------------------------------------------------#
sub new {
    my $class = shift;
    my %options = @_;
    if ( not exists $options{XML_LIBXML_KEEP_BLANKS} ) {
        $options{XML_LIBXML_KEEP_BLANKS} = 1;
    }

    if ( defined $options{catalog} ) {
        $class->load_catalog( $options{catalog} );
        delete $options{catalog};
    }

    my $self = bless \%options, $class;
    if ( defined $options{Handler} ) {
        $self->set_handler( $options{Handler} );
    }

    return $self;
}

#-------------------------------------------------------------------------#
# callback functions                                                      #
#-------------------------------------------------------------------------#
sub match_callback {
    my $self = shift;
    if ( ref $self ) {
        $self->{XML_LIBXML_MATCH_CB} = shift if scalar @_;
        return $self->{XML_LIBXML_MATCH_CB};
    }
    else {
        $MatchCB = shift if scalar @_;
        return $MatchCB;
    }
}

sub read_callback {
    my $self = shift;
    if ( ref $self ) {
        $self->{XML_LIBXML_READ_CB} = shift if scalar @_;
        return $self->{XML_LIBXML_READ_CB};
    }
    else {
        $ReadCB = shift if scalar @_;
        return $ReadCB;
    }
}

sub close_callback {
    my $self = shift;
    if ( ref $self ) {
        $self->{XML_LIBXML_CLOSE_CB} = shift if scalar @_;
        return $self->{XML_LIBXML_CLOSE_CB};
    }
    else {
        $CloseCB = shift if scalar @_;
        return $CloseCB;
    }
}

sub open_callback {
    my $self = shift;
    if ( ref $self ) {
        $self->{XML_LIBXML_OPEN_CB} = shift if scalar @_;
        return $self->{XML_LIBXML_OPEN_CB};
    }
    else {
        $OpenCB = shift if scalar @_;
        return $OpenCB;
    }
}

sub callbacks {
    my $self = shift;
    if ( ref $self ) {
        if (@_) {
            my ($match, $open, $read, $close) = @_;
            @{$self}{qw(XML_LIBXML_MATCH_CB XML_LIBXML_OPEN_CB XML_LIBXML_READ_CB XML_LIBXML_CLOSE_CB)} = ($match, $open, $read, $close);
        }
        else {
            return @{$self}{qw(XML_LIBXML_MATCH_CB XML_LIBXML_OPEN_CB XML_LIBXML_READ_CB XML_LIBXML_CLOSE_CB)};
        }
    }
    else {
        if (@_) {
           ( $MatchCB, $OpenCB, $ReadCB, $CloseCB ) = @_;
        }
        else {
            return ( $MatchCB, $OpenCB, $ReadCB, $CloseCB );
        }
    }
}

#-------------------------------------------------------------------------#
# member variable manipulation                                            #
#-------------------------------------------------------------------------#
sub validation {
    my $self = shift;
    $self->{XML_LIBXML_VALIDATION} = shift if scalar @_;
    return $self->{XML_LIBXML_VALIDATION};
}

sub recover {
    my $self = shift;
    $self->{XML_LIBXML_RECOVER} = shift if scalar @_;
    return $self->{XML_LIBXML_RECOVER};
}

sub expand_entities {
    my $self = shift;
    $self->{XML_LIBXML_EXPAND_ENTITIES} = shift if scalar @_;
    return $self->{XML_LIBXML_EXPAND_ENTITIES};
}

sub keep_blanks {
    my $self = shift;
    $self->{XML_LIBXML_KEEP_BLANKS} = shift if scalar @_;
    return $self->{XML_LIBXML_KEEP_BLANKS};
}

sub pedantic_parser {
    my $self = shift;
    $self->{XML_LIBXML_PEDANTIC} = shift if scalar @_;
    return $self->{XML_LIBXML_PEDANTIC};
}

sub load_ext_dtd {
    my $self = shift;
    $self->{XML_LIBXML_EXT_DTD} = shift if scalar @_;
    return $self->{XML_LIBXML_EXT_DTD};
}

sub complete_attributes {
    my $self = shift;
    $self->{XML_LIBXML_COMPLETE_ATTR} = shift if scalar @_;
    return $self->{XML_LIBXML_COMPLETE_ATTR};
}

sub expand_xinclude  {
    my $self = shift;
    $self->{XML_LIBXML_EXPAND_XINCLUDE} = shift if scalar @_;
    return $self->{XML_LIBXML_EXPAND_XINCLUDE};
}

sub base_uri {
    my $self = shift;
    $self->{XML_LIBXML_BASE_URI} = shift if scalar @_;
    return $self->{XML_LIBXML_BASE_URI};
}

sub gdome_dom {
    my $self = shift;
    $self->{XML_LIBXML_GDOME} = shift if scalar @_;
    return $self->{XML_LIBXML_GDOME};
}


#-------------------------------------------------------------------------#
# set the optional SAX(2) handler                                         #
#-------------------------------------------------------------------------#
sub set_handler {
    my $self = shift;
    if ( defined $_[0] ) {
        $self->{HANDLER} = $_[0];

        $self->{SAX_ELSTACK} = [];
        $self->{SAX} = {State => 0};
    }
    else {
        # undef SAX handling
        $self->{SAX_ELSTACK} = [];
        delete $self->{HANDLER};
        delete $self->{SAX};
    }
}

#-------------------------------------------------------------------------#
# helper functions                                                        #
#-------------------------------------------------------------------------#
sub _auto_expand {
    my ( $self, $result, $uri ) = @_;

    $result->setBaseURI( $uri ) if defined $uri;

    if ( defined $self->{XML_LIBXML_EXPAND_XINCLUDE}
         and  $self->{XML_LIBXML_EXPAND_XINCLUDE} == 1 ) {
        $self->{_State_} = 1;
        eval { $self->processXIncludes($result); };
            my $err = $@;
        $self->{_State_} = 0;
        if ($err) {
            $result = undef;
            croak $err;
        }
    }
    return $result;
}

sub __read {
    read($_[0], $_[1], $_[2]);
}

sub __write {
    if ( ref( $_[0] ) ) {
        $_[0]->write( $_[1], $_[2] );
    }
    else {
        $_[0]->write( $_[1] );
    }
}

#-------------------------------------------------------------------------#
# parsing functions                                                       #
#-------------------------------------------------------------------------#
# all parsing functions handle normal as SAX parsing at the same time.
# note that SAX parsing is handled incomplete! use XML::LibXML::SAX for
# complete parsing sequences
#-------------------------------------------------------------------------#
sub parse_string {
    my $self = shift;
    croak("parse already in progress") if $self->{_State_};

    unless ( defined $_[0] and length $_[0] ) {
        croak("Empty String");
    }

    $self->{_State_} = 1;
    my $result;

    if ( defined $self->{SAX} ) {
        my $string = shift;
        $self->{SAX_ELSTACK} = [];
        eval {
            $self->_parse_sax_string($string);
        };
        my $err = $@;
        $self->{_State_} = 0;
        if ($err) {
            croak $err;
        }
    }
    else {
        eval { $result = $self->_parse_string( @_ ); };

        my $err = $@;
        $self->{_State_} = 0;
        if ($err) {
            croak $err;
        }

        $result = $self->_auto_expand( $result, $self->{XML_LIBXML_BASE_URI} );
    }

    return $result;
}

sub parse_fh {
    my $self = shift;
    croak("parse already in progress") if $self->{_State_};
    $self->{_State_} = 1;
    my $result;
    if ( defined $self->{SAX} ) {
        $self->{SAX_ELSTACK} = [];
        eval { $self->_parse_sax_fh( @_ );  };
        my $err = $@;
        $self->{_State_} = 0;
        if ($err) {
            croak $err;
        }
    }
    else {
        eval { $result = $self->_parse_fh( @_ ); };
        my $err = $@;
        $self->{_State_} = 0;
        if ($err) {
            croak $err;
        }

        $result = $self->_auto_expand( $result,, $self->{XML_LIBXML_BASE_URI} );
    }

    return $result;
}

sub parse_file {
    my $self = shift;
    croak("parse already in progress") if $self->{_State_};
    $self->{_State_} = 1;
    my $result;
    if ( defined $self->{SAX} ) {
        $self->{SAX_ELSTACK} = [];
        eval { $self->_parse_sax_file( @_ );  };
        my $err = $@;
        $self->{_State_} = 0;
        if ($err) {
            croak $err;
        }
    }
    else {
        eval { $result = $self->_parse_file(@_); };
        my $err = $@;
        $self->{_State_} = 0;
        if ($err) {
            croak $err;
        }

        $result = $self->_auto_expand( $result );
    }

    return $result;
}

sub parse_xml_chunk {
    my $self = shift;
    # max 2 parameter:
    # 1: the chunk
    # 2: the encoding of the string
    croak("parse already in progress") if $self->{_State_};    my $result;

    unless ( defined $_[0] and length $_[0] ) {
        croak("Empty String");
    }

    $self->{_State_} = 1;
    if ( defined $self->{SAX} ) {
        eval {
            $self->_parse_sax_xml_chunk( @_ );

            # this is required for XML::GenericChunk.
            # in normal case is_filter is not defined, an thus the parsing
            # will be terminated. in case of a SAX filter the parsing is not
            # finished at that state. therefore we must not reset the parsing
            unless ( $self->{IS_FILTER} ) {
                $result = $self->{HANDLER}->end_document();
            }
        };
    }
    else {
        eval { $result = $self->_parse_xml_chunk( @_ ); };
    }

    my $err = $@;
    $self->{_State_} = 0;
    if ($err) {
        croak $err;
    }

    return $result;
}

sub parse_balanced_chunk {
    my $self = shift;
    return $self->parse_xml_chunk( @_ );
}

# java style
sub processXIncludes {
    my $self = shift;
    my $doc = shift;
    return $self->_processXIncludes($doc || " ");
}

# perl style
sub process_xincludes {
    my $self = shift;
    my $doc = shift;
    return $self->_processXIncludes($doc || " ");
}


#-------------------------------------------------------------------------#
# push parser interface                                                   #
#-------------------------------------------------------------------------#
sub init_push {
    my $self = shift;

    if ( defined $self->{CONTEXT} ) {
        delete $self->{CONTEXT};
    }

    if ( defined $self->{SAX} ) {
        $self->{CONTEXT} = $self->_start_push(1);
    }
    else {
        $self->{CONTEXT} = $self->_start_push(0);
    }
}

sub push {
    my $self = shift;

    if ( not defined $self->{CONTEXT} ) {
        $self->init_push();
    }

    foreach ( @_ ) {
        $self->_push( $self->{CONTEXT}, $_ );
    }
}

# this function should be promoted!
# the reason is because libxml2 uses xmlParseChunk() for this purpose!
sub parse_chunk {
    my $self = shift;
    my $chunk = shift;
    my $terminate = shift;

    if ( not defined $self->{CONTEXT} ) {
        $self->init_push();
    }

    if ( defined $chunk and length $chunk ) {
        $self->_push( $self->{CONTEXT}, $chunk );
    }

    if ( $terminate ) {
        return $self->finish_push();
    }
}


sub finish_push {
    my $self = shift;
    my $restore = shift || 0;
    return undef unless defined $self->{CONTEXT};

    my $retval;

    if ( defined $self->{SAX} ) {
        eval {
            $self->_end_sax_push( $self->{CONTEXT} );
            $retval = $self->{HANDLER}->end_document( {} );
        };
    }
    else {
        eval { $retval = $self->_end_push( $self->{CONTEXT}, $restore ); };
    }

    delete $self->{CONTEXT};

    if ( $@ ) {
        croak( $@ );
    }
    return $retval;
}

1;

#-------------------------------------------------------------------------#
# XML::LibXML::Node Interface                                             #
#-------------------------------------------------------------------------#
package XML::LibXML::Node;

sub isSupported {
    my $self    = shift;
    my $feature = shift;
    return $self->can($feature) ? 1 : 0;
}

sub getChildNodes { my $self = shift; return $self->childNodes(); }

sub childNodes {
    my $self = shift;
    my @children = $self->_childNodes();
    return wantarray ? @children : XML::LibXML::NodeList->new( @children );
}

sub attributes {
    my $self = shift;
    my @attr = $self->_attributes();
    return wantarray ? @attr : XML::LibXML::NamedNodeMap->new( @attr );
}

sub iterator {
    warn "this function is obsolete!\nIt was disabled in version 1.54\n";
    return undef;
}


sub findnodes {
    my ($node, $xpath) = @_;
    my @nodes = $node->_findnodes($xpath);
    if (wantarray) {
        return @nodes;
    }
    else {
        return XML::LibXML::NodeList->new(@nodes);
    }
}

sub findvalue {
    my ($node, $xpath) = @_;
    my $res;
    eval {
        $res = $node->find($xpath);
    };
    if  ( $@ ) {
        die $@;
    }
    return $res->to_literal->value;
}

sub find {
    my ($node, $xpath) = @_;
    my ($type, @params) = $node->_find($xpath);
    if ($type) {
        return $type->new(@params);
    }
    return undef;
}

sub setOwnerDocument {
    my ( $self, $doc ) = @_;
    $doc->adoptNode( $self );
}

1;

#-------------------------------------------------------------------------#
# XML::LibXML::Document Interface                                         #
#-------------------------------------------------------------------------#
package XML::LibXML::Document;

use vars qw(@ISA);
@ISA = 'XML::LibXML::Node';

sub setDocumentElement {
    my $doc = shift;
    my $element = shift;

    my $oldelem = $doc->documentElement;
    if ( defined $oldelem ) {
        $doc->removeChild($oldelem);
    }

    $doc->_setDocumentElement($element);
}

sub toString {
    my $self = shift;
    my $flag = shift;

    my $retval = "";

    if ( defined $XML::LibXML::skipXMLDeclaration
         and $XML::LibXML::skipXMLDeclaration == 1 ) {
        foreach ( $self->childNodes ){
            next if $_->nodeType == XML::LibXML::XML_DTD_NODE()
                    and $XML::LibXML::skipDTD;
            $retval .= $_->toString;
        }
    }
    else {
        $retval =  $self->_toString($flag||0);
    }

    return $retval;
}

#-------------------------------------------------------------------------#
# bad style xinclude processing                                           #
#-------------------------------------------------------------------------#
sub process_xinclude {
    my $self = shift;
    XML::LibXML->new->processXIncludes( $self );
}

sub insertProcessingInstruction {
    my $self   = shift;
    my $target = shift;
    my $data   = shift;

    my $pi     = $self->createPI( $target, $data );
    my $root   = $self->documentElement;

    if ( defined $root ) {
        # this is actually not correct, but i guess it's what the user
        # intends
        $self->insertBefore( $pi, $root );
    }
    else {
        # if no documentElement was found we just append the PI
        $self->appendChild( $pi );
    }
}

sub insertPI {
    my $self = shift;
    $self->insertProcessingInstruction( @_ );
}

#-------------------------------------------------------------------------#
# DOM L3 Document functions.
# added after robins implicit feature requst
#-------------------------------------------------------------------------#
sub getElementsByTagName {
    my ( $doc , $name ) = @_;
    my $xpath = "descendant-or-self::node()/$name";
    my @nodes = $doc->_findnodes($xpath);
    return wantarray ? @nodes : XML::LibXML::NodeList->new(@nodes);
}

sub  getElementsByTagNameNS {
    my ( $doc, $nsURI, $name ) = @_;
    my $xpath = "descendant-or-self::*[local-name()='$name' and namespace-uri()='$nsURI']";
    my @nodes = $doc->_findnodes($xpath);
    return wantarray ? @nodes : XML::LibXML::NodeList->new(@nodes);
}

sub getElementsByLocalName {
    my ( $doc,$name ) = @_;
    my $xpath = "descendant-or-self::*[local-name()='$name']";
    my @nodes = $doc->_findnodes($xpath);
    return wantarray ? @nodes : XML::LibXML::NodeList->new(@nodes);
}

1;

#-------------------------------------------------------------------------#
# XML::LibXML::DocumentFragment Interface                                 #
#-------------------------------------------------------------------------#
package XML::LibXML::DocumentFragment;

use vars qw(@ISA);
@ISA = ('XML::LibXML::Node');

sub toString {
    my $self = shift;
    my $retval = "";
    if ( $self->hasChildNodes() ) {
        foreach my $n ( $self->childNodes() ) {
            $retval .= $n->toString(@_);
        }
    }
    return $retval;
}

1;

#-------------------------------------------------------------------------#
# XML::LibXML::Element Interface                                          #
#-------------------------------------------------------------------------#
package XML::LibXML::Element;

use vars qw(@ISA);
@ISA = ('XML::LibXML::Node');

sub setNamespace {
    my $self = shift;
    my $n = $self->nodeName;
    if ( $self->_setNamespace(@_) ){
        if ( scalar @_ < 3 || $_[2] == 1 ){
            $self->setNodeName( $n );
        }
        return 1;
    }
    return 0;
}

sub setAttribute {
    my ( $self, $name, $value ) = @_;
    if ( $name =~ /^xmlns/ ) {
        # user wants to set a namespace ...

        (my $lname = $name )=~s/^xmlns://;
        my $nn = $self->nodeName;
        if ( $nn =~ /^$lname\:/ ) {
            $self->setNamespace($value, $lname);
        }
        else {
            # use a ($active = 0) namespace
            $self->setNamespace($value, $lname, 0);
        }
    }
    else {
        $self->_setAttribute($name, $value);
    }
}

sub getElementsByTagName {
    my ( $node , $name ) = @_;
    my $xpath = "descendant::$name";
    my @nodes = $node->_findnodes($xpath);
    return wantarray ? @nodes : XML::LibXML::NodeList->new(@nodes);
}

sub  getElementsByTagNameNS {
    my ( $node, $nsURI, $name ) = @_;
    my $xpath = "descendant::*[local-name()='$name' and namespace-uri()='$nsURI']";
    my @nodes = $node->_findnodes($xpath);
    return wantarray ? @nodes : XML::LibXML::NodeList->new(@nodes);
}

sub getElementsByLocalName {
    my ( $node,$name ) = @_;
    my $xpath = "descendant::*[local-name()='$name']";
        my @nodes = $node->_findnodes($xpath);
    return wantarray ? @nodes : XML::LibXML::NodeList->new(@nodes);
}

sub getChildrenByTagName {
    my ( $node, $name ) = @_;
    my @nodes = grep { $_->nodeName eq $name } $node->childNodes();
    return wantarray ? @nodes : XML::LibXML::NodeList->new(@nodes);
}

sub getChildrenByTagNameNS {
    my ( $node, $nsURI, $name ) = @_;
    my $xpath = "*[local-name()='$name' and namespace-uri()='$nsURI']";
    my @nodes = $node->_findnodes($xpath);
    return wantarray ? @nodes : XML::LibXML::NodeList->new(@nodes);
}

sub appendWellBalancedChunk {
    my ( $self, $chunk ) = @_;

    my $local_parser = XML::LibXML->new();
    my $frag = $local_parser->parse_xml_chunk( $chunk );

    $self->appendChild( $frag );
}

1;

#-------------------------------------------------------------------------#
# XML::LibXML::Text Interface                                             #
#-------------------------------------------------------------------------#
package XML::LibXML::Text;

use vars qw(@ISA);
@ISA = ('XML::LibXML::Node');

sub attributes { return undef; }

sub deleteDataString {
    my $node = shift;
    my $string = shift;
    my $all    = shift;
    my $data = $node->nodeValue();
    $string =~ s/([\\\*\+\^\{\}\&\?\[\]\(\)\$\%\@])/\\$1/g;
    if ( $all ) {
        $data =~ s/$string//g;
    }
    else {
        $data =~ s/$string//;
    }
    $node->setData( $data );
}

sub replaceDataString {
    my ( $node, $left, $right,$all ) = @_;

    #ashure we exchange the strings and not expressions!
    $left  =~ s/([\\\*\+\^\{\}\&\?\[\]\(\)\$\%\@])/\\$1/g;
    my $datastr = $node->nodeValue();
    if ( $all ) {
        $datastr =~ s/$left/$right/g;
    }
    else{
        $datastr =~ s/$left/$right/;
    }
    $node->setData( $datastr );
}

sub replaceDataRegEx {
    my ( $node, $leftre, $rightre, $flags ) = @_;
    return unless defined $leftre;
    $rightre ||= "";

    my $datastr = $node->nodeValue();
    my $restr   = "s/" . $leftre . "/" . $rightre . "/";
    $restr .= $flags if defined $flags;

    eval '$datastr =~ '. $restr;

    $node->setData( $datastr );
}

1;

package XML::LibXML::Comment;

use vars qw(@ISA);
@ISA = ('XML::LibXML::Text');

1;

package XML::LibXML::CDATASection;

use vars qw(@ISA);
@ISA     = ('XML::LibXML::Text');

1;

#-------------------------------------------------------------------------#
# XML::LibXML::Attribute Interface                                        #
#-------------------------------------------------------------------------#
package XML::LibXML::Attr;
use vars qw( @ISA ) ;
@ISA = ('XML::LibXML::Node') ;

sub setNamespace {
    my ($self,$href,$prefix) = @_;
    my $n = $self->nodeName;
    if ( $self->_setNamespace($href,$prefix) ) {
        $self->setNodeName($n);
        return 1;
    }

    return 0;
}

1;

#-------------------------------------------------------------------------#
# XML::LibXML::Dtd Interface                                              #
#-------------------------------------------------------------------------#
# this is still under construction
#
package XML::LibXML::Dtd;
use vars qw( @ISA );
@ISA = ('XML::LibXML::Node');

1;

#-------------------------------------------------------------------------#
# XML::LibXML::PI Interface                                               #
#-------------------------------------------------------------------------#
package XML::LibXML::PI;
use vars qw( @ISA );
@ISA = ('XML::LibXML::Node');

sub setData {
    my $pi = shift;

    my $string = "";
    if ( scalar @_ == 1 ) {
        $string = shift;
    }
    else {
        my %h = @_;
        $string = join " ", map {$_.'="'.$h{$_}.'"'} keys %h;
    }

    # the spec says any char but "?>" [17]
    $pi->_setData( $string ) unless  $string =~ /\?>/;
}

1;

#-------------------------------------------------------------------------#
# XML::LibXML::Namespace Interface                                        #
#-------------------------------------------------------------------------#
package XML::LibXML::Namespace;

# this is infact not a node!
sub prefix { return "xmlns"; }

sub getNamespaces { return (); }

sub nodeName {
    my $self = shift;
    my $nsP  = $self->name;
    return length($nsP) ? "xmlns:$nsP" : "xmlns";
}

sub getNodeName { my $self = shift; return $self->nodeName; }

sub isEqualNode {
    my ( $self, $ref ) = @_;
    if ( ref($ref) eq "XML::LibXML::Namespace" ) {
        return $self->_isEqual($ref);
    }
    return 0;
}

sub isSameNode {
    my ( $self, $ref ) = @_;
    if ( $$self == $$ref ){
        return 1;
    }
    return 0;
}

1;

#-------------------------------------------------------------------------#
# XML::LibXML::NamedNodeMap Interface                                     #
#-------------------------------------------------------------------------#
package XML::LibXML::NamedNodeMap;

use XML::LibXML::Common qw(:libxml);

sub new {
    my $class = shift;
    my $self = bless { Nodes => [@_] }, $class;
    $self->{NodeMap} = { map { $_->nodeName => $_ } @_ };
    return $self;
}

sub length     { return scalar( @{$_[0]->{Nodes}} ); }
sub nodes      { return $_[0]->{Nodes}; }
sub item       { $_[0]->{Nodes}->[$_[1]]; }

sub getNamedItem {
    my $self = shift;
    my $name = shift;

    return $self->{NodeMap}->{$name};
}

sub setNamedItem {
    my $self = shift;
    my $node = shift;

    my $retval;
    if ( defined $node ) {
        if ( scalar @{$self->{Nodes}} ) {
            my $name = $node->nodeName();
            if ( $node->nodeType() == XML_NAMESPACE_DECL ) {
                return;
            }
            if ( defined $self->{NodeMap}->{$name} ) {
                if ( $node->isSameNode( $self->{NodeMap}->{$name} ) ) {
                    return;
                }
                $retval = $self->{NodeMap}->{$name}->replaceNode( $node );
            }
            else {
                $self->{Nodes}->[0]->addSibling($node);
            }

            $self->{NodeMap}->{$name} = $node;
            push @{$self->{Nodes}}, $node;
        }
        else {
            # not done yet
            # can this be properly be done???
            warn "not done yet\n";
        }
    }
    return $retval;
}

sub removeNamedItem {
    my $self = shift;
    my $name = shift;
    my $retval;
    if ( $name =~ /^xmlns/ ) {
        warn "not done yet\n";
    }
    elsif ( exists $self->{NodeMap}->{$name} ) {
        $retval = $self->{NodeMap}->{$name};
        $retval->unbindNode;
        delete $self->{NodeMap}->{$name};
        $self->{Nodes} = [grep {not($retval->isSameNode($_))} @{$self->{Nodes}}];
    }

    return $retval;
}

sub getNamedItemNS {
    my $self = shift;
    my $nsURI = shift;
    my $name = shift;
    return undef;
}

sub setNamedItemNS {
    my $self = shift;
    my $nsURI = shift;
    my $node = shift;
    return undef;
}

sub removeNamedItemNS {
    my $self = shift;
    my $nsURI = shift;
    my $name = shift;
    return undef;
}

1;

package XML::LibXML::_SAXParser;

# this is pseudo class!!! and it will be removed as soon all functions
# moved to XS level

use XML::SAX::Exception;

# these functions will use SAX exceptions as soon i know how things really work
sub warning {
    my ( $parser, $message, $line, $col ) = @_;
    my $error = XML::SAX::Exception::Parse->new( LineNumber   => $line,
                                                 ColumnNumber => $col,
                                                 Message      => $message, );
    $parser->{HANDLER}->warning( $error );
}

sub error {
    my ( $parser, $message, $line, $col ) = @_;

    my $error = XML::SAX::Exception::Parse->new( LineNumber   => $line,
                                                 ColumnNumber => $col,
                                                 Message      => $message, );
    $parser->{HANDLER}->error( $error );
}

sub fatal_error {
    my ( $parser, $message, $line, $col ) = @_;
    my $error = XML::SAX::Exception::Parse->new( LineNumber   => $line,
                                                 ColumnNumber => $col,
                                                 Message      => $message, );
    $parser->{HANDLER}->fatal_error( $error );
}

1;

#-------------------------------------------------------------------------#
# XML::LibXML Parser documentation                                        #
#-------------------------------------------------------------------------#
__END__

=head1 NAME

XML::LibXML - Interface to the gnome libxml2 library

=head1 SYNOPSIS

  use XML::LibXML;
  my $parser = XML::LibXML->new();

  my $doc = $parser->parse_string(<<'EOT');
  <some-xml/>
  EOT

=head1 DESCRIPTION

This module is an interface to the gnome libxml2 DOM parser (no SAX
parser support yet), and the DOM tree. It also provides an
XML::XPath-like findnodes() interface, providing access to the XPath
API in libxml2.

=head1 OPTIONS

LibXML options are global (unfortunately this is a limitation of the
underlying implementation, not this interface). They can either be set
using C<$parser-E<gt>option(...)>, or C<XML::LibXML-E<gt>option(...)>, both
are treated in the same manner. Note that even two forked processes
will share some of the same options, so be careful out there!

Every option returns the previous value, and can be called without
parameters to get the current value.

=head2 validation

  $parser->validation(1);

Turn validation on (or off). Defaults to off.

=head2 recover

  $parser->recover(1);

Turn the parsers recover mode on (or off). Defaults to off.

This allows to parse broken XML data into memory.  This switch will
only work with XML data rather than HTML data. Also the validation
will be switched off automaticly.

The recover mode helps to recover documents that are almost wellformed
very efficiently. That is for example a document that forgets to close
the document tag (or any other tag inside the document). The recover
mode of XML::LibXML has problems though to restore documents that are
more like well ballanced chunks. In that case XML::LibXML will only
parse the first tag of the chunk.

=head2 expand_entities

  $parser->expand_entities(0);

Turn entity expansion on or off, enabled by default. If entity expansion
is off, any external parsed entities in the document are left as entities.
Probably not very useful for most purposes.

=head2 keep_blanks

 $parser->keep_blanks(0);

Allows you to turn off XML::LibXML's default behaviour of maintaining
whitespace in the document.

=head2 pedantic_parser

  $parser->pedantic_parser(1);

You can make XML::LibXML more pedantic if you want to.

=head2 load_ext_dtd

  $parser->load_ext_dtd(1);

Load external DTD subsets while parsing.

=head2 complete_attributes

  $parser->complete_attributes(1);

Complete the elements attributes lists with the ones defaulted from the DTDs.
By default, this option is enabled.

=head2 expand_xinclude

  $parser->expand_xinclude

Expands XIinclude tags imidiatly while parsing the document. This flag
ashures that the parser callbacks are used while parsing the included
Document.

=head2 load_catalog

  $parser->load_catalog( $catalog_file );

Will use $catalog_file as a catalog during all parsing
processes. Using a catalog will significantly speed up parsing
processes if many external ressources are loaded into the parsed
documents (such as DTDs or XIncludes)

Note that catalogs will not be available if an external entity handler
was specified. At the current state it is not possible to make use of
both types of resolving systems at the same time.

=head2 base_uri

  $parser->base_uri( $your_base_uri );

In case of parsing strings or file handles, XML::LibXML doesn't know
about the base uri of the document. To make relative references such as
XIncludes work, one has to set a separate base URI, that is then used for
the parsed documents.

=head2 gdome_dom

  $parser->gdome_dom(1);

Although quite powerful XML:LibXML's DOM implementation is limited if
one needs or wants full DOM level 2 or level 3 support. XML::GDOME is
based on libxml2 as well but provides a rather complete DOM
implementation by wrapping libgdome. This allows you to make use of
XML::LibXML's full parser options and XML::GDOME's DOM implementation
at the same time.

All XML::LibXML parser functions recognize this switch.

=head2 match_callback

  $parser->match_callback($subref);

Sets a "match" callback. See L<"Input Callbacks"> below.

=head2 open_callback

  $parser->open_callback($subref);

Sets an open callback. See L<"Input Callbacks"> below.

=head2 read_callback

  $parser->read_callback($subref);

Sets a read callback. See L<"Input Callbacks"> below.

=head2 close_callback

  $parser->close_callback($subref);

Sets a close callback. See L<"Input Callbacks"> below.

=head1 CONSTRUCTOR

The XML::LibXML constructor, C<new()>, takes the following parameters:

=head2 ext_ent_handler

  my $parser = XML::LibXML->new(ext_ent_handler => sub { ... });

The ext_ent_handler sub is called whenever libxml needs to load an external
parsed entity. The handler sub will be passed two parameters: a
URL (SYSTEM identifier) and an ID (PUBLIC identifier). It should return
a string containing the resource at the given URI.

Note that you do not need to enable this - if not supplied libxml will
get the resource either directly from the filesystem, or using an internal
http client library.

=head2 catalog

  my $parser = XML::LibXML->new( catalog => $private_catalog );

Alternatively to ext_ent_handler the catalog parameter allows to use
libxml2's catalog interface directly. The parameter takes a filename
to a catalog file. This catalog is loaded by libxml2 and will be used
during parsing processes.

Note that catalogs will not be available if an external entity handler
was specified. At the current state it is not possible to make use of
both types of resolving systems at the same time.

=head1 DEFAULT VALUES

The following table gives an overview about the default values of the
parser attributes.

=over 4

=item validation == off (0)

=item recover == off (0)

=item expand_entities == on (1)

=item keep_blanks == on (1)

=item pedantic_parser == off (0)

=item load_ext_dtd == on (1)

=item complete_attributes == on (1)

=item expand_xinclude == off (0)

=item base_uri == ""

=item gdome_dom == off (0)

=back

By default no callback handler is set.

=head1 PARSING

There are three ways to parse documents - as a string, as a Perl
filehandle, or as a filename. The return value from each is a
XML::LibXML::Document object, which is a DOM object (although not all
DOM methods are implemented yet). See L<"XML::LibXML::Document"> below
for more details on the methods available on documents.

Each of the below methods will throw an exception if the document is invalid.
To prevent this causing your program exiting, wrap the call in an eval{}
block.

=head2 parse_string

  my $doc = $parser->parse_string($string);

or, passing in a directory to use as the "base":

  my $doc = $parser->parse_string($string, $dir);

=head2 parse_fh

  my $doc = $parser->parse_fh($fh);

Here, C<$fh> can be an IOREF, or a subclass of IO::Handle.

And again, you can pass in a directory as the "base":

  my $doc = $parser->parse_fh($fh, $dir);

Note in the above two cases, $dir must end in a trailing slash,
otherwise the parent of that directory is used. This can actually
be useful, in that it will accept the filename of what you're
parsing.

=head2 parse_file

  my $doc = $parser->parse_file($filename);

This function reads an absolute filename into the memory. It causes
XML::LibXML to use libxml2's file parser instead of letting perl
reading the file such as with parse_fh(). If you need to parse files
directly, this function would be the faster choice, since this function
is about 6-8 times faster then parse_fh().

=head2 Parsing Html

As of version 0.96, XML::LibXML is capable of parsing HTML into a
regular XML DOM. This gives you the full power of XML::LibXML on HTML
documents.

The methods work in exactly the same way as the methods above, and
return exactly the same type of object. If you wish to dump the
resulting document as HTML again, you can use C<$doc->toStringHTML()>
to do that.

=head2 parse_html_string

  my $doc = $parser->parse_html_string($string);

=head2 parse_html_fh

  my $doc = $parser->parse_html_fh($fh);

=head2 parse_html_file

  my $doc = $parser->parse_html_file($filename);

=head2 The Push Parser

XML::LibXML provides a push parser interface. This allows one to parse
large documents without actually loading the entire document into
memory. While parse_file() and parse_fh() won't load the document
before parsing either. While parse_file() forces the data to be a
wellformed XML file, parse_fh() may be used to parse data comming from
any kind of source that delivers wellformed XML
documents. parse_fh()'s parsing ability is limited to single
documents. For a programmer there is no chance to interrupt the
parsing process if for example multiple XML documents are recieved
through the same channel. XML::LibXML's push parser works around this
limitation and provides an interface to libxml2's pushparser. This
parser will parse the data the application provides to it at the time
they are pushed into the parser, rather than pulling the data itself.

Through this it is possible to preprocess incoming data if required -
i.e. in the given example to find the document boundaries. Different
to the pull parser implemented in parse_fh() or parse_file(), the push
parser is not able to find out about the documents end itself. Thus
the calling program needs to indicate explicitly when the parsing is
done.

In XML::LibXML this is done by a single function:

  parse_chunk()

parse_chunk() tries to parse a given chunk of data, which isn't
nessecarily well balanced data. The function takes two parameters:

=over 4

=item 1. the chunk of data as a single string

=item 2. (optional) a termination flag

=back

If the termination flag is set to a true value (e.g. 1), the parsing
will be stopped and the resulting document will be returned.

the following example may clearify this a bit:

  my $parser = XML::LibXML->new;

  for my $string ( "<", "foo", ' bar="hello worls"', "/>") {
       $parser->parse_chunk( $string );
  }
  my $doc = $parser->parse_chunk("", 1); # terminate the parsing

Internally the push parser uses two functions, push() and finish_push().
they are not very usefull expect one likes to write a repairing parser.
How to do this is described in the following part.

Of course XML::LibXML's push parser is available as a SAX parser as
well. To make use of the SAX capabilities one must any the SAX as the
parsers SAX handler; otherwise parse_chunk() will work in the default
mode.

=over 4

=item $parser->push( @data )

This function pushs the data stored inside the array to libxml2's
parse. Each entry in @data must be a normal scalar!

=item $parser->finish_push( $restore );

This function returns the result of the parsing process. If this
function is called without a parameter it will complain about non
wellformed documents. If $restore is 1, the push parser can be used to
restore broken or non well formed (XML) documents as the following
example shows:

  eval {
      $parser->push( "<foo>", "bar" );
      $doc = $parser->finish_push();    # will report broken XML
  };
  if ( $@ ) {
     # ...
  }

This can be anoing if the closing tag misses by accident. The
following code will restore the document:

  eval {
      $parser->push( "<foo>", "bar" );
      $doc = $parser->finish_push(1);   # will return the data parsed
                                        # until an error happend
  };
  warn $doc->toString(); # returns "<foo>bar</foo>"

of course finish_push() will return nothing if there was no data pushed to
the parser before.

=back

=head2 Extra parsing methods

B<processXIncludes>

  $parser->processXIncludes( $doc );

While the document class implements a separate XInclude processing,
this method, is stricly related to the parser. The use of this method
is only required, if the parser implements special callbacks that
should to be used for the XInclude as well.

If expand_xincludes is set to 1, the method is only required to process
XIncludes appended to the DOM after its original parsing.

=head2 Error Handling

XML::LibXML throws exceptions during parseing, validation or XPath
processing. These errors can be catched by useing eval blocks. The
error then will be stored in B<$@>. Alternatively one can use the
get_last_error() function of XML::LibXML. It will return the same
string that is stored in $@. Using get_last_error() makes it still
nessecary to eval the statement, since these function groups will
die() on errors.

get_last_error() can be called either by the class itself or by a
parser instance:

   $errstring = XML::LibXML->get_last_error();
   $errstring = $parser->get_last_error();

Note that XML::LibXML exceptions are global. That means if
get_last_error is called on an parser instance, the last B<global>
error will be returned. This is not nessecarily the error caused by
the parser instance itself.

=head2 Serialization

The oposite of parsing is serialization. In XML::LibXML this can be
done by using the functions toString(), toFile() and toFH(). All
serialization functions understand the flag setTagCompression. if this
Flag is set to 1 empty tags are displayed as <foo></foo>
rather than <foo/>.

toString() additionally checks two other flags:

skipDTD and skipXMLDeclaration

If skipDTD is specified and any DTD node is found in the document this
will not be serialized.

If skipXMLDeclaration is set to 1 the documents xml declaration is not
serialized. This flag will cause the document to be serialized as UTF8
even if the document has an other encoding specified.

XML::LibXML does not define these flags itself, therefore they have to
specify them manually by the caller:

 local $XML::LibXML::skipXMLDeclaration = 1;
 local $XML::LibXML::skipDTD = 1;
 local $XML::LibXML::setTagCompression = 1;

will cause the serializer to avoid the XML declaration for a document,
skip the DTD if found, and expand empty tags.

*NOTE* $XML::LibXML::skipXMLDeclaration and $XML::LibXML::skipDTD are
only recognized by the Documents toString() function.

Additionally it is possible to serialize single nodes by using
toString() for the node. Since a node has no DTD and no XML
Declaration the related flags will take no effect. Nevertheless
setTagCompression is supported.

All basic serialization function recognize an additional formating
flag. This flag is an easy way to format complex xml documents without
adding ignoreable whitespaces.

=head2 Input Callbacks

The input callbacks are used whenever LibXML has to get something B<other
than external parsed entities> from somewhere. The input callbacks in LibXML
are stacked on top of the original input callbacks within the libxml library.
This means that if you decide not to use your own callbacks (see C<match()>),
then you can revert to the default way of handling input. This allows, for
example, to only handle certain URI schemes.

Callbacks are only used on files, but not on strings or filehandles. This is
because LibXML requires the match event to find out about which callback set
is shall be used for the current input stream. LibXML can decide this only
before the stream is open. For LibXML strings and filehandles are already
opened streams.

The following callbacks are defined:

=over 4

=item match(uri)

If you want to handle the URI, simply return a true value from this callback.

=item open(uri)

Open something and return it to handle that resource.

=item read(handle, bytes)

Read a certain number of bytes from the resource. This callback is
called even if the entire Document has already read.

=item close(handle)

Close the handle associated with the resource.

=back

=head2 Example

This is a purely fictitious example that uses a MyScheme::Handler object
that responds to methods similar to an IO::Handle.

  $parser->match_callback(\&match_uri);
  
  $parser->open_callback(\&open_uri);
  
  $parser->read_callback(\&read_uri);
  
  $parser->close_callback(\&close_uri);
  
  sub match_uri {
    my $uri = shift;
    return $uri =~ /^myscheme:/;
  }
  
  sub open_uri {
    my $uri = shift;
    return MyScheme::Handler->new($uri);
  }
  
  sub read_uri {
    my $handler = shift;
    my $length = shift;
    my $buffer;
    read($handler, $buffer, $length);
    return $buffer;
  }
  
  sub close_uri {
    my $handler = shift;
    close($handler);
  }

A more realistic example can be found in the L<"example"> directory

Since the parser requires all callbacks defined it is also possible to
set all callbacks with a single call of callbacks(). This would
simplify the example code to:

  $parser->callbacks( \&match_uri, \&open_uri, \&read_uri, \&close_uri);

All functions that are used to set the callbacks, can also be used to
retrieve the callbacks from the parser.

=head2 Global Callbacks

Optionaly it is possible to apply global callback on the XML::LibXML
class level. This allows multiple parses to share the same callbacks.
To set these global callbacks one can use the callback access
functions directly on the class.

  XML::LibXML->callbacks( \&match_uri, \&open_uri, \&read_uri, \&close_uri);

The previous code snippet will set the callbacks from the first
example as global callbacks.

=head2 Encoding

All data will be stored UTF-8 encoded. Nevertheless the input and
output functions are aware about the encoding of the owner
document. By default all functions will assume, UTF-8 encoding of the
passed strings unless the owner document has a different encoding. In
such a case the functions will assume the encoding of the document to
be valid.

At the current state of implementation query functions like
B<findnodes()>, B<getElementsByTagName()> or B<getAttribute()> accept
B<only> UTF-8 encoded strings, even if the underlaying document has a
different encoding. At first this seems to be a limitation, but on
application level there is no way to make save asumptations about the
encoding of the strings.

Future releases will offer the opportunity to force an application
wide encoding, so make shure that you installed the latest version of
XML::LibXML.

To encode or decode a string to or from UTF-8 B<XML::LibXML> exports
two functions, which use the encoding mechanism of the underlaying
implementation. These functions should be used, if external encoding
is required (e.g. for queryfunctions).

=head2 encodeToUTF8

    $encodedstring = encodeToUTF8( $name_of_encoding, $sting_to_encode );

The function will encode a string from the specified encoding to UTF-8.

=head2 decodeFromUTF8

    $decodedstring = decodeFromUTF8($name_of_encoding, $string_to_decode );

This Function transforms an UTF-8 encoded string the specified
encoding.  While transforms to ISO encodings may cause errors if the
given stirng contains unsupported characters, this function can
transform to UTF-16 encodings as well.


=head1 XML::LibXML::Dtd

This module allows you to parse and return a DTD object. It has one method
right now, C<new()>.

=head2 new()

  my $dtd = XML::LibXML::Dtd->new($public, $system);

Creates a new DTD object from the public and system identifiers. It will
automatically load the objects from the filesystem, or use the input
callbacks (see L<"Input Callbacks"> below) to load the DTD.

=head1 Processing Instructions - XML::LibXML::PI

Processing instructions are implemented with XML::LibXML with read and
write access ;) The PI data is the PI without the PI target (as
specified in XML 1.0 [17]) as a string. This string can be accessed with
L<getData> as implemented in XML::LibXML::Node.

The write access is aware about the fact, that many processing
instructions have attribute like data. Therefor L<setData> provides
besides the DOM spec conform Interface to pass a set of named
parameter. So the code segment

    my $pi = $dom->createProcessingInstruction("abc");
    $pi->setData(foo=>'bar', foobar=>'foobar');
    $dom->appendChild( $pi );

will result the following PI in the DOM:

    <?abc foo="bar" foobar="foobar"?>

The same can be done with

   $pi->setData( 'foo="bar" foobar="foobar"' );

Which is how it is specified in the L<DOM specification>. This three
step interface creates temporary a node in perl space. This can be
avoided while using the B<insertProcessingInstruction> method.
Instead of the three calls described above, the call
C<$dom->insertProcessingInstruction("abc",'foo="bar" foobar="foobar"');>
will have the same result as above.

Currently only the B<setData()> function accepts named parameters,
while only strings are accepted by the other methods.

=head2 createProcessingInstruction

B<SYNOPSIS:>

   $pinode = $dom->createProcessingInstruction( $target );

or

   $pinode = $dom->createProcessingInstruction( $target, $data );

This function creates a new PI and returns this node. The PI is bound
to the DOM, but is not appended to the DOM itself. To add the PI to
the DOM, one needs to use B<appendChild()> directly on the dom itself.

=head2 insertProcessingInstruction

B<SYNOPSIS:>

  $dom->insertProcessingInstruction( $target, $data );

Creates a processing instruction and inserts it directly to the
DOM. The function does not return a node.

=head2 createPI

alias for createProcessingInstruction

=head2 insertPI

alias for insertProcessingInstruction

=head2 setData

B<SYNOPSIS:>

   $pinode->setData( $data_string );

or

   $pinode->setData( name=>string_value [...] );

This method allows to change the content data of a PI. Additionaly to
the interface specified for DOM Level2, the method provides a named
parameter interface to set the data. This parameterlist is converted
into a string before it is appended to the PI.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org
Christian Glahn, christian.glahn@uibk.ac.at

=head1 COPYRIGHT

Copyright 2001-2002, AxKit.com Ltd. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

L<XML::LibXSLT>, L<XML::LibXML::DOM>, L<XML::LibXML::SAX>

=cut
