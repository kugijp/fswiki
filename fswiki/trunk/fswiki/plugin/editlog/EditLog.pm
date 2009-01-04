############################################################
#
# �ڡ�����¸��or������˵�Ͽ��Ԥ��եå��ץ饰����
#
############################################################
package plugin::editlog::EditLog;
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
	
	my @log;
	my $now = time();
	push ( @log, format_date( $now ) );
	push ( @log, $now );
	if($content eq ""){
		push @log, "delete";
	} elsif($backup eq "") {
		push @log, "create";
	} else {
		push @log, "modify";
	}
	push @log, Util::url_encode($pagename);
	push @log, $login->{id};
	
	my $logfile = $wiki->config('log_dir')."/useredit.log";
	Util::file_lock($logfile);
	open (DATA, ">>$logfile") or die $!;
	print DATA join(" ",@log)."\n";
	close(DATA);
	Util::file_unlock($logfile);
}

#==============================================================================
# ���դ�ե����ޥå�
# taken from RSS.pm
#==============================================================================
sub format_date {
	my $time = shift;
	my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime($time);
	return sprintf("%04d/%02d/%02d %02d:%02d:%02d",
	               $year+1900,$mon+1,$mday,$hour,$min,$sec);
}

1;
