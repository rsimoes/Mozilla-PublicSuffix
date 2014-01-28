package Mozilla::PublicSuffix;

use strict;
use warnings FATAL => "all";
use utf8;
use Exporter "import";
use URI::_idna;

our @EXPORT_OK = qw(public_suffix);

# VERSION
# ABSTRACT: Get a domain name's public suffix via the Mozilla Public Suffix List

my $dn_re = do {
    my $alf = "[[:alpha:]]";
    my $aln = "[[:alnum:]]";
    my $anh = "[[:alnum:]-]";
    my $re_str = join(
        "",
        "(?:$aln(?:(?:$anh){0,61}$aln)?",
        "(?:\\.$aln(?:(?:$anh){0,61}$aln)?)*)"
    );
    qr/^$re_str$/;
};
sub public_suffix {

    # Decode domains in punycode form:
    my $domain = defined($_[0]) && ref($_[0]) eq ""
        ? index($_[0], "xn--") == -1
            ? lc $_[0]
            : eval { lc URI::_idna::decode($_[0]) }
        : "";

    # Return early if domain is not well-formed:
    return unless $domain =~ $dn_re;

    # Search using the full domain and a substring consisting of its lowest
    # levels:
    return _find_rule($domain);
}

my %rules = qw();

# Right-hand side of a domain name:
sub _rhs {
    my ($domain) = @_;
    return substr($domain, index($domain, ".") + 1);
}

sub _find_rule {
    my ($domain) = @_;
    my $rhs = _rhs($domain);
    my $rule = $rules{$domain};

    return do {
        # Test for rule match with full domain:
        if (defined $rule) {
            # An identity rule match means the full domain is the public suffix:
            if ( $rule eq "i" ) { $domain } # return undef in scalar context

            # If a wilcard rule matches the full domain, fail out:
            elsif ( $rule eq "w" ) { () }

            # An exception rule means the right-hand side is the public suffix:
            else { $rhs }
        }

        # Fail if no match found and the full domain and right-hand side are
        # identical:
        elsif ( $domain eq $rhs ) { () } # return undef in scalar context

        # No match found with the full domain, but there are more levels of the
        # domain to check:
        else {
            my $rrule = $rules{$rhs};

            # Test for rule match with right-hand side:
            if (defined $rrule) {

                # If a wildcard rule matches the right-hand side, the full
                # domain is the public suffix:
                if ( $rrule eq "w" ) { $domain }

                # An identity rule match means it's the right-hand side:
                elsif ( $rrule eq "i" ) { $rhs }

                # An exception rule match means it's the right-hand side of the
                # right-hand side:
                else { _rhs($rhs) }
            }

            # Recurse with the right-hand side as the full domain, and the old
            # right-hand side sans its lowest domain level as the new right-hand
            # side:
            else {
                _find_rule($rhs, _rhs($rhs));
            }
        }
    }
}

1;
