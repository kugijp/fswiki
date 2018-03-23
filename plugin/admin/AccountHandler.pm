###############################################################################
#
# ��������Ⱦ��������Ԥ����������ϥ�ɥ�
#
###############################################################################
package plugin::admin::AccountHandler;
use strict;
use HTTP::Status;
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
	my $cgi = $wiki->get_CGI;
	
	$wiki->set_title("��������Ⱦ���");
	
	if($cgi->param("changepass") ne ""){
		return $self->change_pass($wiki);
	}
	if(!defined($wiki->get_login_info)) {
		return $wiki->error(RC_FORBIDDEN, "�����󤷤Ƥ��ޤ���");
	}
	my $id = $wiki->get_login_info()->{id};
	
	return $self->account_form($wiki,$id);
}

#==============================================================================
# ��������Ⱦ���ե�����
#==============================================================================
sub account_form {
	my $self = shift;
	my $wiki = shift;
	my $id   = shift;
	
	my $buf = "<h2>��������Ⱦ���</h2>";
	$buf .= "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n";
	$buf .= "  <table>\n";
	$buf .= "  <tr>\n";
	$buf .= "  <th>ID</th>\n";
	$buf .= "  <td><b>".&Util::escapeHTML($id)."</b>���ѹ��ϤǤ��ޤ����</td>\n";
	$buf .= "  </tr>\n";
	$buf .= "  <tr>\n";
	$buf .= "  <th>���ߤΥѥ����</th>\n";
	$buf .= "  <td><input type=\"password\" name=\"pass_old\" size=\"30\"></td>\n";
	$buf .= "  </tr>\n";
	$buf .= "  <tr>\n";
	$buf .= "  <th>�������ѥ����</th>\n";
	$buf .= "  <td><input type=\"password\" name=\"pass1\" size=\"30\"></td>\n";
	$buf .= "  </tr>\n";
	$buf .= "  <tr>\n";
	$buf .= "  <th>�������ѥ���ɡʳ�ǧ��</th>\n";
	$buf .= "  <td><input type=\"password\" name=\"pass2\" size=\"30\"></td>\n";
	$buf .= "  </tr>\n";
	$buf .= "  </table>\n";
#	$buf .= "  <div style=\"margin-top:10pt;\">\n";
	$buf .= "    <input type=\"submit\" name=\"changepass\" value=\"�ѹ�\">\n";
	$buf .= "    <input type=\"hidden\" name=\"action\" value=\"ACCOUNT\">\n";
	$buf .= "    <input type=\"hidden\" name=\"id\" value=\"".&Util::escapeHTML($id)."\">\n";
#	$buf .= "  </div>\n";
	$buf .= "</form>\n";
	
	return $buf;
}

#==============================================================================
# �ѥ���ɤ��ѹ�
#==============================================================================
sub change_pass {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI();
	my $id   = $cgi->param("id");

	my $pass_old     = $cgi->param("pass_old");
	my $pass         = $cgi->param("pass1");
	my $pass_confirm = $cgi->param("pass2");


	# ���ߤΥѥ���ɤξȹ�

	# ¾�ͤ��ѥ���ɤ��ѹ����Ƥ��ޤ����Ȥ��ɻߤ��뤿�ᡢ�ѥ���ɤ��ѹ�
	# ����ݤˤϸ��ߤΥѥ���ɤ�ȹ礹��ɬ�פ����롣
	my $login = $wiki->login_check($id,&Util::md5($pass_old,$id));
	if(defined($login)){
		my $min_length = 2;

		# �������ѥ���ɤ��������γ�ǧ
		if ( length( $pass ) < $min_length ) {
			return $wiki->error(RC_BAD_REQUEST, "�������ѥ���ɤ����Ϥ���Ƥ��ޤ���".
				"���ʤ��Ȥ� $min_length ʸ���ʾ����Ϥ��Ƥ���������");
		}
		elsif ( $pass ne $pass_confirm ) {
			return $wiki->error(RC_BAD_REQUEST, "���Ϥ��줿��ĤΥѥ���ɤ����פ��ޤ���");
		}

		my $session = $cgi->get_session($wiki);
		$session->param("wiki_id"  ,$id);
		$session->param("wiki_type",$login->{type});
		$session->param("wiki_path",$login->{path});
		$session->flush();

		my $users = &Util::load_config_hash($wiki,$wiki->config('userdat_file'));
		my ($p,$type)  = split(/\t/,$users->{$id});
		$users->{$id} = &Util::md5($pass,$id)."\t$type";
		&Util::save_config_hash($wiki,$wiki->config('userdat_file'),$users);
	} else {
		return $wiki->error(RC_UNAUTHORIZED, "���ߤΥѥ���ɤ��㤤�ޤ���");
	}
	
	$wiki->redirectURL( $wiki->create_url({ action=>"LOGIN" }) );
	
	#return "<p>�ѥ���ɤ��ѹ����ޤ�����</p>".
	#       "[<a href=\"".$wiki->config('script_name')."?action=LOGIN\">��˥塼�����</a>]\n";
}

1;
