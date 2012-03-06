package Mozilla::PublicSuffix;

use strict;
use warnings FATAL => "all";
use utf8;
use parent "Exporter";

our @EXPORT_OK = qw(public_suffix);

# VERSION
# ABSTRACT: Get a domain name's "public suffix" via Mozilla's Public Suffix List

my %rules = qw();
sub public_suffix {
    my ($domain) = @_;

    # Test domain well-formedness:
    return undef if !$domain || ! eval {
	use Net::LibIDN qw(idn_prep_name idn_to_ascii idn_to_unicode);
	$domain = idn_to_unicode idn_to_ascii idn_prep_name $domain };

    # Gather matching rules:
    my @labels = split /\./, $domain;
    my @matches;
    for my $i ( 0 .. $#labels) {
	my $label = join ".", @labels[ $i .. $#labels ];
	exists $rules{$label} and push @matches, { type  => $rules{$label},
						   label => $label }; }
    @matches = sort { $b->{label} =~ /\./g <=> $a->{label} =~ /\./g } @matches;

    # Choose prevailing rule and return suffix, if one is to be found:
    return do {
	@matches == 0
	    ? undef
	    : do {
		my @exc_rules = grep { $_->{type} eq "e" } @matches;
		@exc_rules > 0
		    ? do {
			@exc_rules == 1
			    ? undef
			    : do {
				# Recheck domain with label trimmed off
				@_ = $exc_rules[0]{label} =~ /^[^.]+\.(.*)$/;
				goto &public_suffix; } }
		    : do {
			my ($type, $label) = @{$matches[0]}{qw(type label)};
			$type eq "w" and
			($label) = $domain =~ /((?:[^.]+\.)$label)$/;
			$label ||= undef; } } }; }


# Definitions

# - The Public Suffix List consists of a series of lines, separated by \n.
# - Each line is only read up to the first whitespace; entire lines can also be
#   commented using //.
# - Each line which is not entirely whitespace or begins with a comment contains
#   a rule.
# - A rule may begin with a "!" (exclamation mark). If it does, it is labelled
#   as a "exception rule" and then treated as if the exclamation mark is not
#   present.
# - A domain or rule can be split into a list of labels using the separator "."
#   (dot). The separator is not part of any of the labels.
# - A domain is said to match a rule if, when the domain and rule are both
#   split, and one compares the labels from the rule to the labels from the
#   domain, beginning at the right hand end, one finds that for every pair
#   either they are identical, or that the label from the rule is "*" (star).
# - The domain may legitimately have labels remaining at the end of this
#   matching process.

# Algorithm

# - Match domain against all rules and take note of the matching ones.
# - If no rules match, the prevailing rule is "*".
# - If more than one rule matches, the prevailing rule is the one which is an
#   exception rule.
# - If there is no matching exception rule, the prevailing rule is the one with
#   the most labels.
# - If the prevailing rule is a exception rule, modify it by removing the
#   leftmost label.
# - The public suffix is the set of labels from the domain which directly
#   match the labels of the prevailing rule (joined by dots).
# - The registered or registrable domain is the public suffix plus one
#   additional label.

1;
