############################################################
#
# �Ǽ��ǥץ饰����Υ��������ϥ�ɥ顣
#
############################################################
package plugin::bbs::BBS2Handler;
use strict;
#===========================================================
# ���󥹥ȥ饯��
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# �����ν񤭹���
#===========================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $bbsname = $cgi->param("bbsname");
	my $name    = $cgi->param("name");
	my $subject = $cgi->param("subject");
	my $message = $cgi->param("message");
	my $page    = $cgi->param("page");
	my $option  = $cgi->param("option");
	
	if($name    eq ""){
		$name    = "̵̾������";
	} else {
		# fswiki_post_name�Ȥ��������ǥ��å����򥻥åȤ���
		my $path   = &Util::cookie_path($wiki);
		my $cookie = $cgi->cookie(-name=>'fswiki_post_name',-value=>Util::url_encode($name),-expires=>'+1M',-path=>$path);
		print "Set-Cookie: ",$cookie->as_string,"\n";
	}
	
	if($subject eq ""){
		$subject = "̵��";
	}
	
	if($bbsname eq ""){
		return $wiki->error("�ѥ�᡼���������Ǥ���");
	}
	if($message eq ""){
		return $wiki->error("��ʸ�����Ϥ��Ƥ���������");
	}
	
	# �ե����ޥåȥץ饰����ؤ��б�
	my $format = $wiki->get_edit_format();
	$name    = $wiki->convert_to_fswiki($name   ,$format,1);
	$subject = $wiki->convert_to_fswiki($subject,$format,1);
	$message = $wiki->convert_to_fswiki($message,$format);
	
	my $pagename = $self->get_page_name($wiki,$bbsname);
	my $content = "!![[$subject|$pagename]] - $name (".&Util::format_date(time()).")\n".
	              "$message\n";
	
	# no_comment���ץ����
	if($option eq "no_comment"){
		
	# reverse_comment���ץ����
	} elsif($option eq "reverse_comment"){
		$content .= "{{comment reverse}}\n";
	# �ǥե����
	} else {
		$content .= "{{comment}}\n";
	}
	$wiki->save_page($pagename,$content);
	
	# ���Υڡ����˥�����쥯��
	$wiki->redirect($pagename);
}

#===========================================================
# ��������ڡ���̾�����
#===========================================================
sub get_page_name {
	my $self  = shift;
	my $wiki  = shift;
	my $name  = shift;
	my $count = 0;
	my $qname = quotemeta($name);
	foreach my $pagename ($wiki->get_page_list()){
		if($pagename =~ /^BBS-$qname\/([0-9]+)$/){
			if($count < $1){
				$count = $1;
			}
		}
	}
	$count++;
	return "BBS-$name/$count";
}

1;
