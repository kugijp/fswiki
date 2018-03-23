###############################################################################
#
# ���ե�������������⥸�塼��
#
###############################################################################
package plugin::admin::AdminLogHandler;
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
	my $login = $wiki->get_login_info();
	
	if($cgi->param("delete")){
		return $self->delete_log($wiki);
		
	} elsif($cgi->param("download")){
		$self->download_log($wiki);
		
	} elsif($cgi->param("deletecache")){
		return $self->delete_cache($wiki);
		
	} else {
		return $self->log_info($wiki);
	}
}

#==============================================================================
# ���ե�����ξ����ɽ��
#==============================================================================
sub log_info {
	my $self = shift;
	my $wiki = shift;
	my $buf  = "";
	
	$wiki->set_title("���ե�����δ���");
	
	$buf .= $self->make_log_form($wiki,"����������","access");
	$buf .= $self->make_log_form($wiki,"ź�եե�����Υ�","attach");
	$buf .= $self->make_log_form($wiki,"ź�եե������������ɿ��Υ�","download");
	$buf .= "<p>�����Υ��ե�������������ź�եե�����Υ�������ɿ������ꥢ����ޤ���</p>\n";
	$buf .= $self->make_log_form($wiki,"�ڡ������Υ�","freeze");
	$buf .= "<p>�����Υ��ե����������������ƤΥڡ�����뤬�������ޤ���</p>\n";
	
	# ����å���ե�����ξ���
	$buf .= "<h2>����å���ե�����</h2>\n";
	my @cachefiles = ();
	if($wiki->config("log_dir") ne ""){
		opendir(DIR,$wiki->config("log_dir")) or die $wiki->config("log_dir")."�Υ����ץ�˼��Ԥ��ޤ�����";
		while(my $entry = readdir(DIR)){
			if($entry =~ /\.cache$/){
				push(@cachefiles,$entry);
			}
		}
		closedir(DIR);
	}
	
	if($#cachefiles==-1){
		$buf .= "<p>����å���ե�����Ϥ���ޤ���</p>\n";
	} else {
		$buf .= "<ul>\n";
		@cachefiles = sort(@cachefiles);
		foreach(@cachefiles){
			my @status = stat($wiki->config("log_dir")."/".$_);
			my $size = @status[7] / 1024;
			$size = ($size==int($size) ? $size : int($size + 1));
			
			$buf .= "<li>".&Util::escapeHTML($_)."(".$size."KB)</li>\n";
		}
		$buf .= "</ul>\n";
		$buf .= "<form action=\"\" method=\"POST\">\n".
		        "  <input type=\"submit\" name=\"deletecache\" value=\"����å������\">\n".
		        "  <input type=\"hidden\" name=\"action\" value=\"ADMINLOG\">\n".
		        "</form>\n";
	}
	
	return $buf;
}

#==============================================================================
# ���ե�����ξ���ɽ��������Ԥ��ե��������Ϥ���ؿ�
#==============================================================================
sub make_log_form {
	my $self   = shift;
	my $wiki   = shift;
	my $name   = shift;
	my $target = shift;
	my $file   = $self->get_filename_from_target($wiki,$target);
	
	my $buf .= "<h2>".&Util::escapeHTML($name)."</h2>\n";
	
	if(-e $wiki->config('log_dir')."/$file"){
		my @status = stat($wiki->config('log_dir')."/$file");
		my $size = @status[7] / 1024;
		# �������ڤ�夲
		$size = ($size==int($size) ? $size : int($size + 1));
		$buf .= "<p>".&Util::escapeHTML($file)."(".$size."KB)</p>\n".
		        "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
		        "  <input type=\"submit\" name=\"download\" value=\"���������\">\n".
		        "  <input type=\"submit\" name=\"delete\" value=\"�ե�������\">\n".
		        "  <input type=\"hidden\" name=\"target\" value=\"$target\">\n".
		        "  <input type=\"hidden\" name=\"action\" value=\"ADMINLOG\">\n".
		        "</form>\n";
	} else {
		$buf .= "<p>���ե�����Ϥ���ޤ���</p>\n";
	}
	
	return $buf;
}

#==============================================================================
# ���ե��������
#==============================================================================
sub delete_log {
	my $self = shift;
	my $wiki = shift;
	my $target = $wiki->get_CGI->param("target");
	my $file   = $self->get_filename_from_target($wiki,$target);
	
	if($file eq ""){
		return $wiki->error(RC_BAD_REQUEST, "�ѥ�᡼���������Ǥ���");
	}
	
	unlink($wiki->config('log_dir')."/$file") or die $file."�κ���˼��Ԥ��ޤ�����";
	
	return $wiki->redirectURL( $wiki->create_url({ action=>"ADMINLOG"}) );
	
	#$wiki->set_title("���ե�����δ���");
	#return "<p>���ե�����������ޤ�����</p>\n".
	#       "<p>[<a href=\"".$wiki->config('script_name')."?action=ADMINLOG\">���</a>]</p>\n";
}

#==============================================================================
# ���ե��������������
#==============================================================================
sub download_log {
	my $self = shift;
	my $wiki = shift;
	my $target = $wiki->get_CGI->param("target");
	my $file   = $self->get_filename_from_target($wiki,$target);
	
	if($file eq ""){
		return $wiki->error(RC_BAD_REQUEST, "�ѥ�᡼���������Ǥ���");
	}
	
	print "Content-Type: text/plain\n";
	print "Content-Disposition: inline;filename=\"".&Jcode::convert($file,"sjis")."\"\n\n";
	open(LOG,$wiki->config('log_dir')."/$file") or die $file."�Υ����ץ�˼��Ԥ��ޤ�����";
	binmode(LOG);
	while(<LOG>){ print $_; }
	close(LOG);
	
	exit();
}

#==============================================================================
# ���ե�����Υե�����̾���������ؿ�
#==============================================================================
sub get_filename_from_target {
	my $self   = shift;
	my $wiki   = shift;
	my $target = shift;
	if($target eq "access"){
		return $wiki->config('access_log_file');
	} elsif($target eq "attach"){
		return $wiki->config('attach_log_file');
	} elsif($target eq "freeze"){
		return $wiki->config('freeze_file');
	} elsif($target eq "download"){
		return $wiki->config('download_count_file');
	} else {
		return "";
	}
}

#==============================================================================
# ����å���ե��������
#==============================================================================
sub delete_cache {
	my $self = shift;
	my $wiki = shift;
	
	unlink glob($wiki->config("log_dir")."/*.cache") or die "����å���ե�����κ���˼��Ԥ��ޤ�����";
	
	return $wiki->redirectURL( $wiki->create_url({ action=>"ADMINLOG"}) );
	
	#$wiki->set_title("���ե�����δ���");
	#return "<p>����å���ե�����������ޤ�����</p>\n".
	#       "<p>[<a href=\"".$wiki->config('script_name')."?action=ADMINLOG\">���</a>]</p>\n";
}

1;
