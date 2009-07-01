################################################################################
#
# <p>�Х���ݡ��Ȥ���Ƥ��뤿��Υե������ɽ�����ޤ���</p>
# <p>
#   �����Ȥ��ƥץ�������̾����ӥХ��Υ��ƥ������ꤷ�ޤ���
# </p>
# <pre>
# {{bugtrack �ץ�������̾,���ƥ��꣱,���ƥ��ꣲ...}}
# </pre>
# <p>
#   ���Υե����फ��Х���ݡ��Ȥ���Ƥ����
# </p>
# <pre>
# BugTrack-�ץ�������̾/�ֹ�
# </pre>
# <p>
#   �Ȥ���̾���Υڡ�������������ޤ���
#   ��Ͽ�ѤߤΥХ���ݡ��Ȥξ��֤��ѹ�������ϡ��Х���ݡ��Ȥ�ľ���Խ�����
#   ���֤����ơס����סִ�λ�ס֥�꡼���ѡס���α�סֵѲ��פΤ����줫��
#   �񤭴����Ƥ���������
# </p>
# 
################################################################################
package plugin::bugtrack::BugTrack;
use strict;
#===============================================================================
# ���󥹥ȥ饯��
#===============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===============================================================================
# �ѥ饰���
#===============================================================================
sub paragraph {
	my $self     = shift;
	my $wiki     = shift;
	my $project  = shift;
	my @category = @_;
	my $cgi      = $wiki->get_CGI();
	
	if($project eq ""){
		return &Util::paragraph_error("�ץ�������̾�����ꤵ��Ƥ��ޤ���");
	}
	if($#category == -1){
		return &Util::paragraph_error("���ƥ��꤬���ꤵ��Ƥ��ޤ���");
	}
	
	my $template = HTML::Template->new(filename=>$wiki->config('tmpl_dir')."/bugtrack.tmpl",
	                                   die_on_bad_params => 0);
	
	my @priority = ("�۵�","����","����","��");
	my @status   = ("���","���","��λ","��꡼����","��α","�Ѳ�");
	
	$template->param(PRIORITY => &make_array_ref(@priority));
	$template->param(STATUS   => &make_array_ref(@status));
	$template->param(CATEGORY => &make_array_ref(@category));
	
	# ̾�������
	my $name = Util::url_decode($cgi->cookie(-name=>'fswiki_post_name'));
	if($name eq ''){
		my $login = $wiki->get_login_info();
		if(defined($login)){
			$name = $login->{id};
		}
	}
	$template->param(NAME=>$name);
	
	my $buf = "<form action=\"".$wiki->create_url()."\" method=\"post\">\n".
	          $template->output().
	          "<input type=\"hidden\" name=\"action\" value=\"BUG_POST\">\n".
	          "<input type=\"hidden\" name=\"project\" value=\"".&Util::escapeHTML($project)."\">\n".
	          "</form>\n";
	
	return $buf;
}

#===============================================================================
# ������ܤ������ե���󥹤����
#===============================================================================
sub make_array_ref {
	my @array    = @_;
	my $arrayref = [];
	foreach(@array){
		push(@$arrayref,{NAME=>$_,VALUE=>$_});
	}
	return $arrayref;
}


1;
