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
my $version = q{};
GetOptions(
    "c|confirm" => \$confirm,
    "v|verbose+" => \$verbose,
    "version:s"   => \$version,
);

$verbose = 1 unless $confirm;

my $rs = Koha::Database->new()->schema()->resultset('Systempreference');

my ($shortname) = split( '-', $ENV{LOGNAME} || $ENV{USERNAME} || $ENV{USER} );
unless ( $version ) {
    my $koha_version = Koha::version();
    say "Koha Version: $koha_version" if $verbose > 1;
    my ( $major, $minor ) = split( '\.', $koha_version );
    say "Major number: $major" if $verbose > 1;
    say "Minor number: $minor" if $verbose > 1;
    $version = "v$major.$minor";
}
say "SHORTNAME: $shortname" if $verbose;
say "VERSION: $version" if $verbose;

unless ( $version =~ m/^v\d\d\.\d\d$/ ) {
    say "ERROR: Version does not match the format vXX.YY";
    exit(1);
}
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
    say "ERROR: XSLT FILE NOT FOUND" unless $xslt;

    if ( $confirm && $xslt ) {
        say "CONFIRM SWITCH PASSED, EXECUTING" if $verbose;
        for my $dir ( @dirs ) {
            my $success = mkdir $dir;
            die "FAILED TO MAKE DIR $dir" unless $success;
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
