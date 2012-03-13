package Mozilla::PublicSuffix;

use strict;
use warnings FATAL => "all";
use utf8;
use parent "Exporter";
use Carp;
use URI::_idna;

our @EXPORT_OK = qw(public_suffix);

# VERSION
# ABSTRACT: Get a domain name's "public suffix" via Mozilla's Public Suffix List

sub public_suffix {
	my $domain = lc $_[0];
	index($domain, "xn--") != -1
		and $domain = eval { URI::_idna::decode($_[0]) };

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


1;
