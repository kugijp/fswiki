###############################################################################
#
# WikiFarm�κ����Ԥ����������ϥ�ɥ顣
# WikiFarm�������Farm��ǽ����Ѥ�������ˤʤäƤ�����Τ�ͭ���ˤʤ�ޤ���
#
###############################################################################
package plugin::core::RemoveWikiHandler;
use strict;
#==============================================================================
# ���󥹥ȥ饯��
#==============================================================================
sub new {
	my $class = shift;
	my $self  = {};
	return bless $self,$class;
}
#==============================================================================
# ���������ϥ�ɥ�᥽�å�
#==============================================================================
sub do_action {
	my $self = shift;
	my $farm = shift;
	$farm->set_title("Wiki�κ��");
	
	# ���¤Υ����å�
	my $login  = $farm->get_login_info();
	my $config = &Util::load_config_hash($farm,$farm->config('farmconf_file'));
	if($config->{remove}==1){
		if(!defined($login)){
			return $farm->error("Wiki�κ���ϵ��Ĥ���Ƥ��ޤ���");
		}
	} elsif($config->{remove}==2){
		if(!defined($login) || $login->{type}!=0){
			return $farm->error("Wiki�κ���ϵ��Ĥ���Ƥ��ޤ���");
		}
	}
	
	# Wiki��¸�ߥ����å�
	my $path = $farm->get_CGI()->param("path");
	unless($path =~ s|^/|| and $farm->wiki_exists($path)) {
		return $farm->error("Wiki��¸�ߤ��ޤ���");
	}
	
	if($farm->get_CGI()->param("exec_delete") ne ""){
		return $self->exec_remove($farm);
	} else {
		return $self->conf_remove($farm);
	}
}
#==============================================================================
# �����ǧ
#==============================================================================
sub conf_remove {
	my $self = shift;
	my $farm = shift;
	my $path = $farm->get_CGI()->param("path");
	
	return "<p><a href=\"".$farm->config('script_name')."$path\">$path</a>�������Ƥ�����Ǥ�����</p>".
	       "<form action=\"".$farm->create_url()."\" method=\"POST\">\n".
	       "  <input type=\"submit\" name=\"exec_delete\" value=\"���\">\n".
	       "  <input type=\"hidden\" name=\"action\" value=\"REMOVE_WIKI\">\n".
	       "  <input type=\"hidden\" name=\"path\" value=\"".&Util::escapeHTML($path)."\">\n".
	       "</form>\n";
}
#==============================================================================
# ����¹�
#==============================================================================
sub exec_remove {
	my $self = shift;
	my $farm = shift;
	my $path = $farm->get_CGI()->param("path");
	
	$farm->remove_wiki($path);
	return "<p>".&Util::escapeHTML($path)."�������ޤ�����</p>";
}

1;
