use 5.010;
use strict;
use warnings;

package Geo::Openstreetmap::Parser;

# ABSTRACT: Openstreetmap XML dump parser

use autodie;

use XML::Parser;


=method new

Creates a parser object

    my $parser = Geo::Openstreetmap::Parser->new( node => \&process_node, ... );

    sub process_node {
        my ($obj) = @_;
        ...
    }

Callbacks are possible for any tag, but useful for osm primitives:
    node
    way
    relation

Callback function receives hash with params:
    attr    - hash with xml attributes
    tag     - hash with osm tags
    nd      - array of node_ids (for ways)
    member  - array of hashes like { type => 'way', role => 'from', ref => '-1' } (for relations)

=cut

sub new
{
    my ($class, %callback) = @_;
    
    my $self = bless { callback => \%callback }, $class;
    $self->_init_parser();
    return $self;
}


=method parse

Parses XML input, executing defined callback functions for OSM objects

    $parser->parse( *STDIN );

=cut

sub parse
{
    my ($self, $fh) = @_;
    $self->{parser}->parse($fh);
    return;
}




sub _init_parser
{
    my ($self) = @_;

    my @path;

    $self->{parser} = XML::Parser->new( Handlers => {
            Start => sub {
                    my ($expat, $el, %attr) = @_;
                    push @path, { attr => \%attr };
                },
            End => sub {
                    my ($expat, $el) = @_;
                    my $obj = pop @path;

                    for ( $el ) {
                        when ('tag')    { $path[-1]->{$el}->{$obj->{attr}->{k}} = $obj->{attr}->{v} }
                        when ('nd')     { push @{$path[-1]->{$el}}, $obj->{attr}->{ref} }
                        when ('member') { push @{$path[-1]->{$el}}, $obj->{attr} }
                        when ($self->{callback})    { $self->{callback}->{$el}->($obj) }
                    }
                },
        });
    return;
}


sub _process_object
{
    my ($self, $el, $obj) = @_;

    $self->{$el}->($obj)  if $self->{$el};
    return;
}

1;
