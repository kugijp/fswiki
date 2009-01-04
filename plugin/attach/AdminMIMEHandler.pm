###############################################################################
#
# MIME�����פ������Ԥ����������ϥ�ɥ�
#
###############################################################################
package plugin::attach::AdminMIMEHandler;
use strict;
#==============================================================================
# ���󥹥ȥ饯��
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# ���������ϥ�ɥ�᥽�å�
#==============================================================================
sub do_action {
	my $self  = shift;
	my $wiki  = shift;
	my $cgi   = $wiki->get_CGI;
	
	$wiki->set_title("MIME�����פ�����");
	
	if($cgi->param("ADD") ne ""){
		return $self->add($wiki);
		
	} elsif($cgi->param("DELETE") ne ""){
		return $self->delete($wiki);
		
	} else {
		return $self->form($wiki);
	}
}

#==============================================================================
# ��������
#==============================================================================
sub form {
	my $self = shift;
	my $wiki = shift;
	my $buf = "<h2>MIME�����פ���Ͽ</h2>\n".
	          "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
	          "  ��ĥ�ҡʥɥåȤ����ס� <input type=\"text\" name=\"extention\" size=\"5\">\n".
	          "  MIME������ <input type=\"text\" name=\"mimetype\" size=\"20\">\n".
	          "  <input type=\"submit\" name=\"ADD\" value=\"��Ͽ\">\n".
	          "  <input type=\"hidden\" name=\"action\" value=\"ADMINMIME\">\n".
	          "</form>\n".
	          "<h2>��Ͽ�Ѥ�MIME������</h2>\n".
	          "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
	          "<table>\n".
	          "<tr><th>&nbsp;</td><th>��ĥ��</th><th>MIME������</th></tr>\n";
	
	my $mime = &Util::load_config_hash($wiki,$wiki->config('mime_file'));
	
	foreach my $key (sort(keys(%$mime))){
		$buf .= "<tr>\n".
		        "  <td><input type=\"checkbox\" name=\"extention\" value=\"".&Util::escapeHTML($key)."\"></td>\n".
		        "  <td>".&Util::escapeHTML($key)."</td>\n".
		        "  <td>".&Util::escapeHTML($mime->{$key})."</td>\n".
		        "</tr>\n";
	}
	$buf .= "</table>\n".
	        "<input type=\"submit\" name=\"DELETE\" value=\"������ܤ���\">\n".
	        "<input type=\"hidden\" name=\"action\" value=\"ADMINMIME\">\n".
	        "</form>\n";
	
	return $buf;
}

#==============================================================================
# �ɲ�
#==============================================================================
sub add {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI();
	
	my $ext  = $cgi->param("extention");
	my $mime = $cgi->param("mimetype");
	
	if($ext ne "" && $mime ne ""){
		my $hash = &Util::load_config_hash($wiki,$wiki->config('mime_file'));
		$hash->{$ext} = $mime;
		&Util::save_config_hash($wiki,$wiki->config('mime_file'),$hash);
		$wiki->redirectURL($wiki->create_url({ action=>"ADMINMIME"}) );
		#return $self->form($wiki);
		
	} else {
		return $wiki->error("��ĥ�Ҥ�MIME�����פ����Ϥ��Ƥ���������");
	}
}

#==============================================================================
# ���
#==============================================================================
sub delete {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI();
	
	my @ext_list = $cgi->param("extention");
	my $hash     = &Util::load_config_hash($wiki,$wiki->config('mime_file'));
	my $result   = {};
	
	foreach my $key (keys(%$hash)){
		my $flag = 0;
		foreach my $ext (@ext_list){
			if($ext eq $key){
				$flag = 1;
				last;
			}
		}
		if($flag==0){
			$result->{$key} = $hash->{$key};
		}
	}
	
	&Util::save_config_hash($wiki,$wiki->config('mime_file'),$result);
	$wiki->redirectURL($wiki->create_url({action=>"ADMINMIME"}) );
	
	#return $self->form($wiki);
}

1;
