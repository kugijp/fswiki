############################################################
# 
# <p>�����ե������ɽ�����ޤ���</p>
# <pre>
# {{search}}
# </pre>
# <p>�����ɥС���ɽ���������v���ץ�����Ĥ��Ƥ���������</p>
# <pre>
# {{search v}}
# </pre>
# 
############################################################
package plugin::search::SearchForm;
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
# �����ե�����
#===========================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $way  = shift;
	
	if($way eq ""){
		$way = "h";
	}
	my $buf = "<form method=\"GET\" action=\"".$wiki->create_url()."\">\n".
	          "������� <input type=\"TEXT\" name=\"word\" size=\"20\">";
	
	if($way eq "v" || $way eq "V"){
		$buf .= "<br>";
	}
	
	$buf .= "<input type=\"RADIO\" name=\"t\" value=\"and\" id=\"and\" checked><label for=\"and\">AND</label> ".
	        "<input type=\"RADIO\" name=\"t\" value=\"or\" id=\"or\"><label for=\"or\">OR</label> ";
	
	if($way eq "v" || $way eq "V"){
		$buf .= "<br>";
	}
	
	$buf .= "<input type=\"checkbox\" id=\"contents\" name=\"c\" value=\"true\">";
	$buf .= "<label for=\"contents\">�ڡ������Ƥ�ޤ��</label>\n";
	
	$buf .= "<input type=\"SUBMIT\" value=\" �� �� \">".
	        "<input type=\"HIDDEN\" name=\"action\" value=\"SEARCH\">".
	        "</form>\n";
	
	return $buf;
}

1;
