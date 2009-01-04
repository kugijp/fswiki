############################################################
#
# �ڡ�����̾�Τ��ѹ����뤿��Υե��������Ϥ��ޤ���
#
############################################################
package plugin::rename::RenameForm;
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
# �إ�פ�ɽ�����ޤ���
#===========================================================
sub editform {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI();
	my $page = $cgi->param("page");
	
	# �ڡ�����¸�ߤ���������ե������ɽ��
	if($wiki->page_exists($page)){
		my $time = $wiki->get_last_modified($page);
		return "<h2>��͡��ࡦ���ԡ�</h2>".
		       "<form method=\"post\" action=\"".$wiki->create_url()."\">\n".
		       "  <input type=\"text\" name=\"newpage\" size=\"40\" value=\"".&Util::escapeHTML($page)."\">\n".
		       "  <br>\n".
		       "  <input type=\"radio\"  id=\"do_move\" name=\"do\" value=\"move\" checked><label for=\"do_move\">��͡���</label>\n".
		       "  <input type=\"radio\"  id=\"do_movewm\" name=\"do\" value=\"movewm\"><label for=\"do_movewm\">��å�������Ĥ��ƥ�͡���</label>\n".
		       "  <input type=\"radio\"  id=\"do_copy\" name=\"do\" value=\"copy\"><label for=\"do_copy\">���ԡ�</label>\n".
		       "  <input type=\"submit\" name=\"execute_rename\" value=\" �¹� \">\n".
		       "  <input type=\"hidden\" name=\"action\" value=\"RENAME\">".
		       "  <input type=\"hidden\" name=\"lastmodified\" value=\"".&Util::escapeHTML($time)."\">\n".
		       "  <input type=\"hidden\" name=\"page\" value=\"".&Util::escapeHTML($page)."\">".
		       "</form>\n";
	}
}

1;
