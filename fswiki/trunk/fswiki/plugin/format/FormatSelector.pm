###############################################################################
#
# <p>�Խ��ե����ޥåȤ����򤹤뤿��Υץ饰����Ǥ���</p>
#
###############################################################################
package plugin::format::FormatSelector;
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
# �Խ��ե�����˽񼰤����򤹤뤿��Υ���ܥܥå�������Ϥ��ޤ���
#==============================================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my $cgi    = $wiki->get_CGI();
	my $page   = $cgi->param('page');
	my $format = $wiki->get_edit_format();
	my @list   = $wiki->get_format_names();
	
	my $buf = "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
	          "  <input type=\"hidden\" name=\"action\" value=\"CHANGE_FORMAT\">\n".
	          "  <input type=\"hidden\" name=\"query\" value=\"".$ENV{'QUERY_STRING'}."\">\n".
	          "  <select name=\"format\">\n";

	foreach my $value (@list){
		$buf .= "    <option value=\"".&Util::escapeHTML($value)."\"";
		if($value eq $format){
			$buf .= " selected";
		}
		$buf .= ">".&Util::escapeHTML($value)."</option>\n";
	}
	
	$buf .= "  </select>\n".
	        "  <input type=\"submit\" value=\"�ѹ�\">\n".
	        "</form>\n";
	
	return $buf;
}

#==============================================================================
# ���ѹ����ν�����������ޤ���
#==============================================================================
sub do_action {
	my $self   = shift;
	my $wiki   = shift;
	my $cgi    = $wiki->get_CGI();
	my $page   = $cgi->param('page');
	my $format = $cgi->param('format');
	
	if($format eq ""){
		$format = "FSWiki";
	}
	
	my $path   = &Util::cookie_path($wiki);
	my $cookie = $cgi->cookie(-name=>'edit_format',-value=>$format,-expires=>'+1M',-path=>$path);
	print "Set-Cookie: ",$cookie->as_string,"\n";
	
	my $url = $wiki->config('script_name');
	if($cgi->param('query') ne ''){
		$url .= "?".$cgi->param('query');
	}
	
	$wiki->redirectURL($url);
}

1;
