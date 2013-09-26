#!/usr/bin/env perl

use strict;
use warnings FATAL => "all";
use Test::More tests => 65;
use Mozilla::PublicSuffix "public_suffix";

# obviously invalid input.
is public_suffix(undef), undef;
is public_suffix(""), undef;
is public_suffix([]), undef;

# Mixed case.
is public_suffix("COM"), "com";
is public_suffix("example.COM"), "com";
is public_suffix("WwW.example.COM"), "com";
# Leading dot.
is public_suffix(".com"), undef;
is public_suffix(".example"), undef;
is public_suffix(".example.com"), undef;
is public_suffix(".example.example"), undef;
# Unlisted TLD.
is public_suffix("example"), undef;
is public_suffix("example.example"), undef;
is public_suffix("b.example.example"), undef;
is public_suffix("a.b.example.example"), undef;
# Listed, but non-Internet, TLD.
is public_suffix("local"), undef;
is public_suffix("example.local"), undef;
is public_suffix("b.example.local"), undef;
is public_suffix("a.b.example.local"), undef;
# TLD with only 1 rule.
is public_suffix("biz"), "biz";
is public_suffix("domain.biz"), "biz";
is public_suffix("b.domain.biz"), "biz";
is public_suffix("a.b.domain.biz"), "biz";
# TLD with some 2-level rules.
is public_suffix("com"), "com";
is public_suffix("example.com"), "com";
is public_suffix("b.example.com"), "com";
is public_suffix("a.b.example.com"), "com";
is public_suffix("uk.com"), "uk.com";
is public_suffix("example.uk.com"), "uk.com";
is public_suffix("b.example.uk.com"), "uk.com";
is public_suffix("a.b.example.uk.com"), "uk.com";
is public_suffix("test.ac"), "ac";
# TLD with only 1 (wildcard) rule.
is public_suffix("cy"), undef;
is public_suffix("c.cy"), "c.cy";
is public_suffix("b.c.cy"), "c.cy";
is public_suffix("a.b.c.cy"), "c.cy";
# More complex TLD.
is public_suffix("jp"), "jp";
is public_suffix("test.jp"), "jp";
is public_suffix("www.test.jp"), "jp";
is public_suffix("ac.jp"), "ac.jp";
is public_suffix("test.ac.jp"), "ac.jp";
is public_suffix("www.test.ac.jp"), "ac.jp";
is public_suffix("kyoto.jp"), "kyoto.jp";
is public_suffix("c.kyoto.jp"), "kyoto.jp";
is public_suffix("b.c.kyoto.jp"), "kyoto.jp";
is public_suffix("a.b.c.kyoto.jp"), "kyoto.jp";
is public_suffix("ayabe.kyoto.jp"), "ayabe.kyoto.jp";
is public_suffix("test.kobe.jp"), "test.kobe.jp";     # Wildcard rule.
is public_suffix("www.test.kobe.jp"), "test.kobe.jp"; # Wildcard rule.
is public_suffix("city.kobe.jp"), "kobe.jp";          # Exception rule.
is public_suffix("www.city.kobe.jp"), "kobe.jp";      # Identity rule.
# TLD with a wildcard rule and exceptions.
is public_suffix("ck"), undef;
is public_suffix("test.ck"), "test.ck";
is public_suffix("b.test.ck"), "test.ck";
is public_suffix("a.b.test.ck"), "test.ck";
is public_suffix("www.ck"), "ck";
is public_suffix("www.www.ck"), "ck";
# US K12.
is public_suffix("us"), "us";
is public_suffix("test.us"), "us";
is public_suffix("www.test.us"), "us";
is public_suffix("ak.us"), "ak.us";
is public_suffix("test.ak.us"), "ak.us";
is public_suffix("www.test.ak.us"), "ak.us";
is public_suffix("k12.ak.us"), "k12.ak.us";
is public_suffix("test.k12.ak.us"), "k12.ak.us";
is public_suffix("www.test.k12.ak.us"), "k12.ak.us";
