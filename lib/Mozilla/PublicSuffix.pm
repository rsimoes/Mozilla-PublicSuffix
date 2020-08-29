package Mozilla::PublicSuffix;

use strict;
use warnings FATAL => 'all';
use utf8;
use Exporter qw(import);
use URI::_idna;

our @EXPORT_OK = qw(public_suffix);

# VERSION
# ABSTRACT: Get a domain name's public suffix via the Mozilla Public Suffix List

my $dn_re = do {
    my $aln = '[[:alnum:]]';
    my $anh = '[[:alnum:]-]';
    my $re_str = "(?:$aln(?:(?:$anh){0,61}$aln)?"
               . "(?:\\.$aln(?:(?:$anh){0,61}$aln)?)*)";

    qr/^$re_str$/;
};
sub public_suffix {
    my $string = shift;

    # Decode domains in punycode form:
    my $domain = defined($string) && ref($string) eq ''
        ? index($string, 'xn--') == -1
            ? lc $string
            : eval { lc URI::_idna::decode($string) }
        : '';

    # Search using the full domain and a substring consisting of its lowest
    # levels, or return early (undef in scalar context) if the domain name is
    # not well-formed according to RFC 1123:
    return $domain =~ $dn_re ? _find_rule($domain) : ( );
}

my %rules = qw();

# Right-hand side of a domain name:
sub _rhs {
    my $domain = shift;
    return substr($domain, index($domain, '.') + 1);
}

sub _find_rule {
    my $domain = shift;
    my $rhs = _rhs($domain);
    my $rule = $rules{$domain};

    return do {
        # Test for rule match with full domain:
        if ( defined $rule ) {
            # An identity rule match means the full domain is the public suffix:
            if ( $rule eq 'i' ) { $domain } # return undef in scalar context

            # Fail out if a wilcard rule matches the full domain:
            elsif ( $rule eq 'w' ) { () }

            # An exception rule means the right-hand side is the public suffix:
            else { $rhs }
        }

        # Fail out if no match found and the full domain and right-hand side are
        # identical:
        elsif ( $domain eq $rhs ) { () }

        # No match found with the full domain, but there are more levels of the
        # domain to check:
        else {
            my $rrule = $rules{$rhs};

            # Test for rule match with right-hand side:
            if (defined $rrule) {

                # If a wildcard rule matches the right-hand side, the full
                # domain is the public suffix:
                if ( $rrule eq 'w' ) { $domain }

                # An identity rule match means it's the right-hand side:
                elsif ( $rrule eq 'i' ) { $rhs }

                # An exception rule match means it's the right-hand side of the
                # right-hand side:
                else { _rhs($rhs) }
            }

            # Try again with the right-hand side as the full domain:
            else {
                _find_rule($rhs);
            }
        }
    }
}

sub _parse_file {
    my $rulesref = shift;
    my $dat_file = shift;
    open DAT ,"<:encoding(UTF-8)", "$dat_file";
    foreach (<DAT>) {
        s/\s//g;
        if    ( s/^!// )        { $rulesref->{$_} = "e" }  # exception rule
        elsif ( s/^\*\.// )     { $rulesref->{$_} = "w" }  # wildcard rule
        elsif ( /^[\p{Word}]/ ) { $rulesref->{$_} = "i" }  # identity rule
    }
    close DAT;
}

1;
