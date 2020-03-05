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

my $opacresults  = undef;
my $opacdetails  = undef;
my $staffresults = undef;
my $staffdetails = undef;
my $opaclists    = undef;
my $stafflists   = undef;

GetOptions(
    "c|confirm"     => \$confirm,
    "v|verbose+"    => \$verbose,
    "s|shortname=s" => \$shortname,
    "t|target=s"    => \$target_shortname,
    "r|repo=s"      => \$which_repo,

    "opacdetails"   => \$opacdetails,
    "opacresults"   => \$opacresults,
    "staffdetails"  => \$staffdetails,
    "staffresults"  => \$staffresults,

    # If these are defined byt empty, we use the results xslt, otherwise use the file specified
    "opaclists:s"    => \$opaclists,
    "stafflists:s"   => \$stafflists,
);

# If no xslt file is specified, the default is to enable all of them
unless ( $opacresults || $opacdetails || $staffresults || $staffdetails || defined $opaclists || defined $stafflists ) {
    my $opacdetails = 1;
    my $opaclists  //= q{};
    my $opacresults = 1;

    my $staffdetails = 1;
    my $stafflists //= q{};
    my $staffresults = 1;
}

my $xslt_options = {
    opacdetails  => $opacdetails,
    opaclists    => $opaclists,
    opacresults  => $opacresults,
    opacutils    => 1,
    staffdetails => $staffdetails,
    stafflists   => $stafflists,
    staffresults => $staffresults,
    staffutils   => 1,
};

my $repo = $which_repo ? $which_repo : "https://raw.githubusercontent.com/bywatersolutions/bywater-koha-xslt"

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

my $stylesheets = {
    staffdetails => {
        url               => "$repo/$shortname/koha-tmpl/intranet-tmpl/prog/en/xslt/MARC21slim2intranetDetail.xsl",
        filename          => "/var/lib/koha/$target_shortname/custom-xslt/intranet/$target_shortname-intranet-detail.xsl",
        system_preference => 'XSLTDetailsDisplay',
    },
    staffresults => {
        url               => "$repo/$shortname/koha-tmpl/intranet-tmpl/prog/en/xslt/MARC21slim2intranetResults.xsl",
        filename          => "/var/lib/koha/$target_shortname/custom-xslt/intranet/$target_shortname-intranet-results.xsl",
        system_preference => 'XSLTResultsDisplay',
    },
    staffutils => {
        url               => "$repo/$shortname/koha-tmpl/intranet-tmpl/prog/en/xslt/MARC21slimUtils.xsl",
        filename          => "/var/lib/koha/$target_shortname/custom-xslt/intranet/MARC21slimUtils.xsl",
    },
    stafflists => {
        url               => $stafflists,
        filename          => "/var/lib/koha/$target_shortname/custom-xslt/intranet/staff-lists.xsl",
        system_preference => 'XSLTListsDisplay',
    },
    opacdetails => {
        url               => "$repo/$shortname/koha-tmpl/opac-tmpl/bootstrap/en/xslt/MARC21slim2OPACDetail.xsl",
        filename          => "/var/lib/koha/$target_shortname/custom-xslt/opac/$target_shortname-opac-detail.xsl",
        system_preference => 'OPACXSLTDetailsDisplay',
    },
    opacresults => {
        url               => "$repo/$shortname/koha-tmpl/opac-tmpl/bootstrap/en/xslt/MARC21slim2OPACResults.xsl",
        filename          => "/var/lib/koha/$target_shortname/custom-xslt/opac/$target_shortname-opac-results.xsl",
        system_preference => 'OPACXSLTResultsDisplay',
    },
    opacutils => {
        url               => "$repo/$shortname/koha-tmpl/opac-tmpl/bootstrap/en/xslt/MARC21slimUtils.xsl",
        filename          => "/var/lib/koha/$target_shortname/custom-xslt/opac/MARC21slimUtils.xsl",
    },
    opaclists => {
        url               => $opaclists,
        filename          => "/var/lib/koha/$target_shortname/custom-xslt/opac/opac-lists.xsl",
        system_preference => 'OPACXSLTListsDisplay',
    },
};

if ( $confirm ) {
    say "CONFIRM SWITCH PASSED, CREATING DIRECTORIES" if $verbose;
    for my $dir ( @dirs ) {
        unless (-e $dir and -d $dir) {
            my $success = mkdir $dir;
            say "FAILED TO MAKE DIR $dir" unless $success;
        }
    }
}

for my $type (
    qw( staffdetails staffresults staffutils stafflists opacdetails opacresults opacutils opaclists )
  )
{
    my $s = $stylesheets->{$type};

    my $xslt;

    if ($verbose) {
        say q{===============================================================};
        say "Type:        $type";
        say "URL:         $s->{url}";
        say "Filename:    $s->{filename}";
        say "System Pref: $s->{system_preference}" if $s->{system_preference};
    }

    if ( $s->{url} ) {
        $xslt = get( $s->{url} );

        say "Downloaded XSLT file from $s->{url}" if $xslt && $verbose;
        say "ERROR: XSLT file not found!" unless $xslt;
    }

    if ( $confirm && $xslt ) {
        say "CONFIRMED: Updating system preferences" if $verbose;

        open my $fh, ">", $s->{filename} or die("Could not open file. $!");
        print $fh $xslt;
        close $fh;
        say "File $s->{filename} created!" if $verbose;

        if ( $s->{system_preference} ) {
            my $sp = $rs->find( $s->{system_preference} );

            if ( -e $s->{filename} ) {
                $sp->value( $s->{filename} );
            }
            elsif ( $type eq 'stafflists' ) {
                # No url for custom xslt was specified, detail to results xslt
                $sp->value( $stylesheets->{staffresults}->{filename} );
            }
            elsif ( $type eq 'opaclists' ) {
                # Same as above, but for OPAC lists
                $sp->value( $stylesheets->{opacresults}->{filename} );
            }
            else {
                die( "DANGER WILL ROBINSON!!! Unable to fine file for: "
                      . Data::Dumper::Dumper($s) );
            }

            $sp->update();
            say "System preference updated!" if $verbose;
        }
    }

}

say qq{\n} if $verbose;

exit 0;
