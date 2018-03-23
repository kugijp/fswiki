###############################################################################
#
# �桼��������Ԥ����������ϥ�ɥ�
#
###############################################################################
package plugin::admin::AdminUserHandler;
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
	my $cgi   = $wiki->get_CGI;
	
	$wiki->set_title("�桼������");
	
	if($cgi->param("delete") ne ""){
		return $self->delete_user($wiki);
		
	} elsif($cgi->param("regist") ne ""){
		return $self->user_form($wiki,{});
		
	} elsif($cgi->param("update") ne ""){
		my $users = &Util::load_config_hash($wiki,$wiki->config('userdat_file'));
		my $id = $cgi->param("update");
		my ($pass,$type) = split(/\t/,$users->{$id});
		
		return $self->user_form($wiki,{id=>$id,pass=>$pass,type=>$type});
		
	} elsif($cgi->param("saveuser") ne ""){
		return $self->save_user($wiki);
	
	} elsif($cgi->param("changepass") ne ""){
		return $self->change_pass($wiki);
		
	} else {
		return $self->user_list($wiki);
	}
}

#==============================================================================
# �桼������
#==============================================================================
sub user_list {
	my $self = shift;
	my $wiki = shift;
	
	my $users = &Util::load_config_hash($wiki,$wiki->config('userdat_file'));
	my $buf .= "<h2>�桼������</h2>\n".
	           "<table>\n".
	           "<tr><th>ID</th><th>����</th><th>���</th></tr>\n";
	
	foreach my $id (sort(keys(%$users))){
		my ($pass,$type) = split(/\t/,$users->{$id});
		
		$buf .= "<tr>\n";
		$buf .= "  <td>".&Util::escapeHTML($id)."</td>\n";
		if($type==0){
			$buf .= "  <td>������</td>\n";
		} else {
			$buf .= "  <td>����</td>\n";
		}
		$buf .= "  <td><a href=\"".$wiki->create_url({action=>"ADMINUSER",update=>$id})."\">�ѹ�</a> ".
		              "<a href=\"".$wiki->create_url({action=>"ADMINUSER",delete=>$id})."\">���</a></td>\n";
		$buf .= "</tr>\n";
	}
	$buf .= "</table>\n";
	$buf .= "<form action=\"".$wiki->create_url()."\" method=\"GET\">\n".
	        "  <input type=\"submit\" name=\"regist\" value=\"�桼�����ɲ�\">\n".
	        "  <input type=\"hidden\" name=\"action\" value=\"ADMINUSER\">\n".
	        "</form>\n";
	return $buf;
}

#==============================================================================
# �桼���ɲá������ե�����
#==============================================================================
sub user_form {
	my $self = shift;
	my $wiki = shift;
	my $data = shift;
	
	my $buf = "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n";
	if(defined($data->{id})){
		$buf .= "<h2>�桼�����ѹ�</h2>";
	} else {
		$buf .= "<h2>�桼�����ɲ�</h2>";
	}
	$buf .= "<h3>ID</h3>\n";
	if(defined($data->{id})){
		$buf .= "<p><b>".&Util::escapeHTML($data->{id})."</b>���ѹ��ϤǤ��ޤ����</p>\n";
		$buf .= "<input type=\"hidden\" name=\"id\" value=\"".&Util::escapeHTML($data->{id})."\">\n";
	} else {
		$buf .= "<p><input type=\"text\" name=\"id\" size=\"20\"></p>\n";
	}
	if(!defined($data->{id})){
		$buf .= "<h3>�ѥ����</h3>\n";
		$buf .= "<p><input type=\"password\" name=\"pass\" size=\"20\"></p>\n";
	}
	$buf .= "<h3>����</h3>\n";
	$buf .= "<p>\n";
	$buf .= "<input type=\"radio\" name=\"type\" value=\"0\" id=\"type_0\"";
	if($data->{type}!=1){ $buf .= " checked"; }
	$buf .= "><label for=\"type_0\">������</label>\n";
	$buf .= "<input type=\"radio\" name=\"type\" value=\"1\" id=\"type_1\"";
	if($data->{type}==1){ $buf .= " checked"; }
	$buf .= "><label for=\"type_1\">����</label>\n";
	$buf .= "</p>\n";
	
	if(defined($data->{id})){
		$buf .= "<input type=\"submit\" name=\"saveuser\" value=\"�ѹ�\">\n";
	} else {
		$buf .= "<input type=\"submit\" name=\"saveuser\" value=\"�ɲ�\">\n";
	}
	$buf .= "<input type=\"hidden\" name=\"action\" value=\"ADMINUSER\">\n";
	$buf .= "</form>\n";
	
	if(defined($data->{id})){
		$buf .= "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n";
		$buf .= "  <h2>�ѥ���ɤ��ѹ�</h2>\n";
		$buf .= "  <h3>�������ѥ����</h3>\n";
		$buf .= "  <p><input type=\"password\" name=\"pass\" size=\"30\"></p>\n";
		$buf .= "  <input type=\"submit\" name=\"changepass\" value=\"�ѹ�\">\n";
		$buf .= "  <input type=\"hidden\" name=\"action\" value=\"ADMINUSER\">\n";
		$buf .= "  <input type=\"hidden\" name=\"id\" value=\"".&Util::escapeHTML($data->{id})."\">\n";
		$buf .= "</form>\n";
	}
	
	$buf .= "[<a href=\"". $wiki->create_url({ action=>"ADMINUSER" }) . "\">���</a>]\n";
	
	return $buf;
}

