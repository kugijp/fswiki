###############################################################################
# 
# �ڡ���̾�Τ��ѹ����ڡ����Υ��ԡ��򤹤�ϥ�ɥ顣
# ��������rename�եå���ƤӽФ��ޤ���
# 
###############################################################################
package plugin::rename::RenameHandler;
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
	
	return $self->do_rename($wiki);
}

#==============================================================================
# ��͡����¹�
#==============================================================================
sub do_rename {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;

	my $pagename    = $cgi->param("page");
	my $newpagename = $cgi->param("newpage");
	my $do          = $cgi->param("do");
	my $time        = $wiki->get_last_modified($pagename);
	my $buf         = "";
	my $login       = $wiki->get_login_info();

	# ���顼�����å�
	if($newpagename eq ""){
		return $wiki->error("�ڡ��������ꤵ��Ƥ��ޤ���!!");
	}
	if($newpagename =~ /[\|:\[\]]/){
		return $wiki->error("�ڡ���̾�˻��ѤǤ��ʤ�ʸ�����ޤޤ�Ƥ��ޤ���");
	}
	if($wiki->page_exists($newpagename)){
		return $wiki->error("���˥�͡�����Υڡ�����¸�ߤ��ޤ�!!");
	}
	if($newpagename eq $pagename){
		return $wiki->error("Ʊ��Υڡ��������ꤵ��Ƥ��ޤ�!!");
	}
	if(!$wiki->can_modify_page($pagename) || !$wiki->can_modify_page($newpagename)){
		return $wiki->error("�ڡ������Խ��ϵ��Ĥ���Ƥ��ޤ���");
	}
	if($wiki->page_exists($pagename)){
		if($cgi->param("lastmodified") < $time){
			return $wiki->error("�ڡ����ϴ����̤Υ桼���ˤ�äƹ�������Ƥ��ޤ���");
		}
	}

	# FrontPage���ư���褦�Ȥ������ˤϥ��顼
	if($pagename eq $wiki->config("frontpage") && $do ne "copy"){
		return $wiki->error($wiki->config("frontpage")."���ư���뤳�ȤϤǤ��ޤ���");
	}

	# ���ԡ�����
	$wiki->do_hook("rename");
	my $content = $wiki->get_page($pagename);
	$wiki->save_page($newpagename,$content);
	
	# �������
	if($do eq "move"){
		$wiki->save_page($pagename,'');
	}elsif($do eq "movewm"){
		$wiki->save_page($pagename,'[['.$newpagename.']]�˰�ư���ޤ�����');
	}

	# �եå��ε�ư���ֵѥ�å�����
	if($do eq "copy"){
		$wiki->set_title($pagename."�򥳥ԡ����ޤ���");
		return Util::escapeHTML($pagename)."�򥳥ԡ����ޤ�����";
	} else {
		$wiki->set_title($pagename."���͡��ष�ޤ���");
		return Util::escapeHTML($pagename)."���͡��ष�ޤ�����";
	}
}

1;
