use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::CookieRecipesNet',
    license             => 'perl',
    dist_author         => q|Zoffix <'zoffix@cpan.org'>|,
    dist_version_from   => 'lib/WWW/CookieRecipesNet.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'WWW::Mechanize'           => 1.34,
        'HTML::TokeParser::Simple' => 3.15,
        'HTML::Entities'           => 1.35,
        'Class::Data::Accessor'    => 0.04001,
        'overload'                 => 1.04,
    },
    add_to_cleanup      => [ 'WWW-CookieRecipesNet-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
