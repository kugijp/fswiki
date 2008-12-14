############################################################
#
# �ڡ�����¸��or������˥᡼��������Ԥ��եå��ץ饰����
#
############################################################
package plugin::core::SendMail;
use strict;
use plugin::core::Diff;
#===========================================================
# ���󥹥ȥ饯��
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# �ڡ�����¸��or�����Υեå��᥽�å�
#===========================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $login    = $wiki->get_login_info();
	my $pagename = $cgi->param("page");
	my $content  = $cgi->param("content");
	my $backup   = $wiki->get_backup($pagename);
	my $diff     = plugin::core::Diff->new();
	
	my $subject;
	my $tmpl;
	
	# �����ȥ�ȥƥ�ץ졼�Ȥ����
	if($content eq ""){
		$subject = $wiki->config('mail_prefix')."$pagename���������ޤ���";
		
	} elsif($backup eq "") {
		$subject = $wiki->config('mail_prefix')."$pagename����������ޤ���";
		
	} else {
		$subject = $wiki->config('mail_prefix')."$pagename����������ޤ���";
		
	}
	
	my $mail = "";
	
	if($wiki->config('mail_id')==1 && defined($login)){
		$mail .= "ID:".$login->{id}."\n";
	}
	if($wiki->config('mail_remote_addr')==1){
		$mail .= "IP:".$ENV{'REMOTE_ADDR'}."\n";
	}
	if($wiki->config('mail_user_agent')==1){
		$mail .= "UA:".$ENV{'HTTP_USER_AGENT'}."\n";
	}
	if($wiki->config('mail_diff')==1){
		my @list = $wiki->{storage}->get_backup_list($pagename);
		my $last_generation = @list - 1;
		$mail .= "----\n";
		$mail .= "�ʲ����ѹ��κ�ʬ�Ǥ���\n";
		$mail .= "----\n";
		$mail .= $diff->get_diff_text($wiki,$pagename,$last_generation)."\n";
	}
	if($wiki->config('mail_backup_source')==1){
		$mail .= "----\n";
		$mail .= "�ʲ����ѹ����Υ������Ǥ���\n";
		$mail .= "----\n";
		$mail .= $backup."\n";
	}
	if($wiki->config('mail_modified_source')==1){
		$mail .= "----\n";
		$mail .= "�ʲ����ѹ���Υ������Ǥ���\n";
		$mail .= "----\n";
		$mail .= $content."\n";
	}
	
	&Util::send_mail($wiki,$subject,$mail);
}

1;
