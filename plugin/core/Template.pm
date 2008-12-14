############################################################
#
# �ƥ�ץ졼�Ȥ����򤹤륳��ܤ�ɽ������ץ饰����
#
############################################################
package plugin::core::Template;
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
# �إ�פ�ɽ�����ޤ���
#===========================================================
sub editform {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	my $page = $cgi->param("page");
	
	# ɽ������ΤϿ����������Τ�
	if($wiki->page_exists($page)){
		return "";
	}
	
	my $tmpl = $cgi->param("template");
	my $buf = "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
	          "  �ƥ�ץ졼��\n".
	          "  <select name=\"template\">\n";
	
	my $count = 0;
	
	foreach($wiki->get_page_list({-permit=>'show'})){
		if(index($_,"Template/")==0){
			$buf .= "    <option value=\"".&Util::escapeHTML($_)."\"";
			if($_ eq $tmpl){ $buf .= " selected"; }
			$buf .= ">".&Util::escapeHTML($_)."</option>\n";
			$count++;
		}
	}
	
	# �ƥ�ץ졼�Ȥ�¸�ߤ��ʤ��ä����
	if($count==0){
		return "";
	}
	
	$buf .= "  </select>\n".
	        "  <input type=\"submit\" name=\"\" value=\"�ɹ���\">\n".
	        "  <input type=\"hidden\" name=\"action\" value=\"EDIT\">\n".
	        "  <input type=\"hidden\" name=\"page\" value=\"".&Util::escapeHTML($cgi->param("page"))."\">\n".
	        "</form>\n";
	
	return $buf;
}

1;
