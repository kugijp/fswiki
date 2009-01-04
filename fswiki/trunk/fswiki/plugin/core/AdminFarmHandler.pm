###############################################################################
#
# Farm�������Ԥ����������ϥ�ɥ顣
#
###############################################################################
package plugin::core::AdminFarmHandler;
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
	my $wiki = shift;
	$wiki->set_title("WikiFarm������");
	if($wiki->get_CGI()->param("save") ne ""){
		return $self->save_config($wiki);
	} else {
		return $self->config_form($wiki);
	}
}

#==============================================================================
# �������¸
#==============================================================================
sub save_config {
	my $self = shift;
	my $wiki = shift;
	
	my $cgi           = $wiki->get_CGI();
	my $create        = $cgi->param("create");
	my $remove        = $cgi->param("remove");
	my $usefarm       = $cgi->param("usefarm");
	my $use_template  = $cgi->param("use_template");
	my $search_parent = $cgi->param("search_parent");
	my $hide_template = $cgi->param("hide_template");
	
	&Util::save_config_hash($wiki,$wiki->config('farmconf_file'),
		{create        => $create,
		 remove        => $remove,
		 usefarm       => $usefarm,
		 use_template  => $use_template,
		 search_parent => $search_parent,
		 hide_template => $hide_template});
	
	$wiki->redirectURL($wiki->create_url( {action=>"ADMINFARM"} ) );
	#return "WikiFarm���������¸���ޤ�����";
}

#==============================================================================
# �������
#==============================================================================
sub config_form {
	my $self = shift;
	my $wiki = shift;
	my $config = &Util::load_config_hash($wiki,$wiki->config('farmconf_file'));
	
	my $buf = "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n";
	$buf   .= "<h2>WikiFarm������</h2>\n";
	$buf   .= "  <h3>Farm����Ѥ��뤫�ɤ���</h3>\n";
	$buf   .= "  <p>\n";
	$buf   .= "  <input type=\"radio\" id=\"usefarm_0\" name=\"usefarm\" value=\"0\""; if($config->{usefarm}==0){ $buf.= " checked"; } $buf.="><label for=\"usefarm_0\">���Ѥ��ʤ�</label>\n";
	$buf   .= "  <input type=\"radio\" id=\"usefarm_1\" name=\"usefarm\" value=\"1\""; if($config->{usefarm}==1){ $buf.= " checked"; } $buf.="><label for=\"usefarm_1\">���Ѥ���</label>\n";
	$buf   .= "  </p>\n";
	$buf   .= "  <h3>Farm�κ�������</h3>\n";
	$buf   .= "  <p>\n";
	$buf   .= "  <input type=\"radio\" id=\"create_0\" name=\"create\" value=\"0\""; if($config->{create}==0){ $buf.= " checked"; } $buf.="><label for=\"create_0\">ï�Ǥ��ǽ</label>\n";
	$buf   .= "  <input type=\"radio\" id=\"create_1\" name=\"create\" value=\"1\""; if($config->{create}==1){ $buf.= " checked"; } $buf.="><label for=\"create_1\">��������Τ߲�ǽ</label>\n";
	$buf   .= "  <input type=\"radio\" id=\"create_2\" name=\"create\" value=\"2\""; if($config->{create}==2){ $buf.= " checked"; } $buf.="><label for=\"create_2\">�����ԤΤ߲�ǽ</label>\n";
	$buf   .= "  </p>\n";
	$buf   .= "  <h3>Farm�κ������</h3>\n";
	$buf   .= "  <p>\n";
	$buf   .= "  <input type=\"radio\" id=\"remove_0\" name=\"remove\" value=\"0\""; if($config->{remove}==0){ $buf.= " checked"; } $buf.="><label for=\"remove_0\">ï�Ǥ��ǽ</label>\n";
	$buf   .= "  <input type=\"radio\" id=\"remove_1\" name=\"remove\" value=\"1\""; if($config->{remove}==1){ $buf.= " checked"; } $buf.="><label for=\"remove_1\">��������Τ߲�ǽ</label>\n";
	$buf   .= "  <input type=\"radio\" id=\"remove_2\" name=\"remove\" value=\"2\""; if($config->{remove}==2){ $buf.= " checked"; } $buf.="><label for=\"remove_2\">�����ԤΤ߲�ǽ</label>\n";
	$buf   .= "  </p>\n";
	$buf   .= "  <h3>�������Υƥ�ץ졼��</h3>\n";
	$buf   .= "  <ul>\n";
	$buf   .= "  <li><input type=\"checkbox\" id=\"use_template\" name=\"use_template\" value=\"1\""; 
	          if($config->{use_template}==1){ $buf.= " checked"; } $buf.="><label for=\"use_template\">./template����ڡ����򥳥ԡ�����</label></li>\n";
	$buf   .= "  <li><input type=\"checkbox\" id=\"search_parent\" name=\"search_parent\" value=\"1\"";
	          if($config->{search_parent}==1){ $buf.= " checked"; } $buf.="><label for=\"search_parent\">./template���ʤ���硢�Ƥˤ����Τܤä�õ��</label></li>\n";
	$buf   .= "  <li><input type=\"checkbox\" id=\"hide_template\" name=\"hide_template\" value=\"1\"";
	          if($config->{hide_template}==1){ $buf.= " checked"; } $buf.="><label for=\"hide_template\">Wiki�ΰ�����./template��ɽ�����ʤ�</label></li>\n";
	$buf   .= "  </ul>\n";
	$buf   .= "  <input type=\"submit\" name=\"save\" value=\"��¸\">\n";
	$buf   .= "  <input type=\"reset\"  value=\"�ꥻ�å�\">\n";
	$buf   .= "  <input type=\"hidden\" name=\"action\" value=\"ADMINFARM\">\n";
	$buf   .= "</form>\n";
	
	return $buf;
}

1;
