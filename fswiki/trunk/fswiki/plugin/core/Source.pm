###############################################################################
# 
# ��������ɽ������ץ饰����
# 
###############################################################################
package plugin::core::Source;
use strict;
#==============================================================================
# ���󥹥ȥ饯��
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# ���������μ¹�
#==============================================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	if($pagename eq ""){
		$pagename = $wiki->config("frontpage");
	}
	unless($wiki->can_show($pagename)){
		return $wiki->error("���ȸ��¤�����ޤ���");
	}
	my $gen = $cgi->param("generation");
	my $source;
	if($gen eq ''){
		$source = $wiki->get_page($pagename);
	} else {
		$source = $wiki->get_backup($pagename,$gen);
	}
	my $format = $wiki->get_edit_format();
	$source = $wiki->convert_from_fswiki($source,$format);
	
	if(&Util::handyphone()){
		print "Content-Type: text/plain;charset=Shift_JIS\n\n";
		&Jcode::convert(\$source,"sjis");
	} else {
		print "Content-Type: text/plain;charset=EUC-JP\n";
		if($ENV{"HTTP_USER_AGENT"} =~ /MSIE/){
			print Util::make_content_disposition("source.txt", "attachment");
		} else {
			print "\n";
		}
	}
	print $source;
	exit();
}

#==============================================================================
# �ڡ���ɽ�����Υեå��᥽�å�
# �֥������ץ�˥塼��ͭ���ˤ��ޤ�
#==============================================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	if($pagename eq ""){
		$pagename = $wiki->config("frontpage");
	}
	
	$wiki->add_menu("������",$wiki->create_url({ action=>"SOURCE",page=>$pagename }));
}

1;
