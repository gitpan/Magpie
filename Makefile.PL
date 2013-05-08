
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Pipelined State Machine Plack Middleware Framework",
  "AUTHOR" => "Kip Hampton <kip.hampton\@tamarou.com>, Chris Prather <chris.prather\@tamarou.com>",
  "BUILD_REQUIRES" => {
    "HTTP::Request::Common" => "6.02",
    "Test::Requires" => 0,
    "Test::Simple" => "0.98"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Magpie",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Magpie",
  "PREREQ_PM" => {
    "Bread::Board" => "0.25",
    "Carp" => "1.24",
    "HTTP::Negotiate" => "6.00",
    "HTTP::Throwable" => "0.016",
    "Moose" => "2.0402",
    "MooseX::Role::Parameterized" => 0,
    "MooseX::Traits" => "0.11",
    "MooseX::Types::Path::Class" => "0.05",
    "Plack" => "0.9985",
    "Scalar::Util" => "1.23",
    "Try::Tiny" => "0.11",
    "URI" => "1.59"
  },
  "VERSION" => "1.131280",
  "test" => {
    "TESTS" => "t/*.t t/config/*.t t/core/*.t t/plugins/*.t t/resources/*.t t/transformers/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



