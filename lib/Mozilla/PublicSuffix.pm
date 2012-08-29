package Mozilla::PublicSuffix;

use strict;
use warnings FATAL => "all";
use utf8;
use Carp;
use Exporter "import";
use Regexp::Common "net";
use URI::_idna;

our @EXPORT_OK = qw(public_suffix);

# VERSION
# ABSTRACT: Get a domain name's public suffix via the Mozilla Public Suffix List

my $dn_re = qr/^$RE{net}{domain}$/;
sub public_suffix {
    # Decode domains in punycode form:
    my $domain = index($_[0], "xn--") == -1
        ? lc $_[0]
        : eval { lc URI::_idna::decode($_[0]) };

    # Test domain well-formedness:
    if ($domain !~ $dn_re) {
        croak("Argument passed is not a well-formed domain name");
    }

    # Search using the full domain and a substring consisting of its lowest
    # levels:
    return _find_rule($domain, substr($domain, index($domain, ".") + 1 ) );
}

my %rules = qw();
sub _find_rule {
    my ($string, $rhs) = @_;
    my $rule = $rules{$string};
    return do {
        # Test for rule match with full string:
        if (defined $rule) {
            # If a wilcard rule matches the full string; fail early:
            if ($rule eq "w") { undef }
            # All other rule matches mean success:
            else { $string }
        }
        # Fail if no match found and the full string and right-hand substring
        # are identical:
        elsif ($string eq $rhs) { undef }
        # No match found with the full string, but there are more levels of the
        # domain to check:
        else {
            my $rrule = $rules{$rhs};
            # Test for rule match with right-hand side:
            if (defined $rrule) {
                # If a wildcard rule matches the right-hand substring, the
                # full string is the public suffix:
                if ($rrule eq "w") { $string }
                # Otherwise, it's the substring:
                else { $rhs }
            }
            # Recurse with the right-hand substring as the full string, and the
            # old substring sans its lowest domain level as the new substring:
            else {
                _find_rule( $rhs, substr($rhs, index($rhs, ".") + 1 ) );
            }
        }
    }
}

1;
