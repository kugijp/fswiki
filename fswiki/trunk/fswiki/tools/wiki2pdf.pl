#!/usr/local/bin/perl
############################################################
#
# Wiki�ե����ޥåȤ���PDF���������륹����ץ�
#
############################################################
use lib "$ENV{'FSWIKI_HOME'}/lib","$ENV{'FSWIKI_HOME'}/";
use plugin::pdf::PDFParser;
use Wiki;
use Util;
use Jcode;
use Cwd;

#===========================================================
# ������­��ʤ�
#===========================================================
if($#ARGV < 1){
	die "wiki2pdf.pl sourcefile savefile\n";
}

#===========================================================
# �ѿ��ν���
#===========================================================
my $from    = $ARGV[0];
my $to      = $ARGV[1];
my $current = cwd();
chdir($ENV{'FSWIKI_HOME'});

my $url = $from;
$url =~ s/\?.*$//;
my $wiki = Wiki->new(CGI->new($url));

#===========================================================
# Wiki�����������
#===========================================================
my $source = "";
if(index($from,"http://")==0 || index($from,"https://")==0){
	# HTTP��ͳ�ǥ����������
	$source = &Util::get_response($wiki,$from);
} else {
	# ������ե����뤫�饽���������
	chdir($current);
	open(DATA,$from) or die "File Open Error :$from\n";
	while(<DATA>){
		$source .= $_;
	}
	close(DATA);
	chdir($ENV{'FSWIKI_HOME'});
}
&Jcode::convert(\$source,"euc");

#===========================================================
# PDF����
#===========================================================
my $parser = plugin::pdf::PDFParser->new($wiki,$from);
$parser->parse($source);

chdir($current);
$parser->save_file($to);

#===========================================================
# CGI.pm�Υ�å����֥�������
#===========================================================
package CGI;

sub new {
	my $class = shift;
	my $self  = {};
	$self->{url} = shift;
	return bless $self, $class;
}

sub url {
	my $self = shift;
	return $self;
}

sub get_session {
	return undef;
}
