print "1..6\n";

my $filename = "file$$.htm";
die "$filename is already there" if -e $filename;
open(FILE, ">$filename") || die "Can't create $filename: $!";
print FILE <<'EOT'; close(FILE);
<title>Heisan</title>
EOT

my $testno = 1;

{
    package MyParser;
    require HTML::Parser;
    @ISA=qw(HTML::Parser);

    sub start
    {
	my($self, $tag, $attr) = @_;
	print "not " unless $tag eq "title";
	print "ok $testno\n";
	$testno++;
    }
}

MyParser->new->parse_file($filename);
open(FILE, $filename) || die;
MyParser->new->parse_file(*FILE);
seek(FILE, 0, 0) || die;
MyParser->new->parse_file(\*FILE);
close(FILE);

require IO::File;
my $io = IO::File->new($filename) || die;
MyParser->new->parse_file($io);
$io->seek(0, 0) || die;
MyParser->new->parse_file(*$io);

my $text = '';
$io->seek(0, 0) || die;
MyParser->new(
    start_h => [ sub{ shift->eof; }, "self" ],
    text_h =>  [ sub{ $text = shift; }, "text" ])->parse_file(*$io);
print "not " if $text;
print "ok $testno\n";
$testno++;

close($io);  # needed because of bug in perl
undef($io);

unlink($filename) or warn "Can't unlink $filename: $!";
