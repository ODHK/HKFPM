#!/usr/bin/perl

use strict;
use Data::Dumper;
use OpenRice;

#
# Initialize the stop word list
#
&add_stopwords_from_file("stopwords.txt");

#
# Initialize a user agent
#
my $useragent = LWP::UserAgent->new;

#
# District IDs in OpenRice
#
my $districts = {
    1007 => "Shek O",
    1019 => "Causeway Bay",
};

my $district=1007;

#
# Getting comments from all restaurants in a district
#
foreach my $shop (&get_shops_in_district($district, 1)) {
    &get_comments($shop, 1);
}

#
# Getting comments for a particular restaurant
#
# &get_comments(50330, 1);

#
# Log the acquired data
#
print Dumper &comments;

#
# Push the data to the server
#
# (not working right now, so die before that).
#
die;
foreach my $c (&comments) {
    if ($c->{stopwords} > 0) {
	$useragent->post("http://graham-leach.com/HKFPM/report-3.php", {
	    openrice_shopid => $c->{shopid},
	    openrice_commentid => $c->{commentid},
	    name => $c->{shopname},
	    address => $c->{shopaddress},
	    notes => 'test',
			 });
    }
}



