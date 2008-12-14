############################################################
#
# <p>�ե������ź�դ��뤿��Υե������ɽ�����ޤ���</p>
# <pre>
# {{attach}}
# </pre>
# <p>
#   ź�դ����ե�����ϥե�����ξ�˰���ɽ������ޤ���
#   Ʊ���ե������ź�դ����ʣ��ɽ������Ƥ��ޤ��ΤϤ����ȤǤ���
#   nolist���ץ�����Ĥ���Ȱ���ɽ����Ԥ��ޤ���
# </p>
# <pre>
# {{attach nolist}}
# </pre>
#
############################################################
package plugin::attach::Attach;
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
# �ץ饰����μ��̤��֤��ޤ�
#===========================================================
sub type {
	return "html";
}

#===========================================================
# ź�եե������ɽ��
#===========================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my $option = shift;
	my $cgi    = $wiki->get_CGI;
	my $page   = $cgi->param("page");
	
	if(!defined($option) || $option ne "nolist"){
		if(!defined($self->{$page})){
			$self->{$page} = 1;
		} else {
			$self->{$page}++;
		}
	} else {
		$self->{$page} = undef;
	}
	
	my $buf = "<form action=\"".$wiki->create_url()."\" method=\"post\" enctype=\"multipart/form-data\">\n".
	          "  <input type=\"file\" name=\"file\">\n".
	          "  <input type=\"submit\" name=\"UPLOAD\" value=\" ź �� \">\n".
	          "  <input type=\"hidden\" name=\"page\" value=\"". Util::escapeHTML($page)."\">\n".
	          "  <input type=\"hidden\" name=\"action\" value=\"ATTACH\">\n";
	
	if(defined($self->{$page})){
		$buf .= "  <input type=\"hidden\" name=\"count\" value=\"".$self->{$page}."\">\n";
	}
	
	$buf .= "</form>\n";

	return $buf;
}

1;
