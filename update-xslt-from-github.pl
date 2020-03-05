#!/usr/bin/perl

use Modern::Perl;
use LWP::Simple qw(get);
use Getopt::Long;
use Koha;
use Koha::Database;

my $confirm;
my $verbose;
my $shortname;
my $target_shortname;
my $which_repo = q{};
GetOptions(
    "c|confirm"     => \$confirm,
    "v|verbose+"    => \$verbose,
    "s|shortname=s" => \$shortname,
    "t|target=s"    => \$target_shortname,
    "r|repo=s"      => \$which_repo,
);

my $repo = $which_repo eq 'updated'
  ? "https://raw.githubusercontent.com/bywatersolutions/bywater-koha-xslt"
  : "https://raw.githubusercontent.com/bywatersolutions/bywater-koha-xslt-updated";

$verbose = 1 unless $confirm;

my $rs = Koha::Database->new()->schema()->resultset('Systempreference');

unless ( $shortname ) {
    ($shortname) = split( '-', $ENV{LOGNAME} || $ENV{USERNAME} || $ENV{USER} );
    say "SHORTNAME: $shortname" if $verbose;
}

unless ( $shortname ) {
    say "ERROR: Unable to detect shortname";
    exit(1);
}

# $shortname refers to the shortname in the git repo,
# target_shortname refers the shortname of the instance on this Koha server
# They will almost always match except in the case of testing,
# where the shortname will be the branch being tested, and the target will be
# your local instance name ( e.g. kohadev )
$target_shortname ||= $shortname;

my @dirs = (
    "/var/lib/koha/$target_shortname/custom-xslt",
    "/var/lib/koha/$target_shortname/custom-xslt/intranet",
    "/var/lib/koha/$target_shortname/custom-xslt/opac",
);

my @stylesheets = (
    {
        url               => "$repo/$shortname/koha-tmpl/intranet-tmpl/prog/en/xslt/MARC21slim2intranetDetail.xsl",
        filename          => "/var/lib/koha/$target_shortname/custom-xslt/intranet/$target_shortname-intranet-detail.xsl",
        system_preference => 'XSLTDetailsDisplay',
    },
    {
        url               => "$repo/$shortname/koha-tmpl/intranet-tmpl/prog/en/xslt/MARC21slim2intranetResults.xsl",
        filename          => "/var/lib/koha/$target_shortname/custom-xslt/intranet/$target_shortname-intranet-results.xsl",
        system_preference => 'XSLTResultsDisplay',
    },
    {
        url               => "$repo/$shortname/koha-tmpl/intranet-tmpl/prog/en/xslt/MARC21slimUtils.xsl",
        filename          => "/var/lib/koha/$target_shortname/custom-xslt/intranet/MARC21slimUtils.xsl",
    },
    {
        url               => "$repo/$shortname/koha-tmpl/opac-tmpl/bootstrap/en/xslt/MARC21slim2OPACDetail.xsl",
        filename          => "/var/lib/koha/$target_shortname/custom-xslt/opac/$target_shortname-opac-detail.xsl",
        system_preference => 'OPACXSLTDetailsDisplay',
    },
    {
        url               => "$repo/$shortname/koha-tmpl/opac-tmpl/bootstrap/en/xslt/MARC21slim2OPACResults.xsl",
        filename          => "/var/lib/koha/$target_shortname/custom-xslt/opac/$target_shortname-opac-results.xsl",
        system_preference => 'OPACXSLTResultsDisplay',
    },
    {
        url               => "$repo/$shortname/koha-tmpl/opac-tmpl/bootstrap/en/xslt/MARC21slimUtils.xsl",
        filename          => "/var/lib/koha/$target_shortname/custom-xslt/opac/MARC21slimUtils.xsl",
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
