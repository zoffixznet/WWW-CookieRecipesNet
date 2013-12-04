#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(lib ../lib);

use WWW::CookieRecipesNet;

my $cookie = WWW::CookieRecipesNet->new;

$cookie->get_random(q|Witches' Brooms|)
    or die $cookie->error;

print $cookie;