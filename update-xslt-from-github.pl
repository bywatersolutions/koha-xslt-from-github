#!/usr/bin/perl

use Modern::Perl;
use LWP::Simple qw(get);
use Getopt::Long;
use Koha;
use Koha::Database;

my $repo =
  "https://raw.githubusercontent.com/bywatersolutions/bywater-koha-xslt";

my $confirm;
my $verbose;
GetOptions(
    "c|confirm" => \$confirm,
    "v|verbose+" => \$verbose,
);

$verbose = 1 unless $confirm;

my $rs = Koha::Database->new()->schema()->resultset('Systempreference');

my ($shortname) = split( '-', $ENV{LOGNAME} || $ENV{USERNAME} || $ENV{USER} );
say "SHORTNAME: $shortname" if $verbose;

unless ( $shortname ) {
    say "ERROR: Unable to detect shortname";
    exit(1);
}

my @dirs = (
    "/var/lib/koha/$shortname/custom-xslt",
    "/var/lib/koha/$shortname/custom-xslt/intranet",
    "/var/lib/koha/$shortname/custom-xslt/opac",
);

my @stylesheets = (
    {
        url               => "$repo/$shortname/koha-tmpl/intranet-tmpl/prog/en/xslt/MARC21slim2intranetDetail.xsl",
        filename          => "/var/lib/koha/$shortname/custom-xslt/intranet/$shortname-intranet-detail.xsl",
        system_preference => 'XSLTDetailsDisplay',
    },
    {
        url               => "$repo/$shortname/koha-tmpl/intranet-tmpl/prog/en/xslt/MARC21slim2intranetResults.xsl",
        filename          => "/var/lib/koha/$shortname/custom-xslt/intranet/$shortname-intranet-results.xsl",
        system_preference => 'XSLTResultsDisplay',
    },
    {
        url               => "$repo/$shortname/koha-tmpl/intranet-tmpl/prog/en/xslt/MARC21slimUtils.xsl",
        filename          => "/var/lib/koha/$shortname/custom-xslt/intranet/MARC21slimUtils.xsl",
    },
    {
        url               => "$repo/$shortname/koha-tmpl/opac-tmpl/bootstrap/en/xslt/MARC21slim2OPACDetail.xsl",
        filename          => "/var/lib/koha/$shortname/custom-xslt/opac/$shortname-opac-detail.xsl",
        system_preference => 'OPACXSLTDetailsDisplay',
    },
    {
        url               => "$repo/$shortname/koha-tmpl/opac-tmpl/bootstrap/en/xslt/MARC21slim2OPACResults.xsl",
        filename          => "/var/lib/koha/$shortname/custom-xslt/opac/$shortname-opac-results.xsl",
        system_preference => 'OPACXSLTResultsDisplay',
    },
    {
        url               => "$repo/$shortname/koha-tmpl/opac-tmpl/bootstrap/en/xslt/MARC21slimUtils.xsl",
        filename          => "/var/lib/koha/$shortname/custom-xslt/opac/MARC21slimUtils.xsl",
    },
);

my $xslt;

for my $s (@stylesheets) {
    if ($verbose) {
        say q{};
        say "URL: $s->{url}";
        say "FILENAME: $s->{filename}";
        say "SYSTEM PREF: $s->{system_preference}" if $s->{system_preference};
    }

    $xslt = get( $s->{url} );

    say "FOUND XSLT FILE" if $xslt && $verbose;
    say "ERROR: XSLT FILE NOT FOUND" unless $xslt;

    if ( $confirm && $xslt ) {
        say "CONFIRM SWITCH PASSED, EXECUTING" if $verbose;
        for my $dir ( @dirs ) {
            unless (-e $dir and -d $dir) {
                my $success = mkdir $dir;
                say "FAILED TO MAKE DIR $dir" unless $success;
            }
        }

        say "File created!" if $verbose;
        open my $fh, ">", $s->{filename} or die("Could not open file. $!");
        print $fh $xslt;
        close $fh;

       if ( $s->{system_preference} ) {
            my $sp = $rs->find( $s->{system_preference} );
            $sp->value( $s->{filename} );
            $sp->update();
            say "System preference updated!" if $verbose;
       }
    }

}

say qq{\n} if $verbose;

exit 0;
