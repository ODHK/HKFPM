#!/usr/bin/perl

use strict;
use Data::Dumper;
use OpenRice;


my $useragent = LWP::UserAgent->new;

my $district=1007;#1019;

&add_stopwords_from_file("stopwords.txt");

# foreach my $shop (&get_shops_in_district($district, 1)) {
#     &get_comments($shop, 1);
# }

&get_comments(50330, 1);

print Dumper &comments;

die;
foreach my $c (&comments) {
    if ($c->{stopwords}) {# > 0) {
	$useragent->post("http://graham-leach.com/HKFPM/report-3.php", {
	    openrice_shopid => $c->{shopid},
	    openrice_commentid => $c->{commentid},
	    name => $c->{shopname},
	    address => $c->{shopaddress},
	    notes => 'test',
			 });
    }
}



