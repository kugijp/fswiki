###############################################################################
#
# �桼������Ͽ��Ԥ����������ϥ�ɥ�
#
###############################################################################
package plugin::admin::UserRegisterHandler;
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
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI();
	
	if($cgi->param("saveuser") ne ""){
		return $self->save_user($wiki);
		
	} else {
		return $self->user_form($wiki);
	}
}

#==============================================================================
# �桼���ɲá������ե�����
#==============================================================================
sub user_form {
	my $self = shift;
	my $wiki = shift;
	
	$wiki->set_title("�桼���������Ͽ");
	
	my $buf = "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n";
	$buf .= "<h2>�桼���������Ͽ</h2>";
	$buf .= "<h3>ID</h3>\n";
	$buf .= "<p><input type=\"text\" name=\"id\" size=\"20\"></p>\n";
	$buf .= "<h3>�ѥ����</h3>\n";
	$buf .= "<p><input type=\"password\" name=\"pass\" size=\"20\"></p>\n";
	$buf .= "<input type=\"submit\" name=\"saveuser\" value=\"��Ͽ\">\n";
	$buf .= "<input type=\"hidden\" name=\"action\" value=\"USERREGISTER\">\n";
	$buf .= "</form>\n";
	
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
	my $type = 1;
	
	if($wiki->user_exists($id)){
		return $wiki->error("���Ϥ��줿ID�Ϥ��Ǥ˻��Ѥ���Ƥ��ޤ���");
	}
	if($id eq "" || $pass eq ""){
		return $wiki->error("ID���ѥ���ɤ���ꤷ�Ƥ���������");
	}
	unless($id =~ /^[a-zA-Z0-9\-_]+$/ && $pass =~ /^[a-zA-Z0-9\-_]+/){
		return $wiki->error("ID���ѥ���ɤˤ�Ⱦ�ѱѿ����������ѤǤ��ޤ���");
	}
	
	Util::sync_update_config($wiki,$wiki->config('userdat_file'),sub {
		my $hash = shift;
		unless(defined($hash->{$id})){
			$hash->{$id} = &Util::md5($pass,$id)."\t$type";
		}
		return $hash;
	});
	
	return qq|
	<h1>�桼���������Ͽ</h1>
	<p>
		�桼���������Ͽ���ޤ�����
		����³��<a href="@{[$wiki->create_url({action=>'LOGIN'})]}">������</a>���Ƥ���������
	</p>
	|;
}

1;