#==============================================================================
# �桼���������¸
#==============================================================================
sub save_user {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $id   = $cgi->param("id");
	my $pass = $cgi->param("pass");
	my $type = $cgi->param("type");
	my $users = &Util::load_config_hash($wiki,$wiki->config('userdat_file'));
	
	if(!defined($users->{$id})){
		if($id eq "" || $pass eq "" || $type eq ""){
			return $wiki->error(RC_BAD_REQUEST, "ID���ѥ���ɡ��桼�����̤���ꤷ�Ƥ���������");
		}
	} else {
		if($id eq "" || $type eq ""){
			return $wiki->error(RC_BAD_REQUEST, "ID���桼�����̤���ꤷ�Ƥ���������");
		}
	}
	unless($id =~ /^[a-zA-Z0-9\-_]+$/ && (!defined($pass) || $pass =~ /^[a-zA-Z0-9\-_]+/)){
		return $wiki->error(RC_BAD_REQUEST, "ID���ѥ���ɤˤ�Ⱦ�ѱѿ����������ѤǤ��ޤ���");
	}
	
	if(defined($users->{$id})){
		($pass) = split(/\t/,$users->{$id});
		$users->{$id} = "$pass\t$type";
	} else {
		$users->{$id} = &Util::md5($pass,$id)."\t$type";
	}
	&Util::save_config_hash($wiki,$wiki->config('userdat_file'),$users);
	
	$wiki->redirectURL( $wiki->create_url({ action=>"ADMINUSER"}) );
}

#==============================================================================
# �ѥ���ɤ��ѹ�
#==============================================================================
sub change_pass {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI();
	my $id   = $cgi->param("id");
	my $pass = $cgi->param("pass");
	
	my $users = &Util::load_config_hash($wiki,$wiki->config('userdat_file'));
	my ($p,$type)  = split(/\t/,$users->{$id});
	$users->{$id} = &Util::md5($pass,$id)."\t$type";
	&Util::save_config_hash($wiki,$wiki->config('userdat_file'),$users);
	
	$wiki->redirectURL( $wiki->create_url({ action=>"ADMINUSER"}) );
}

#==============================================================================
# �桼���κ��
#==============================================================================
sub delete_user {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	my $id   = $cgi->param("delete");
	
	my $users = &Util::load_config_hash($wiki,$wiki->config('userdat_file'));
	my $saveusers = {};
	foreach(sort(keys(%$users))){
		if($_ ne $id){
			$saveusers->{$_} = $users->{$_};
		}
	}
	&Util::save_config_hash($wiki,$wiki->config('userdat_file'),$saveusers);
	
	$wiki->redirectURL( $wiki->create_url({ action=>"ADMINUSER"}) );
}

1;
