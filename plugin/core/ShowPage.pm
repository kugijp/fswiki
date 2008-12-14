###############################################################################
# 
# �ڡ�����ɽ������ץ饰����
# 
###############################################################################
package plugin::core::ShowPage;
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
# ���������μ¹�
#==============================================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	if(!defined($pagename) || $pagename eq ""){
		$pagename = $wiki->config("frontpage");
		$cgi->param("page",$pagename);
	}
	
	if($wiki->page_exists($pagename)){
		# �����������ε�Ͽ
		if($wiki->config('log_dir') ne "" && $wiki->config('access_log_file') ne ""){
			&write_log($wiki,$pagename);
		}
		
		# ���ȸ��¤Υ����å�
		if(!$wiki->can_show($pagename)){
			$wiki->set_title("���ȸ��¤�����ޤ���");
			return $wiki->error("���ȸ��¤�����ޤ���");
		}
		
		$wiki->set_title($pagename);
		$wiki->do_hook("show"); # ������Wiki.pm���椫��ƤӤ���...
		
		return $wiki->process_wiki($wiki->get_page($pagename),1,1);
		
	} else {
		return $wiki->call_handler("EDIT",$cgi);
	}
}

#==============================================================================
# �����������ε�Ͽ
#==============================================================================
sub write_log {
	my $wiki = shift;
	my $page = shift;
	
	my $ip  = $ENV{"REMOTE_ADDR"};
	my $ref = $ENV{"HTTP_REFERER"};
	my $ua  = $ENV{"HTTP_USER_AGENT"};
	if(!defined($ip)  || $ip  eq ""){ $ip  = "-"; }
	if(!defined($ref) || $ref eq ""){ $ref = "-"; }
	if(!defined($ua)  || $ua  eq ""){ $ua  = "-"; }
	
	my $logfile = $wiki->config('log_dir')."/".$wiki->config('access_log_file');
	Util::file_lock($logfile);
	open(LOG,">>$logfile") or die $!;
	print LOG Util::url_encode($page)." ".&log_date()." $ip $ref $ua\n";
	close(LOG);
	Util::file_unlock($logfile);
}

#===============================================================================
# ���դ�ե����ޥåȡʥ����������ѡ�
#===============================================================================
sub log_date {
	my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time());
	return sprintf("%04d/%02d/%02d %02d:%02d:%02d",
	               $year+1900,$mon+1,$mday,$hour,$min,$sec);
}

1;
