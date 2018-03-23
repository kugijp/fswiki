###############################################################################
#
# ��Wiki��������ޤ���
# WikiFarm�������Farm��ǽ����Ѥ�������ˤʤäƤ�����Τ�ͭ���ˤʤ�ޤ���
#
###############################################################################
package plugin::core::CreateWikiHandler;
use strict;
use HTTP::Status;
use plugin::core::WikiList;
#==============================================================================
# ���󥹥ȥ饯��
#==============================================================================
sub new {
	my $class = shift;
	my $self  = {};
	return bless $self,$class;
}

#==============================================================================
# ���������ϥ�ɥ�
#==============================================================================
sub do_action{
	my $self  = shift;
	my $farm  = shift;
	my $cgi   = $farm->get_CGI;
	my $child = $cgi->param("child");
	my $admin_id   = $cgi->param("admin_id");
	my $admin_pass = $cgi->param("admin_pass");
	
	my $can_create = 1;
	
	my $config = &Util::load_config_hash($farm,$farm->config('farmconf_file'));
	my $login  = $farm->get_login_info();
	if($config->{create}==1){
		if(!defined($login)){
			$can_create = 0;
			#return $farm->error(RC_FORBIDDEN, "Wiki�κ����ϵ��Ĥ���Ƥ��ޤ���");
		}
	} elsif($config->{create}==2){
		if(!defined($login) || $login->{type}!=0){
			$can_create = 0;
			#return $farm->error(RC_FORBIDDEN, "Wiki�κ����ϵ��Ĥ���Ƥ��ޤ���");
		}
	}
	
	if($child eq ""){
		# ��Wiki��̾�����ϥե�����
		$farm->set_title("WikiFarm",1);
		my $buf = "";
		
		if($can_create==1){
			$buf = "<h2>����Wiki�κ���</h2>\n".
			       "<form method=\"post\" action=\"".$farm->create_url()."\">\n".
			       "  <h3>Wiki��̾��</h3>\n".
			       "  <p>���������ꤷ��Wiki̾��URL�˴ޤޤ�ޤ��ΤǤ���Wiki����ħ��ɽ������".
			       "     �Ǥ������û��̾����Ĥ��뤳�Ȥ򥪥����ᤷ�ޤ���".
			       "     Ⱦ�ѱѿ����������ѤǤ��ޤ���</p>\n".
			       "  <p>Wiki̾��<input type=\"text\" name=\"child\" size=\"40\"></p>".
			       "  <h3>�����Ԥξ���</h3>\n".
			       "  <p>��������Wiki�δ�����ID�ȥѥ���ɤ����ꤷ�Ƥ���������".
			       "     Ⱦ�ѱѿ����������ѤǤ��ޤ���</p>\n".
			       "  <p>ID��<input type=\"text\" size=\"20\" name=\"admin_id\">\n".
			       "     Pass��<input type=\"password\" size=\"20\" name=\"admin_pass\">\n".
			       "  </p>\n".
			       "  <input type=\"submit\" value=\" ���� \">".
			       "  <input type=\"hidden\" name=\"action\" value=\"CREATE_WIKI\">".
			       "</form>\n";
		}
		
		# ��Wiki�ΰ���
		my $wikilist = plugin::core::WikiList->new();
		my $listcnt  = $wikilist->paragraph($farm);
		
		$buf .= "<h2>Wiki�����Ȥΰ���</h2>\n";
		
		if($listcnt eq "<ul>\n</ul>\n"){
			$buf .= "<p>���ߤ���Wiki�۲��ˤ�Wiki�����ȤϤ���ޤ���</p>";
		} else {
			$buf .= "<p>���ߤ���Wiki���۲��ˤϰʲ���Wiki�����Ȥ�¸�ߤ��ޤ���</p>".$listcnt;
		}
		
		return $buf;
		
	}else{
		if($can_create==0){
			return $farm->error(RC_FORBIDDEN, "Wiki�κ����ϵ��Ĥ���Ƥ��ޤ���");
		}
		
		# ���ϥ����å�
		if(!($child =~ /^[A-Za-z0-9]+$/)){
			return $farm->error(RC_BAD_REQUEST, &Util::escapeHTML($child)."��������̾�ΤǤ���");
		
		} elsif($admin_id eq ""){
			return $farm->error(RC_BAD_REQUEST, "������ID�����Ϥ��Ƥ���������");
			
		} elsif($admin_pass eq ""){
			return $farm->error(RC_BAD_REQUEST, "�����ԥѥ���ɤ����Ϥ��Ƥ���������");
			
		} elsif(!($admin_id =~ /^[A-Za-z0-9]+$/)){
			return $farm->error(RC_BAD_REQUEST, "������ID�������Ǥ���");
		
		} elsif(!($admin_pass =~ /^[A-Za-z0-9]+$/)){
			return $farm->error(RC_BAD_REQUEST, "�����ԥѥ���ɤ������Ǥ���");
		
		# ��Wiki�ν�ʣ������å�
		} elsif($farm->wiki_exists($child)){
			return $farm->error(&Util::escapeHTML($child)."�ϴ���¸�ߤ��ޤ���");
		
		# �桼���ν�ʣ������å�
		#} elsif($farm->user_exists($admin_id)){
		#	return $farm->error("ID��".&Util::escapeHTML($admin_id)."�Υ桼���ϴ���¸�ߤ��ޤ���");
			
		# ��Wiki����
		} else {
			$farm->create_wiki($child,$admin_id,$admin_pass);
			$farm->set_title(&Util::escapeHTML($child)."��������ޤ���");
			return "<a href=\"".$farm->config('script_name')."/".&Util::escapeHTML($child)."\">".
			       &Util::escapeHTML($child)."</a>��������ޤ�����";
		}
	}
}

1;
