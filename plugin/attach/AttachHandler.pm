############################################################
#
# ź�եե�����Υ��������ϥ�ɥ顣
#
############################################################
package plugin::attach::AttachHandler;
use strict;
use plugin::attach::Files;
#===========================================================
# ���󥹥ȥ饯��
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# ���������μ¹�
#===========================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	if($pagename eq ""){
		$pagename = $wiki->config("frontpage");
	}
	
	$wiki->set_title("�ե������ź��",1);
	
	if($cgi->param("UPLOAD") ne "" || $cgi->param("CONFIRM") ne "" || $cgi->param("DELETE") ne ""){
		unless($wiki->can_modify_page($pagename)){
			return $wiki->error("�Խ��϶ػߤ���Ƥ��ޤ���");
		}
	}
	
	if($cgi->param("DELETE") ne ""){
		unless(&plugin::attach::Files::can_attach_delete($wiki, $pagename)){
			return $wiki->error("�ե�����κ���ϵ��Ĥ���Ƥ��ޤ���");
		}
	}
	
	#-------------------------------------------------------
	# ���åץ��ɼ¹�
	if($cgi->param("UPLOAD") ne ""){
		my $filename = $cgi->param("file");
		$filename =~ s/\\/\//g;
		$filename = substr($filename,rindex($filename,"/")+1);
		$filename =~ tr/";\x00-\x1f/': /;
		&Jcode::convert(\$filename,'euc');
		
		if($filename eq ""){
			return $wiki->error("�ե����뤬���ꤵ��Ƥ��ޤ���");
		}
		
		my $hundle = $cgi->upload("file");
		unless($hundle){
			return $wiki->error("�ե����뤬�ɤ߹���ޤ���Ǥ�����");
		}
		
		my $uploadfile = $wiki->config('attach_dir')."/".&Util::url_encode($pagename).".".&Util::url_encode($filename);
		if(-e $uploadfile && !&plugin::attach::Files::can_attach_update($wiki, $pagename)){
			return $wiki->error("�ե�����ξ�񤭤ϵ��Ĥ���Ƥ��ޤ���");
		}
		
		open(DATA,">$uploadfile") or die $!;
		binmode(DATA);
		while(read($hundle,$_,16384)){ print DATA $_; }
		close(DATA);
				
		# attach�ץ饰���󤫤�ź�դ��줿���
		if(defined($cgi->param("count"))){
			my @lines = split(/\n/,$wiki->get_page($pagename));
			my $flag = 0;
			my $form_count = 1;
			my $count=$cgi->param("count");
			my $content = "";
			foreach(@lines){
				if(index($_," ")==0||index($_,"\t")==0){
					$content .= $_."\n";
					next;
				}
				if(index($_,"{{attach}}")!=-1 && $flag==0){
					if($form_count==$count){
						$content = $content."{{ref ".$filename."}}\n";
						$flag = 1;
					} else {
						$form_count++;
					}
				}
				$content = $content.$_."\n";
			}
			if($flag==1){
				$wiki->save_page($pagename,$content);
			}
		}
		
		# ���ε�Ͽ
		&write_log($wiki,"UPLOAD",$pagename,$filename);
		
		$wiki->redirect($pagename);
		
	#-------------------------------------------------------
	# �����ǧ
	} elsif($cgi->param("CONFIRM") ne ""){
		my $file = $cgi->param("file");
		if($file eq ""){
			return $wiki->error("�ե����뤬���ꤵ��Ƥ��ޤ���");
		}
		
		my $buf = "";
		
		$buf .= "<a href=\"".$wiki->create_page_url($pagename)."\">".
		        Util::escapeHTML($pagename)."</a>����".Util::escapeHTML($file)."�������Ƥ�����Ǥ�����\n".
		        "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
		        "  <input type=\"submit\" name=\"DELETE\" value=\"�� ��\">".
		        "  <input type=\"hidden\" name=\"action\" value=\"ATTACH\">".
		        "  <input type=\"hidden\" name=\"page\" value=\"".Util::escapeHTML($pagename)."\">".
		        "  <input type=\"hidden\" name=\"file\" value=\"".Util::escapeHTML($file)."\">".
		        "</form>";
		return $buf;
	
	#-------------------------------------------------------
	# ����¹�
	} elsif($cgi->param("DELETE") ne ""){
		my $file = $cgi->param("file");
		if($file eq ""){
			return $wiki->error("�ե����뤬���ꤵ��Ƥ��ޤ���");
		}
		
		# ���ε�Ͽ
		&write_log($wiki,"DELETE",$pagename,$file);

		unlink($wiki->config('attach_dir')."/".&Util::url_encode($pagename).".".&Util::url_encode($file));
		$wiki->redirect($pagename);
		
	#-------------------------------------------------------
	# ���������
	} else {
		my $file = $cgi->param("file");
		if($file eq ""){
			return $wiki->error("�ե����뤬���ꤵ��Ƥ��ޤ���");
		}
		unless($wiki->page_exists($pagename)){
			return $wiki->error("�ڡ�����¸�ߤ��ޤ���");
		}
		unless($wiki->can_show($pagename)){
			return $wiki->error("�ڡ����λ��ȸ��¤�����ޤ���");
		}
		my $filepath = $wiki->config('attach_dir')."/".&Util::url_encode($pagename).".".&Util::url_encode($file);
		unless(-e $filepath){
			return $wiki->error("�ե����뤬�ߤĤ���ޤ���");
		}
		
		my $contenttype = &get_mime_type($wiki,$file);
		my $ua = $ENV{"HTTP_USER_AGENT"};
		my $disposition = ($contenttype =~ /^image\// && $ua !~ /MSIE/ ? "inline" : "attachment");

		open(DATA, $filepath) or die $!;
		print "Content-Type: $contenttype\n";
		print Util::make_content_disposition($file, $disposition);
		binmode(DATA);
		while(read(DATA,$_,16384)){ print $_; }
		close(DATA);
				
		# ���ε�Ͽ
		&write_log($wiki,"DOWNLOAD",$pagename,$file);
		&count_up($wiki,$pagename,$file);
		
		exit();
	}
}

