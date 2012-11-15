package GarbageDay;
use strict;
use warnings;
our $VERSION = '0.01';

use Time::Piece;

BEGIN {
    no strict 'refs';
    *{'Time::Piece::week_of_month'} = sub {
        my $self = shift;
        return int( ( $self->mday - ( $self->day_of_week + 1 ) + 13 ) / 7 );
    };
    *{'Time::Piece::weekday_of_month'} = sub {
        my $self = shift;
        return int( ( $self->mday + 6 ) / 7 );
    };
}

use Any::Moose;

has 'schedule' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { +{} },
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

use constant DATE_FORMAT => '%Y-%m-%d';

sub can_dump {
    my $self = shift;
    my $t = shift || localtime;
    $t = Time::Piece->strptime( $t, DATE_FORMAT )
        unless ( ref $t && $t->isa('Time::Piece') );

    my $y      = $t->year;
    my $m      = sprintf( '%02d', $t->mon );
    my $d      = sprintf( '%02d', $t->mday );
    my $wday   = $t->wdayname;
    my $wdom   = $t->weekday_of_month;
    my $r_date = "($y|\\*)-($m|\\*)-($d|\\*)";
    my $r_wday = "$wday(-$wdom)?";
    my $regex  = qr/^(!)?\s*($r_date|$r_wday)$/i;

    my $garbage      = +{};
    my $cannot_dump = +{};
    my @days         = keys %{ $self->schedule };
    for my $day (@days) {
        next if ( $day !~ $regex );
        my $list = $self->_get_garbage($day);
        if (! $1) {
            map { $garbage->{$_} = 1 } @$list;
        }
        else { # exclude
            for (@$list) {
                return [] if ( $_ eq '*' ); # '*' is all exclude.
                $cannot_dump->{$_} = 1;
            }
            next;
        }
    }
    map { delete $garbage->{$_} } keys %$cannot_dump;

    my $list = [ sort keys %$garbage ];
    return wantarray ? ( $list, $t ) : $list;
}

sub _get_garbage {
    my $self = shift;
    my $day  = shift || return;
    my $list = $self->schedule->{$day} || [];
    $list = ["$list"] if ( ref $list ne 'ARRAY' );
    return $list;
}

1;
__END__

=encoding utf8

=head1 NAME

GarbageDay - What can you dump garbage today ?

=head1 SYNOPSIS

  use GarbageDay;
  my $gd = GarbageDay->new( schedule => {
      'Mon' => '燃やすごみ',
      'Wed' => [
                  '燃やすごみ',
                  '枝葉・草'
              ],
      'Thu-2' => '古紙類',
      'Sat-4' => [
                  '燃やさないごみ',
                  'ペットボトル'
                  ],
      '*-12-31' => '燃やすごみ',
      '!*-01-01' => '*',
      '!*-01-02' => '*',
      '!*-01-03' => '*',
      '!*-02-*' => '枝葉・草',
  });

  use Data::Dumper;
  say Dumper( $gd->can_dump() );

=head1 DESCRIPTION

GarbageDay is life-hack module to know "What can I dump garbage today ?"

=head1 CONSTRUCTORS

The following methods construct new GarbageDay objects:

=head2 C<new>

  my $gd = GarbageDay->new( schedule => {
      'Mon' => '燃やすごみ',
      'Wed' => [
                  '燃やすごみ',
                  '枝葉・草'
              ],
      'Thu-2' => '古紙類',
      'Sat-4' => [
                  '燃やさないごみ',
                  'ペットボトル'
                  ],
      '*-12-31' => '燃やすごみ',
      '!*-01-01' => '*',
      '!*-01-02' => '*',
      '!*-01-03' => '*',
      '!*-02-*' => '枝葉・草',
  });

Create a new object.

This method can take properties. see L<"PROPERTIES">.

=head1 PROPERTIES

=head2 C<schedule>

schedule of garbage day as Hashref.

  my $schedule = {
      'Mon' => '燃やすごみ',
      'Wed' => [
                  '燃やすごみ',
                  '枝葉・草'
              ],
      'Thu-2' => '古紙類',
      'Sat-4' => [
                  '燃やさないごみ',
                  'ペットボトル'
                  ],
      '*-12-31' => '燃やすごみ',
      '!*-01-01' => '*',
      '!*-01-02' => '*',
      '!*-01-03' => '*',
      '!*-02-*' => '枝葉・草',
  };
  my $gd = GarbageDay->new( schedule => $schedule );

=head3 every week

  my $schedule = {
      'Mon' => '燃やすごみ',
      'Wed' => [
                  '燃やすごみ',
                  '枝葉・草'
              ],
  };

=head3 week of month

  my $schedule = {
      'Thu-2' => '古紙類',
      'Sat-4' => [
                  '燃やさないごみ',
                  'ペットボトル'
                  ],
  };

=head3 date

  my $schedule = {
      '2012-01-04' => '燃やすゴミ',
  };

=head3 every year

  my $schedule = {
      '*-12-31' => '燃やすゴミ',
  };

=head3 every month

  my $schedule = {
      '*-*-01' => '燃やすゴミ',
  };

=head3 every day

  my $schedule = {
      '*-*-*' => '燃やすゴミ',
  };

=head3 excludes

add a "!" At the beginning.

  my $schedule = {
      '!*-01-01' => '*',
      '!*-01-02' => '*',
      '!*-01-03' => '*',
      '!*-02-*'  => '枝葉・草',
      '!*-03-*'  => '枝葉・草',
  };

=head1 METHODS

=head2 C<can_dump>

  say Dumper( $gd->can_dump() ); # today
  say Dumper( $gd->can_dump('2012-05-03') );

get list of "What can I dump garbage ?".

=head1 AUTHOR

hayajo E<lt>hayajo@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
