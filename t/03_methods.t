use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    eval "use Class::DBI::Test::SQLite;use Sledge::TestPages";
    plan $@ ? (skip_all => "needs Class::DBI::Test::SQLite, Sledge::TestPages for testing $@") : (tests => 12);
}

{
    package Mock::Data;
    use base 'Class::DBI::Test::SQLite';
    use Class::DBI::FromSledge;

    __PACKAGE__->set_table('test');
    __PACKAGE__->columns(All => qw/id name film salary carrier email/);

    sub create_sql {
        return q{
                id      INTEGER PRIMARY KEY,
                name    CHAR(40),
                film    VARCHAR(255),
                salary  INT,
                email   VARCHAR(255),
                carrier VARCHAR(50)
        }
    }
}

{
    package Mock::Pages;
    use base 'Sledge::TestPages';
    use Sledge::Plugin::Validator;

    sub valid_create {
        my $self = shift;
        $self->valid->check(
            name    => [qw(NOT_NULL)],
            carrier => [qw(NOT_NULL)],
            email   => [qw(EMAIL)],
            salary  => [qw(UINT NOT_NULL)],
        );
        $self->valid->err_template($self->page); # XXX
    }
    sub dispatch_create {
        my $self = shift;
        my $row = Mock::Data->create_from_sledge($self, {salary => 350});
        ::is $row->name, 'tokuhirom', 'set the name';
        ::is $row->film, undef, 'no set film';
        ::is $row->salary, 350, 'set the salary with argument.';
        ::is $row->carrier, 'I,V', 'set the salary with argument.';
        ::is(Mock::Data->retrieve_from_sql(q{id=? AND email IS NULL}, $row->id)->count, 1, 'nulled');# 0, 'nulled';

        my $row2 = Mock::Data->create_from_sledge($self);

        return $self->redirect('/');
    }

    sub valid_update {
        my $self = shift;
        $self->valid->check(film => [qw(NOT_NULL)]);
        $self->valid->err_template($self->page); # XXX
    }
    sub dispatch_update {
        my $self = shift;
        my $row = Mock::Data->retrieve_all->first;
        $row->update_from_sledge($self);
        ::is $row->name, 'tokuhirom', 'unchange the name';
        ::is $row->film, 'aha', 'change the film';
        ::is $row->salary, 350, 'unchange the film';
        return $self->redirect('/');
    }

    sub valid_error_create {
        my $self = shift;
        $self->valid->check(name => [qw(NOT_NULL)]);
        $self->valid->err_template($self->page); # XXX
    }
    sub dispatch_error_create {
        my $self = shift;
        $self->valid->{ERROR}->{foo} = 'bar';
        ::dies_ok {Mock::Data->create_from_sledge($self)} 'error detect at create_from_sledge';

        return $self->redirect('/');
    }


    sub valid_error_update {
        my $self = shift;
        $self->valid->check(film => [qw(NOT_NULL)]);
        $self->valid->err_template($self->page); # XXX
    }
    sub dispatch_error_update {
        my $self = shift;
        $self->valid->{ERROR}->{foo} = 'bar';
        my $row = Mock::Data->retrieve_all->first;
        ::dies_ok {$row->update_from_sledge($self)} 'error detect';
        return $self->redirect('/');
    }
}

my $d = $Mock::Pages::TMPL_PATH;
$Mock::Pages::TMPL_PATH = './t/';

my $c = $Mock::Pages::COOKIE_NAME;
$Mock::Pages::COOKIE_NAME = 'sid';

$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING} = 'name=tokuhirom&film=aha&carrier=I&carrier=V&email=&salary=500';

my $pages2 = Mock::Pages->new;
$pages2->dispatch('create');

my $pages = Mock::Pages->new;
$pages->dispatch('update');

my $pages4 = Mock::Pages->new;
$pages4->dispatch('error_create');

my $pages3 = Mock::Pages->new;
$pages3->dispatch('error_update');

my $row = Mock::Data->retrieve_all->first;
dies_ok {$row->create_from_sledge} 'create_from_sledge is class method';
dies_ok {Mock::Data->update_from_sledge} 'update_from_sledge is instance method';
