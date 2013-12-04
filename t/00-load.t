#!/usr/bin/env perl

use Test::More tests => 14;

BEGIN {
    use_ok('WWW::Mechanize');
    use_ok('HTML::TokeParser::Simple');
    use_ok('HTML::Entities');
    use_ok('Class::Data::Accessor');
	use_ok( 'WWW::CookieRecipesNet' );
}

diag( "Testing WWW::CookieRecipesNet $WWW::CookieRecipesNet::VERSION, Perl $], $^X" );

can_ok('WWW::CookieRecipesNet', qw/new get_list
get_recipe
get_random
recipe
link_list
list
error
ua/);

my $cookie = WWW::CookieRecipesNet->new;
isa_ok($cookie, 'WWW::CookieRecipesNet');
isa_ok($cookie->ua, 'WWW::Mechanize');

my $recipe = $cookie->get_random;

ok( defined $recipe and length $recipe or length $cookie->error );

my $recipe = $cookie->get_recipe(q|Witches' Brooms|);



ok( defined $recipe and length $recipe or length $cookie->error );
is( $recipe, recipe() );
is( $recipe, "$cookie" );
is( $recipe, $cookie->recipe );

my @list = @{ $cookie->get_list('A') || [] };

my $count = grep /^A/, @list;
is( $count, ~~@list );



sub recipe {
return "Witches' Brooms\n\nAmount Measure Ingredient -- Preparation Method\n\n-------- ------------ --------------------------------\n\n1/2 cup packed brown sugar\n\n1/2 cup butter or margarine -- softened\n\n2 tablespoons water\n\n1 teaspoon vanilla\n\n1 1/2 cups all-purpose flour\n\n1/8 teaspoon salt\n\n10 pretzel rods (about 8 1/2 inches long) -- cut crosswise in half\n\n2 teaspoons shortening\n\n2/3 cup semisweet chocolate chips\n\n1/3 cup butterscotch-flavored chips\n\nHeat oven to 350\302\272. Beat brown sugar, butter, water and vanilla in medium bowl with electric mixer on medium speed, or mix with spoon. Stir in flour and salt. Shape dough into twenty 1 1/4-inch balls.\n\nPlace pretzel rod halves on ungreased cookie sheet. Press ball of dough onto cut end of each pretzel rod. Press dough with fork to resemble bristles of broom. Bake about 12 minutes or until set but not brown. Remove from cookie sheet to wire rack. Cool completely.\n\nCover cookie sheet with waxed paper. Place brooms on waxed paper. Melt shortening and chocolate chips in 1-quart saucepan over low heat, stirring occasionally, until smooth; remove from heat. Spoon melted chocolate over brooms, leaving about 1 inch at top of pretzel handle and bottom halves of cookie bristles uncovered.\n\nPlace butterscotch chips in microwavable bowl. Microwave uncovered on Medium-High (70%) 30 to 50 seconds, stirring after 30 seconds, until chips can be stirred smooth. Drizzle over chocolate. Let stand until chocolate is firm.\n\n\r\n";
}




