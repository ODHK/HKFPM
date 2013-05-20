use strict;
use LWP::UserAgent;

my $useragent = LWP::UserAgent->new;
my $shops = {};
my $comments = {};
my $districts = {};
my %stopwords;
my $swre;

sub shops { return $shops; }
sub comments { return $comments; }

sub get_shops_in_district {
    my ($district, $page) = @_;
    if (exists $districts->{$district}{$page}) {
	return;
    }
    $districts->{$district}{$page}++;

    my $url = 'http://www.openrice.com/english/restaurant/sr1.htm?district_id='.$district.'&inputcategory=all&page='.$page;
    my $response = $useragent->get($url);
    my $content = $response->content;

    my %shopids = map { $_, 1 } $content =~ /shopid=(\d+)/ig;
    my @shops = keys %shopids;

    my %pages = map { $_, 1 } $content =~ /page\=(\d+)/ig;
    if (%pages) {
	foreach my $p (sort keys %pages) {
	    unless (exists $districts->{$district}{$p}) {
		push @shops, &get_shops_in_district($district, $p);
	    }
	}
    }
    return @shops;
}


sub add_stopwords_from_file {
    my ($stopwordlist) = @_;
    open SWL, "< $stopwordlist";
    while (<SWL>) {
	chomp;
	$stopwords{$_}++;
    }
    close SWL;
    $swre = '(?:' . join('|', keys(%stopwords)) . ')';
}


sub get_comments {
    my ($shopid, $page) = @_;
    if (exists $shops->{$shopid}{$page}) {
	return;
    }
    $shops->{$shopid}{$page}++;

    my $url='http://www.openrice.com/restaurant/reviews.htm?shopid='.$shopid.'&reviewlang=en%2chk&mode=detail&page='.$page;
    my $response = $useragent->get($url);
    my $content = $response->content;
    
    my $shopname = &get_shopname($content, $shopid);

    my @page_comments;
    while (my @list = $content =~ /^(.*?)<a href=\"\/restaurant\/commentdetail\.htm\?commentid\=(\d*?)\"\>\w*(.*?)\w*\<\/a\>(.*?)$/si) {
	my ($prefix, $id, $title, $suffix) = ($1, $2, $3, $4);
	$title =~ s/<.*?>//sig;
	if (@page_comments) {
	    &add_to_comment($page_comments[-1], $prefix);
	}
	$comments->{$id} = {
	    shopid => $shopid,
	    commentid => $id,
	    title => $title,
	    shopname => $shopname,
	    shopaddress => '',
	};
	push @page_comments, $comments->{$id};
	$content = $suffix;
    }
    my @contents = split /page\=/, $content;
    if (@contents) {
	if (@page_comments) {
	    &add_to_comment($page_comments[-1], shift @contents);
	}
	my @pages = map { /^(\d+).*$/ } @contents;
	foreach my $p (@pages) {
	    unless (exists $shops->{$shopid}{$p}) {
		&get_comments($shopid, $p);
	    }
	}
    }
}

sub get_shopname {
    my ($text, $shopid) = @_;
    $text =~ /<a.*?\?shopid=$shopid\".*?>(.*?)<\/a>/ig;
    my $name1 = $1;
    $text =~ /<a.*?\?shopid=$shopid\".*?>(.*?)<\/a>/ig;
    my $name2 = $1;
    return "$name1 $name2";
}


sub add_to_comment {
    my ($comment, $text) = @_;
    $comment->{body} = &strip_tags($text);
    $comment->{emotes} = &get_emotes($text);
    
    $comment->{body} =~ /^\w*(\d\d\d\d\-\d\d\-\d\d)/;
    $comment->{date} = $1;

    my %swc = map { $_, 1 } $comment->{body} =~ /$swre/sig;
    $comment->{stopwords} = join(',', keys %swc);
}

sub strip_tags {
    my ($text) = @_;
    $text =~ s/^(.*?)\<div\w+class\=\"PT5\"/$1/si;
    $text =~ s/\/\/alert\(.*?\)\;//sig;
    $text =~ s/<.*?>//sig;
    $text =~ s/\t\n\r\w/ /sig;
    $text =~ s/ +/ /sig;
    return $text;
}

sub get_emotes {
    my ($text) = @_;
    my $hash = {};
    foreach my $e ($text =~ /\<img.*?\/images\/Forum_icons.*?alt\=[\'\"](.*?)[\'\"]/sig) {
	$hash->{$e}++;
    }
    return $hash;
}


1;
