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
my $version;
GetOptions(
    "c|confirm" => \$confirm,
    "v|verbose" => \$verbose,
    "version"   => \$version,
);

$verbose = 1 unless $confirm;

my $rs = Koha::Database->new()->schema()->resultset('Systempreference');

my $shortname;
unless ( $version ) {
    ($shortname) = split( '-', $ENV{LOGNAME} || $ENV{USERNAME} || $ENV{USER} );
    my ( $major, $minor ) = split( '\.', Koha::version() );
    my $version = "v$major.$minor";
}
say "SHORTNAME: $shortname" if $verbose;
say "VERSION: $version" if $verbose;

my @dirs = (
    "/var/lib/koha/$shortname/custom-xslt",
    "/var/lib/koha/$shortname/custom-xslt/intranet",
    "/var/lib/koha/$shortname/custom-xslt/opac",
);

my @stylesheets = (
    {
        url               => "$repo/$version/$shortname/koha-tmpl/intranet-tmpl/prog/en/xslt/MARC21slim2intranetDetail.xsl",
        filename          => "/var/lib/koha/$shortname/custom-xslt/intranet/$shortname-intranet-detail.xsl",
        system_preference => 'XSLTDetailsDisplay',
    },
    {
        url               => "$repo/$version/$shortname/koha-tmpl/intranet-tmpl/prog/en/xslt/MARC21slim2intranetResults.xsl",
        filename          => "/var/lib/koha/$shortname/custom-xslt/intranet/$shortname-intranet-results.xsl",
        system_preference => 'XSLTResultsDisplay',
    },
    {
        url               => "$repo/$version/$shortname/koha-tmpl/intranet-tmpl/prog/en/xslt/MARC21slimUtils.xsl",
        filename          => "/var/lib/koha/$shortname/custom-xslt/intranet/MARC21slimUtils.xsl",
    },
    {
        url               => "$repo/$version/$shortname/koha-tmpl/opac-tmpl/bootstrap/en/xslt/MARC21slim2OPACDetail.xsl",
        filename          => "/var/lib/koha/$shortname/custom-xslt/opac/$shortname-opac-detail.xsl",
        system_preference => 'OPACXSLTDetailsDisplay',
    },
    {
        url               => "$repo/$version/$shortname/koha-tmpl/opac-tmpl/bootstrap/en/xslt/MARC21slim2OPACResults.xsl",
        filename          => "/var/lib/koha/$shortname/custom-xslt/opac/$shortname-opac-results.xsl",
        system_preference => 'OPACXSLTResultsDisplay',
    },
    {
        url               => "$repo/$version/$shortname/koha-tmpl/opac-tmpl/bootstrap/en/xslt/MARC21slimUtils.xsl",
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

    if ( $confirm && $xslt ) {
        for my $dir ( @dirs ) {
            mkdir $dir;
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
