package Lyrics::Fetcher::Google;
use strict;
use Net::Google;
use LWP::UserAgent;
use HTML::LinkExtractor;
use String::Similarity;

my $Lyrics::Fetcher::Google::VERSION = '0.01';

my ($class) = @_;
my $ua = new LWP::UserAgent;
my $lx = new HTML::LinkExtractor;
$Lyrics::Fetcher::Error = 'OK';


sub fetch($$$) {
  my $self = shift;
  my ($artist, $song) = @_;
  my @links = &links($artist, $song);

  $Lyrics::Fetcher::Error = "Could not get any results from google. Did you supply a gid?" unless (@links);

  my $totaltext;

  foreach my $link (@links) {
    $totaltext.=&get($link);
  }
  my @biggest = &biggest_blocks($totaltext, 3);
  my %songs = &most_similar(@biggest);

  #@results contains multiple entries. Only the first(highest weighted) entry is returned.
  my @results = sort { $songs{$b} <=> $songs{$a} } keys %songs;
  $results[1].="AASDFASD";
  return shift(@results); 
}

sub links {
  my ($artist, $song) = @_;
  my $google = Net::Google->new(key=>$Lyrics::Fetcher::gid);
  my $search = $google->search();
  $search->max_results(5);
  $search->query($artist,$song,'lyrics');
  return map { $_ = $_->{__URL}} @{$search->results()};
}


sub links_unethical {
  my ($artist,$song) = @_;
  $ua->agent("Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.6) Gecko/20040206 Firefox/0.8");
  $lx->parse(\&get("http://www.google.com/search?hl=en&lr=&ie=UTF-8&q=lyrics+%22$artist%22%20%22$song%22&btnG=Search"));
    my @links;
    foreach my $link (@{$lx->links}) {
      if ($link->{href}) {
        if ($link->{href} !~ /(google|cache)/i) {
          if ($link->{href} !~ /^\//) {
            push(@links,$link->{href});
          }
        }
      }
    }
    return @links;
}

sub get {
  my ($url) = @_;
  $ua->timeout(6);
  $ua->agent("Mozilla/5.0");
  my $res = $ua->get($url);
  if ($res->is_success) {
    return $res->content;
  }
}

sub biggest_blocks {
  my ($html, $num) = @_;
  $html =~ s/<script.*?>.*?<\/script>//sig;
  $html =~ s/<body.*?>(.*)?<\/body>/$1/sig;
  $html =~ s/{(.*)?}/$1/sig;
  $html =~ s/<\!--[^>]*//sig;
  $html =~ s/<\s*?(p|br|i|b|a)\s*.*?>//sig;
  my @blocks = split(/<.*?>/, $html);
  @blocks = sort { length $b <=> length $a } @blocks;
  @blocks = splice(@blocks,0,$num);
  return @blocks;
}

sub most_similar {
  my (@strings) = @_;
  my %rank;
  foreach my $outside (@strings) {
    foreach my $inside (@strings) {
      $rank{$outside} += similarity($outside, $inside);
    }
  }
  return %rank;
}


1;

=pod

=head1 NAME

Lyrics::Fetcher::Google - Get some lyrics. Maybe.


=head1 SYNOPSIS

  use Lyrics::Fetcher;

  $Lyrics::Fetcher::gid = '<your google API id>';

  print Lyrics::Fetcher->fetch("<artist>","<song>","Google");


=head1 DESCRIPTION

This module tries to find lyrics on the web.
Sometimes it works. But it probably won't.

It searches google for an initial set. It then
finds the largest block of plain text in the top
5 results. Those results are then compared to
one another and weighted. The idea being that
a large block of text on one site may be a bunch
of poo, but a large area of similar text on multiple
sites most likely is the lyrics for which you are
looking.


=head1 BUGS

Yes. I would be happy to hear that this worked for someone.
Let me know if it does. I may even respond if you let me 
know that it doesn't.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

John Lifsey <nebulous@crashed.net>

=cut

__END__


