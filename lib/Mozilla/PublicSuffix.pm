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
	my $domain = lc $_[0];
	index($domain, "xn--") != -1
		and $domain = eval { URI::_idna::decode($_[0]) };
	# Test domain well-formedness:
	$domain =~ $dn_re
		or croak("Argument passed is not a well-formed domain name");
	return _find_rule($domain, substr($domain, index($domain, ".") + 1 ) ) }

my %rules = qw();
sub _find_rule {
	my ($domain, $rhs) = @_;
	my $drule = $rules{$domain};
	return defined $drule       # Test for rule with full domain
		? $drule eq "w"
			? undef             # Wildcard rules need an extra level.
			: $domain
		: $domain eq $rhs
			? undef
			: do {
				my $rrule = $rules{$rhs};
				defined $rrule  # Test for rule with right-hand side
					? $rrule eq "w"
						? $domain
						: $rhs
					: _find_rule($rhs, substr($rhs, index($rhs, ".") + 1 ) ) } }

1;
