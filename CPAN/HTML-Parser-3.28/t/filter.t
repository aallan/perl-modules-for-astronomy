print "1..2\n";

my $HTML = <<EOT;

<!DOCTYPE HTML>
<!-- comment
<h1>Foo</h1>
-->

<H1
>Bar</H1
>

<Table><tr><td>1<td>2<td>3
<tr>
</table>

<?process>

EOT

use HTML::Filter;
use SelectSaver;

my $tmpfile = "test-$$.htm";
die "$tmpfile already exists" if -e $tmpfile;

open(HTML, ">$tmpfile") or die "$!";

{
    my $save = new SelectSaver(HTML);
    HTML::Filter->new->parse($HTML)->eof;
}
close(HTML);

open(HTML, $tmpfile) or die "$!";
local($/) = undef;
my $FILTERED = <HTML>;
close(HTML);

#print $FILTERED;
print "not " unless $FILTERED eq $HTML;
print "ok 1\n";

{
    package MyFilter;
    @ISA=qw(HTML::Filter);
    sub comment {}
    sub output { push(@{$_[0]->{fhtml}}, $_[1]) }
    sub filtered_html { join("", @{$_[0]->{fhtml}}) }
}

my $f2 = MyFilter->new->parse_file($tmpfile)->filtered_html;
unlink($tmpfile) or warn "Can't unlink $tmpfile: $!";

#print $f2;

print "not " unless $f2 !~ /Foo/ && $f2 =~ /Bar/;
print "ok 2\n";


