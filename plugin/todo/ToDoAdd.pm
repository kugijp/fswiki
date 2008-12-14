############################################################
# 
# <p>ToDo�ꥹ�Ȥ˹��ܤ��ɲä��뤿��Υե��������Ϥ��ޤ���</p>
# <pre>
# {{todoadd ToDo(ToDo�򵭽Ҥ����ڡ�������ά��)}}
# </pre>
# <p>
#   �ե�����˵��������ɲä򲡤��ȡ�ToDo�ꥹ���Ѥι��ܤ��ɲä���ޤ���
#   �ڡ���̾���ά�������ϡ����ιԤ������ɲä��ޤ���
#   �ڡ���̾����ꤷ�����ϡ����ꤷ���ڡ����κǸ���ɲä��ޤ���
# </p>
# 
############################################################
package plugin::todo::ToDoAdd;
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
# ToDo�ꥹ���ɲåե�����
#===========================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $dist = shift;
	my $cgi = $wiki->get_CGI;
	my $page = $cgi->param("page");
	
	if($page eq ""){
		return "";
	}
	
	if($dist eq ""){
		$dist = $page;
	} elsif(not $wiki->page_exists($dist)){
		return &Util::paragraph_error("$dist��¸�ߤ��ޤ���");
	}
	
	return "<form method=\"post\" action=\"".$wiki->create_url()."\">\n".
	       "ͥ���١�<input type=\"text\" name=\"priority\" size=\"3\"> ".
	       "��ư��<input type=\"text\" name=\"dothing\" size=\"40\"> ".
	       "<input type=\"submit\" value=\"�ɲ�\">\n".
	       "<input type=\"hidden\" name=\"action\" value=\"ADD_TODO\">\n".
	       "<input type=\"hidden\" name=\"page\" value=\"".Util::escapeHTML($page)."\">\n".
	       "<input type=\"hidden\" name=\"dist\" value=\"".Util::escapeHTML($dist)."\">\n".
	       "</form>";
}

1;
