use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use Data::Dumper;
use File::Basename;
use Cwd;
use List::Util qw(first);

my $program = basename($0);
my $version = "1.0";
my $debug = 0;
my $verbose = 0;
my $help = 0;
my $man = 0;

GetOptions(
    "help|?"  => \$help,
    "man"     => \$man,
    "debug"   => \$debug,
    "verbose" => \$version,
    "version" => \$man,
    "verbose" => \$verbose,
    "debug"   => \$debug,
) or pod2usage(2);
pod2usage(1) if defined $help;


=pod

=head1 API

=head2 INVEST::NTT

=head2 INVEST::NTT::NTT

=head2 INVEST::NTT:NTT:NTT

=head2 INVEST:NTT::NTT:NTT

=encoding UTF-8

=head1 SYNOPSIS

INVEST::NTT [options] <file>

=head1 DESCRIPTION

=head1 options

=over 1

=item -help or --help

=item --man

=item -debug or --debug

=item --verbose or -verbose

=item --version or -version


=back

=head1 ATTRIBUTES

The following attributes are available.
readonly file.

methods readonly:

sub ntt re cursor

=head1 CONTRIBUTORS

=head1 FUNCTIONS

=head1 INSTALLATION

=head1 VERSION

=head1 COPYRIGHT AND LICENSE

this program is free software; you can redistributes is and/or modify;
it under the something.

=cut
