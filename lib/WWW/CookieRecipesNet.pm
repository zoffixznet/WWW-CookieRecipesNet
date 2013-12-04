package WWW::CookieRecipesNet;

use warnings;
use strict;

our $VERSION = '0.0101';

use WWW::Mechanize;
use HTML::TokeParser::Simple;
use HTML::Entities;
use overload fallback => 1, q|""| => sub { shift->recipe };

use base 'Class::Data::Accessor';
__PACKAGE__->mk_classaccessors qw/
    recipe
    link_list
    list
    error
    ua
/;

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    $args{ua} ||= WWW::Mechanize->new( timeout => 30, agent => 'Opera 9.5' );

    $self->$_( $args{$_} )
        for keys %args;

    return $self;
}

sub get_list {
    my ( $self, $letter ) = @_;

    defined $letter
        or $letter = '';

    my $ua = $self->ua;

    my $response = $ua->get('http://www.cookie-recipes.net/cookie-index.htm');
    $response->is_success
        or return $self->_set_error($response, 'net');

    my @links = $ua->find_all_links(
        url_regex  => qr{^\Qhttp://www.cookie-recipes.net/cookie-recipes-},
        text_regex => qr/^\Q$letter/i,
    );

    $self->link_list( \@links );
    my @list = map $_->text, @links;
    return $self->list( \@list );
}

sub get_recipe {
    my ( $self, $name ) = @_;

    my $link_list = $self->link_list || [];
    my ( $link ) = grep $_->text eq $name, @$link_list;

    unless ( $link ) {
        $self->get_list()
            or return;
    }

    $link_list = $self->link_list || [];
    ( $link ) = grep $_->text eq $name, @$link_list;

    $link
        or return $self->_set_error('Recipe not found');

    my $response = $self->ua->get( $link->url );
    $response->is_success
        or return $self->_set_error( $response, 'net' );

    return $self->recipe( $self->_parse_recipe( $response->content ) );
}

sub get_random {
    my ( $self, $letter ) = @_;

    $self->get_list( $letter )
        or return;

    my $list = $self->link_list;

    my $ua = $self->ua;
    my $link = $list->[ rand @$list ];
    my $response = $ua->get( $link->url );
    $response->is_success
        or return $self->_set_error( $response, 'net' );
    
    return $self->recipe( $self->_parse_recipe( $response->content ) );
}

sub _parse_recipe {
    my ( $self, $content ) = @_;

    my $p = HTML::TokeParser::Simple->new( \$content );

    my ( $recipe, $start ) = ( '', 0 );
    while ( my $t = $p->get_token ) {
        if ( $t->is_start_tag('p') and not $start ) {
            $start = 1;
        }
        elsif ( $start and $t->is_end_tag('p') ) {
            $start = 0;
            $recipe .= "\n\n";
        }
        elsif ( $start and $t->is_text ) {
            $recipe .= decode_entities $t->as_is;
        }
        elsif ( $start and $t->is_start_tag('table') ) {
            last;
        }
    }

    return $recipe;
}

sub _set_error {
    my ( $self, $message, $is_net ) = @_;
    if ( $is_net ) {
        $self->error( 'Network error: ' . $message->status_line );
    }
    else {
        $self->error( $message );
    }
    return;
}

1;
__END__

=head1 NAME

WWW::CookieRecipesNet - fetch cookie recipes from http://www.cookie-recipes.net/

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::CookieRecipesNet;

    my $cookie = WWW::CookieRecipesNet->new;

    $cookie->get_random
        or die $cookie->error;

    print $cookie;

=head1 DESCRIPTION

The module provides means to get a list of recipes from L<http://www.cookie-recipes.net/>
as well as get random recipes or get recipes by name.

=head1 CONSTRUCTOR

=head2 C<new>

    my $cookie = WWW::CookieRecipesNet->new;

    my $cookie = WWW::CookieRecipesNet->new(
        ua => WWW::Mechanize->new( timeout => 30, agent => 'Opera 9.5' ),
    );

Constructs and returns a freshly baked L<WWW::CookieRecipesNet> object.
Takes arguments in a key/value fashion. Possible arguments are as follows:

=head3 C<ua>

    my $cookie = WWW::CookieRecipesNet->new(
        ua => WWW::Mechanize->new( timeout => 30, agent => 'Opera 9.5' ),
    );

B<Optional>. The C<ua> argument takes a L<WWW::Mechanize> object as a value. This object
will be used for accessing L<http://www.cookie-recipes.net/>. B<Defaults to:>
C<< WWW::Mechanize->new( timeout => 30, agent => 'Opera 9.5' ) >>

=head1 METHODS

=head2 C<get_list>

    my $recipe_list = $cookie->get_list
        or die $cookie->error;

    my $list_of_recipes_that_start_with_A = $cookie->get_list('A')
        or die $cookie->error;

Instructs the object to fetch a list of recipes from L<http://www.cookie-recipes.net/>.
Takes one optional argument that must be one letter; when this letter is specified, only
recipe names that start with that letter will be listed. On failure returns either C<undef>
or an empty list (depending on the context) and reason for failure will be available via
C<error()> method. On success returns an arrayref with a
list of recipe names; any of these names can be
given to C<get_recipe()> method. See also C<list()> and C<link_list()> methods below.

=head2 C<get_recipe>

    my $recipe = $cookie->get_recipe(q|Witches' Brooms|)
        or die $cookie->error;

Instructs the object to fetch the recipe text. Takes one mandatory argument that must
be the name of the recipe that you can obtain via C<get_list()> method. If called after
a successful call to C<get_list()> will try to find the link to the recipe from the list,
otherwise (or if it doesn't find anything) will call C<get_list()> with no arguments. If
a network error occured or recipe was not found returns either C<undef> or an empty list,
depending on the context, and reason for failure will be available via C<error()> method.
On success returns a scalar containing the text for the fetched recipe.

=head2 C<get_random>

    my $random_recipe = $cookie->get_random
        or die $cookie->error;

    my $random_recipe = $cookie->get_random('A')
        or die $cookie->error;

Instructs the object to fetch a random recipe. Will call C<get_list()> with the same
arguments that you pass to C<get_random()>, thus C<link_list()> and C<list()> will be modified.
Takes one optional argument that is exactly the same as the optional argument to C<get_list()>
method. On failure returns either C<undef> or an empty list, depending on the context, and
the reason for failure will be available via C<error()> method. On success returns a scalar
contain the text of the fetched recipe.

=head2 C<recipe>

    print "I fetched this recipe:\n" . $cookie->recipe;

    # or

    print "I fetched this recipe:\n$cookie";

Must be called after a successful call to either C<get_random()> or C<get_recipe()> method.
Returns the same return value last call to C<get_random()> or C<get_recipe()> method returned.
This method is overloaded on C<q|""|>, thus you can simply use the object in a string.

=head2 C<link_list>

    my $link_list_ref = $cookie->link_list;

Must be called after a successful call to C<get_list()> or one of the
methods that calls C<get_list()> internally. Takes no arguments, returns an arrayref containing
L<WWW::Mechanize::Link> objects, each of which point to a recipe.

=head2 C<list>

    my $recipe_name_list_ref = $cookie->list;

Must be called after a successful call to C<get_list()> or one of the
methods that calls C<get_list()> internally. Takes no arguments, returns an arrayref containing
names of the recipes, i.e. the same arrayref as last call to C<get_list()> returned.

=head2 C<error>

    $cookie->get_random
        or die $cookie->error;

Several methods on failure return either C<undef> or an empty list, depending on the context.
When that happens the C<error()> method will return a human parsable error message explaining
the failure.

=head2 C<ua>

    my $ua = $cookie->ua;
    $ua->proxy('http', 'http://foo.bar.com');
    $cookie->ua( $ua );

Returns a currently used object that is used for fetching recipes. When called with its
optional argument will set that argument as an object for fetching. The argument must satisfy
the same criteria as contructor's C<ua> argument.

=head1 SEE ALSO

L<WWW::Mechanize::Link>, L<http://www.cookie-recipes.net/>

=head1 AUTHOR

'Zoffix, C<< <'zoffix at cpan.org'> >>
(L<http://zoffix.com/>, L<http://haslayout.net/>, L<http://zofdesign.com/>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-cookierecipesnet at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-CookieRecipesNet>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::CookieRecipesNet

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-CookieRecipesNet>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-CookieRecipesNet>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-CookieRecipesNet>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-CookieRecipesNet>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 'Zoffix, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

