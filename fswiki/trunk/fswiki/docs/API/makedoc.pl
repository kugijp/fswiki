#!/usr/local/bin/perl
###############################################################################
#
# Perl�⥸�塼�뤫��API��ե���󥹤�������뤿��Υ�����ץ�
#
###############################################################################
my $file  = $ARGV[0];
my $buf   = "";
my $count = 0;

print "<html>\n";
print "<head>\n";
print "<title>Module Reference</title>\n";
print "<link rel=\"stylesheet\" type=\"text/css\" href=\"../default.css\">\n";
print "</head>\n";
print "<body>\n";

open(DATA,$file);
while(my $LINE = <DATA>){
	if($LINE =~ /^sub (.+){/){
		my $subname = $1;
		unless($subname =~ /^_/){
			print "<h2>".&escapeHTML($subname)."</h2>\n";
			print $buf;
		}
		$buf    = "";
		$count  =  0;

	} elsif($LINE =~ /package (.+);/){
		print "<h1>".&escapeHTML($1)."</h1>\n";
		print $buf;
		$buf   = "";
		$count =  0;

	} elsif($LINE =~ /^\#\#/ || $LINE=~ /^\#==/ || $LINE =~ /^\#--/){
		if($count!=0){
			$buf = "";
		}
		$count++;
		
	} elsif($LINE =~ /^\#(.+)/){
		my $comment = $1;
		if($comment =~ /^\s+</){
			$comment =~ s/^\s+//g;
		}
		$count = 0;
		$buf .= $comment."\n";
	}
}
close(DATA);

print "<div class=\"footer\">\n";
print "Generated by makedoc.pl\n";
print "</div>\n";
print "</body>\n";
print "</html>\n";

sub escapeHTML {
	my($retstr) = shift;
	my %table = (
		'&' => '&amp;',
		'"' => '&quot;',
		'<' => '&lt;',
		'>' => '&gt;',
	);
	$retstr =~ s/([&\"<>])/$table{$1}/go;
	return $retstr;
}