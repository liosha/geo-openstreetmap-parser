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

=cut

sub new
{
    my ($class, %callback) = @_;
    
    my $self = bless { callback => \%callback }, $class;
    $self->_init_parser();
    return $self;
}


=method parse

Parses XML input, executing callback functions for every OSM object

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
                        $path[-1]->{$el}->{$obj->{attr}->{k}} = $obj->{attr}->{v}   when 'tag';
                        push @{$path[-1]->{$el}}, $obj->{attr}->{ref}               when 'nd';
                        push @{$path[-1]->{$el}}, $obj->{attr}                      when 'member';
                        $self->{callback}->{$el}->($obj)                            when $self->{callback};
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