#===========================================================
# ��������ɥ�����Ȥ򥤥󥯥����
#===========================================================
sub count_up {
	my $wiki = shift;
	my $page = shift;
	my $file = shift;
	
	Util::sync_update_config(undef,$wiki->config('log_dir')."/".$wiki->config('download_count_file'),
	sub {
		my $hash = shift;
		unless(defined($hash->{$page."::".$file})){
			$hash->{$page."::".$file} = 1;
		} else {
			$hash->{$page."::".$file}++;
		}
		return $hash;
	}
	);
}

#===========================================================
# ź�եե�����Υ�
#===========================================================
sub write_log(){
	my $wiki = shift;
	my $mode = shift;
	my $page = shift;
	my $file = shift;
	if($wiki->config('log_dir') eq "" || $wiki->config('attach_log_file') eq ""){
		return;
	}
	my $ip  = $ENV{"REMOTE_ADDR"};
	my $ref = $ENV{"HTTP_REFERER"};
	my $ua  = $ENV{"HTTP_USER_AGENT"};
	if($ip  eq ""){ $ip  = "-"; }
	if($ref eq ""){ $ref = "-"; }
	if($ua  eq ""){ $ua  = "-"; }
	my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time());
	my $date = sprintf("%04d/%02d/%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
	
	my $logfile = $wiki->config('log_dir')."/".$wiki->config('attach_log_file');
	Util::file_lock($logfile);
	open(LOG,">>$logfile") or die $!;
	binmode(LOG);
	print LOG $mode." ".&Util::url_encode($page)." ".&Util::url_encode($file)." ".
	          $date." ".$ip." ".$ref." ".$ua."\n";
	close(LOG);
	Util::file_unlock($logfile);
}

#===========================================================
# MIME�����פ�������ޤ�
#===========================================================
sub get_mime_type {
	my $wiki = shift;
	my $file = shift;
	my $type = lc(substr($file,rindex($file,".")+1));
	
	my $hash  = &Util::load_config_hash($wiki,$wiki->config('mime_file'));
	my $ctype = $hash->{$type};
	
	if($ctype eq "" ){
		$ctype = "application/octet-stream";
	}
	
	return $ctype;
}

1;
