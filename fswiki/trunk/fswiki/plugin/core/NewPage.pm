############################################################
# 
# �ڡ��������ѥե������ɽ������ץ饰����
# 
############################################################
package plugin::core::NewPage;
#use strict;
#===========================================================
# ���󥹥ȥ饯��
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# ���������μ¹�
#===========================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi = $wiki->get_CGI;
	
	if($wiki->config('accept_edit')==0 && !defined($wiki->get_login_info())){
		return $wiki->error("�ڡ����κ����ϵ��Ĥ���Ƥ��ޤ���");
	}
	
	$wiki->set_title("��������",1);
	
	return "<form method=\"post\" action=\"".$wiki->create_url()."\">\n".
	       "  <input type=\"text\" name=\"page\" size=\"40\">".
	       "  <input type=\"submit\" value=\" ���� \">".
	       "  <input type=\"hidden\" name=\"action\" value=\"EDIT\">".
	       "</form>\n";
}

1;
