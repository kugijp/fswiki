###############################################################################
#
# PDF��������륢�������ϥ�ɥ�ʥեå��˥ץ饰����
#
###############################################################################
package plugin::pdf::PDFMaker;
use strict;
use lib '../../';
use lib '../../lib';
use plugin::pdf::PDFParser;
use URI::Escape;
#==============================================================================
# ���󥹥ȥ饯��
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# ���������ϥ�ɥ��PDF��˥塼��������
#==============================================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	$self->{dir} = $wiki->config('pdf_dir');
	my $cgi = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	if($pagename eq ""){
		$pagename = $wiki->config("frontpage");
	}
	
	# �ڡ�����¸�ߤ��뤫�����å�
	unless($wiki->page_exists($pagename)){
		return $wiki->error("�ڡ���������ޤ���");
	}
	# ���ȸ������뤫�ɤ��������å�
	unless($wiki->can_show($pagename)){
		return $wiki->error("�ڡ����λ��ȸ��¤�����ޤ���");
	}
	
	my $filename = $self->{dir}."/".&Util::url_encode($pagename).".pdf";
	
	if(!-e $filename){
		$self->make_pdf($pagename,$wiki->get_page($pagename),$wiki);
	} else {
		# �������դΥ����å�
		my $pdftime = (stat($filename))[9];
		my $wikitime = $wiki->get_last_modified($pagename);
		if($pdftime < $wikitime){
			$self->make_pdf($pagename,$wiki->get_page($pagename),$wiki);
		}
	}
	
	$pagename =~ tr|/";|-':|; # ���Ĥ��ִ������򤹤�
	
	print "Pragma: no-cache\n";
	print "Cache-Control: no-cache\n";
	print "Content-Type: application/pdf\n";
	print Util::make_content_disposition("$pagename.pdf", "inline");
	open(DATA,$filename) or die $!;
	binmode(DATA);
	while(<DATA>){
		print $_;
	}
	close(DATA);
	
	exit();
}

#==============================================================================
# �ڡ������������
#==============================================================================
sub make_pdf {
	my $self   = shift;
	my $page   = shift;
	my $source = shift;
	my $wiki   = shift;
	my $parser = plugin::pdf::PDFParser->new($wiki,$page);
	$parser->parse($source);
	$parser->save_file($self->{"dir"}."/".Util::url_encode($page).".pdf");
}

1;
