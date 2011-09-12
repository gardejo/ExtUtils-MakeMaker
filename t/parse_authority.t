#!/usr/bin/perl -w

BEGIN {
    unshift @INC, 't/lib';
}
chdir 't';

use Test::More;
use ExtUtils::MakeMaker;

my %authorities = (q[$AUTHORITY = 'cpan:JOHNDOE']               => 'cpan:JOHNDOE',
                   q[*AUTHORITY = \'cpan:JOHNDOE']              => 'cpan:JOHNDOE',
                   '($AUTHORITY) = q$Author: cpan:JOHNDOE $ =~ /Author:\s(.+)\s/g;' => 'cpan:JOHNDOE',
                   q[$FOO::AUTHORITY = 'cpan:JOHNDOE';]         => 'cpan:JOHNDOE',
                   q[*FOO::AUTHORITY = \'cpan:JOHNDOE';]        => 'cpan:JOHNDOE',
                   '$AUTHORITY = undef'                         => 'undef',
                   q[$wibble  = 'cpan:JOHNDOE']                 => 'undef',
                   q[my $AUTHORITY = 'cpan:JOHNDOE']            => 'undef',
                   q[local $AUTHOIRTY = 'cpan:JOHNDOE']         => 'undef',
                   q[local $FOO::AUTHORITY = 'cpan:JOHNDOE']    => 'undef',
                   q[if( $Foo::AUTHORITY ne 'cpan:JOHNDOE' ) {] => 'undef',
                   q[our $AUTHORITY = 'cpan:JOHNDOE';]          => 'cpan:JOHNDOE',

                   q[$Something::AUTHORITY eq 'cpan:JOHNDOE']   => 'undef',
                   q[$Something::AUTHORITY ne 'cpan:JOHNDOE']   => 'undef',

                   qq[\$Something::AUTHORITY == 'cpan:FOO'\n\$AUTHORITY = 'cpan:JOHNDOE'\n]                             => 'cpan:JOHNDOE',
                   qq[\$Something::AUTHORITY == 'cpan:FOO'\n\$AUTHORITY = 'cpan:JOHNDOE'\n\$AUTHORITY = 'cpan:BAR'\n]   => 'cpan:JOHNDOE',

                   '$AUTHORITY = sprintf("%s", q$Author: cpan:JOHNDOE $ =~ /:\s(.+)\s$/);'                         => 'cpan:JOHNDOE',
                   q[$AUTHORITY = substr(q$Author: cpan:JOHNDOE $, 8, -1) . 'X';]                                           => 'cpan:JOHNDOEX',
                   q[elsif ( $Something::AUTHORITY ne 'cpan:JOHNDOE' )] => 'undef',

                  );


plan tests => 3 * keys %authorities;

for my $code ( sort keys %authorities ) {
    my $expect = $authorities{$code};
    (my $label = $code) =~ s/\n/\\n/g;
    my $warnings = "";
    local $SIG{__WARN__} = sub { $warnings .= "@_\n"; };
    is( parse_authority_string($code), $expect, $label );
    is($warnings, '', "$label does not cause warnings");
}


sub parse_authority_string {
    my $code = shift;

    open(FILE, ">AUTHORITY.tmp") || die $!;
    print FILE "$code\n";
    close FILE;

    $_ = 'foo';
    my $authority = MM->parse_authority('AUTHORITY.tmp');
    is( $_, 'foo', '$_ not leaked by parse_authority' );

    unlink "AUTHORITY.tmp";

    return $authority;
}
