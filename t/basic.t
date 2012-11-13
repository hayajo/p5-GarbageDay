use 5.10.0;
use strict;
use warnings;
use utf8;

use Test::More tests => 7;
use GarbageDay;
use YAML;

my $schedule = Load( do { local $/; <DATA> } );

my $gd = new_ok( 'GarbageDay' => [ schedule => $schedule ] );
is_deeply $gd->schedule, $schedule;

subtest 'date' => sub {
    my $date = '2012-01-09'; # Wed
    my $expected = ['燃やすゴミ'];
    subtest 'scalar' => sub {
        my $list = $gd->can_dump($date);
        is_deeply( $list, $expected );
    };
    subtest 'array' => sub {
        my ($list, $time) = $gd->can_dump($date);
        is_deeply( $list, $expected );
        is( $time->strftime('%Y-%m-%d'), $date );
    };
};

subtest 'every year' => sub {
    for (1..3) {
        my $date = sprintf("%d-12-31", 2000 + rand(100));
        my $list = $gd->can_dump($date);
        ok( grep /^燃やすゴミ$/, @$list ) or diag explain $list;
    }
};

subtest 'every week' => sub {
    for my $date (qw/2012-01-04 2012-01-11 2012-01-18/) {
        my $list = $gd->can_dump($date);
        is_deeply( $list, [ sort(qw/枝葉・草 燃やすゴミ/) ] );
    }
};

subtest 'week of month' => sub {
    for my $date (qw/2012-01-28 2012-02-25 2012-10-27/) {
        my $list = $gd->can_dump($date);
        is_deeply( $list, [ sort(qw/ペットボトル 燃やさないゴミ/) ] );
    }
    for my $date (qw/2012-01-21 2012-02-18 2012-10-20/) {
        my $list = $gd->can_dump($date);
        is_deeply( $list, [] );
    }
};

subtest 'exclude' => sub {
    my $year = 2000 + rand(100);
    for (1..3) {
        my $date = sprintf("%d-01-%02d", $year, $_);
        my $list = $gd->can_dump($date);
        ok @$list == 0;
    }
    for my $date (qw/2012-02-15 2012-03-07/) { # wed
        my $list = $gd->can_dump($date);
        ok $list, [ '燃やすゴミ' ];
    }
}

__DATA__
# date
2012-01-09: 燃やすゴミ

# every year
"*-12-31": 燃やすゴミ

# every week
Wed:
  - 燃やすゴミ
  - 枝葉・草

# week of month
Sat-4:
  - 燃やさないゴミ
  - ペットボトル

# exclude
"!*-01-01": "*"
"!*-01-02": "*"
"!*-01-03": "*"
"!*-02-*": 枝葉・草
"!*-03-*": 枝葉・草
