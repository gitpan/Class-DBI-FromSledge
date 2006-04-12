package Class::DBI::FromSledge;
use strict;
use warnings;
use base qw/Class::DBI::Plugin/;
our $VERSION = '0.02';
use Carp;

sub create_from_sledge : Plugged {
    my ($class, $page, $args) = @_;
    croak "create_from_sledge can only be called as a class method" if ref $class;
    croak "error detected at validator" if $page->valid->is_error;

    my $cols = $args || {};
    for my $col ($class->columns) {
        unless ($cols->{$col}) {
            if ($page->valid->check($col)) {
                $cols->{$col} = &_get_val($page, $col);
            } elsif ($page->valid->check("$col\_year")) {
                $cols->{$col} =  sprintf '%d-%02d-%02d', map {$page->r->param("$col\_$_")} qw(year month day);
            }
        }
    }

    return $class->create($cols);
}

sub update_from_sledge : Plugged {
    my ($self, $page) = @_;
    croak "update_from_sledge cannot be called as a class method" unless ref $self;
    croak "error detected at validator" if $page->valid->is_error;

    for my $col ($self->columns('All')) {
        if ($page->valid->{PLAN}->{$col}) {
            $self->set($col => &_get_val($page, $col));
        } elsif ($page->valid->{PLAN}->{"$col\_year"}) {
            $self->set($col => sprintf '%d-%02d-%02d', map {$page->r->param("$col\_$_") || 0} qw(year month day));
        }
    }

    $self->update;
}

sub _get_val {
    my ($page, $col) = @_;

    my @val = $page->r->param($col);
    if (@val==1) {
        return $val[0] ne '' ? $val[0] : undef; # scalar
    } else {
        return join ',', @val; # array
    }
}

1;

__END__

=head1 NAME

Class::DBI::FromSledge - Update Class::DBI data using Sledge

=head1 SYNOPSIS

    package Your::Data::Film;
    use Class::DBI::FromSledge;
    use base 'Class::DBI';
    
    package Your::Pages;
    sub valid_create {
        shift->valid->check( ... );
    }
    sub dispatch_create {
        my $self = shift;
        Your::Data::Film->create_from_sledge($self);
    }

    sub valid_update {
        shift->valid->check( ... );
    }
    sub dispatch_update {
        my $self = shift;
        my $film = Your::Data::Film->retrieve('Fahrenheit 911');
        $film->update_from_sledge($self);
    }

=head1 DESCRIPTION

Create and update L<Class::DBI> objects from L<Sledge::Plugin::Validator>.

=head1 METHODS

=head2 create_from_sledge

Create a new object.

=head2 update_from_sledge

Update object.

=head1 COVERAGE

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    ...b/Class/DBI/FromSledge.pm  100.0  100.0  100.0  100.0  100.0  100.0  100.0
    Total                         100.0  100.0  100.0  100.0  100.0  100.0  100.0
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 AUTHOR

MATSUNO Tokuhiro <tokuhiro at mobilefactory.jp>

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=head1 THANKS TO

Sebastian Riedel, the Class::DBI::FromForm author.

=head1 SEE ALSO

L<Class::DBI>, L<Class::DBI::FromForm>, L<Sledge::Plugin::Validator>, L<Bundle::Sledge>

=cut
