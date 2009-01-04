######################################################
#
# BugState�ץ饰�����ѤΥ��������ϥ�ɥ�Ǥ���
#
######################################################
package plugin::bugtrack::BugStateHandler;
use strict;
#=====================================================
# ���󥹥ȥ饯��
#=====================================================
sub new {
    my $class = shift;
    my $self = {};
    return bless $self,$class;
}
#=====================================================
# ���������ϥ�ɥ�
#=====================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi    = $wiki->get_CGI;
	my $source = $cgi->param("source");
	my $state  = $cgi->param("state");
	my $page   = $cgi->param("page");
	
	if($wiki->page_exists($source)){
		if(!$wiki->can_modify_page($source)){
			return $wiki->error("�ڡ������Խ��ϵ��Ĥ���Ƥ��ޤ���");
		}
		my $content = $wiki->get_page($source);
		$content =~ s/(\n\*���֡�)\s+(.*)/$1 $state/;
		$wiki->save_page($source,$content);
	}
	
	$wiki->redirect($page);
}

1;
