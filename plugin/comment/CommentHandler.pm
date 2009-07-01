############################################################
# 
# Comment�ץ饰����Υ��������ϥ�ɥ顣
# 
############################################################
package plugin::comment::CommentHandler;
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
# �����Ȥν񤭹���
#===========================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $name    = $cgi->param("name");
	my $message = $cgi->param("message");
	my $count   = $cgi->param("count");
	my $page    = $cgi->param("page");
	my $option  = $cgi->param("option");
	
	if(!$wiki->can_show($page)){
		return $wiki->error("�ڡ����λ��ȸ��¤�����ޤ���");
	}
	if($name eq ""){
		$name = "̵̾������";
	} else {
		# fswiki_post_name�Ȥ��������ǥ��å����򥻥åȤ���
		my $path   = &Util::cookie_path($wiki);
		my $cookie = $cgi->cookie(-name=>'fswiki_post_name',-value=>Util::url_encode($name),-expires=>'+1M',-path=>$path);
		print "Set-Cookie: ",$cookie->as_string,"\n";
	}
	
	# �ե����ޥåȥץ饰����ؤ��б�
	my $format = $wiki->get_edit_format();
	$name    = $wiki->convert_to_fswiki($name   ,$format,1);
	$message = $wiki->convert_to_fswiki($message,$format,1);
	
	if($page ne "" && $message ne "" && $count ne ""){
		
		my @lines = split(/\n/,$wiki->get_page($page));
		my $flag       = 0;
		my $form_count = 1;
		my $content    = "";
		
		foreach(@lines){
			# �����ξ��
			if($option eq "reverse"){
				$content = $content.$_."\n";
				if(/^{{comment\s*.*}}$/ && $flag==0){
					if($form_count==$count){
						$content = $content."*$message - $name (".Util::format_date(time()).")\n";
						$flag = 1;
					} else {
						$form_count++;
					}
				}
			# �ڡ����������ɲäξ��
			} elsif($option eq "tail"){
				$content = $content.$_."\n";
				
			# ��ƽ�ξ��
			} else {
				if(/^{{comment\s*.*}}$/ && $flag==0){
					if($form_count==$count){
						$content = $content."*$message - $name (".Util::format_date(time()).")\n";
						$flag = 1;
					} else {
						$form_count++;
					}
				}
				$content = $content.$_."\n";
			}
		}
		
		# �ڡ����������ɲäξ��ϺǸ���ɲ�
		if($option eq "tail" && check_comment($wiki, 'Footer')){
			$content = $content."*$message - $name (".Util::format_date(time()).")\n";
			$flag = 1;
		}
		
		if($flag==1){
			$wiki->save_page($page,$content);
		}
	}
	
	# ���Υڡ����˥�����쥯��
	$wiki->redirect($page);
}

#==================================================================
# �ڡ�����comment�ץ饰���󤬴ޤޤ�Ƥ��뤫�ɤ���������å�
#==================================================================
sub check_comment {
	my $wiki = shift;
	my $page = shift;
	my @lines = split(/\n/,$wiki->get_page($page));
	foreach(@lines){
		if(/^{{comment\s*.*}}$/){
			return 1;
		}
	}
	return 0;
}

1;
