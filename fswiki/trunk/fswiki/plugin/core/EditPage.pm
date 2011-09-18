###############################################################################
# 
# �ڡ������Խ�����ץ饰����
# 
###############################################################################
package plugin::core::EditPage;
use strict;
use plugin::core::Diff;
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
	my $cgi = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	my $format   = $wiki->get_edit_format();
	my $content  = $cgi->param("content");
	my $sage     = $cgi->param("sage");
	my $template = $cgi->param("template");
	my $artno    = $cgi->param("artno");
	my $time     = $wiki->get_last_modified($pagename);
	
	my $buf = "";
	my $login = $wiki->get_login_info();

	if($pagename eq ""){
		return $wiki->error("�ڡ��������ꤵ��Ƥ��ޤ���");
	}
	if($pagename =~ /([\|\[\]])|^:|([^:]:[^:])/){
		return $wiki->error("�ڡ���̾�˻��ѤǤ��ʤ�ʸ�����ޤޤ�Ƥ��ޤ���");
	}
	if(!$wiki->can_modify_page($pagename)){
		return $wiki->error("�ڡ������Խ��ϵ��Ĥ���Ƥ��ޤ���");
	}
	
	#--------------------------------------------------------------------------
	# ��¸����
	if($cgi->param("save") ne ""){
		if($wiki->config('page_max') ne '' && $wiki->config('page_max') > 0){
			if(length($content) > $wiki->config('page_max')){
				return $wiki->error('�ڡ�������¸��ǽ�ʺ��祵������Ķ���Ƥ��ޤ���');
			}
		}
		if($wiki->page_exists($pagename) && $cgi->param("lastmodified") != $time){
			$buf .= "<p><span class=\"error\">�ڡ����ϴ����̤Υ桼���ˤ�äƹ�������Ƥ��ޤ���</span></p>";
			
			my $mode = $wiki->get_edit_format();
			my $orig_source = undef;
			if($artno eq ""){
				$orig_source = $wiki->convert_from_fswiki($wiki->get_page($pagename), $mode);
			} else {
				$orig_source = $wiki->convert_from_fswiki(&read_by_part($wiki->get_page($pagename), $artno), $mode);
			}
			my $your_source = $content;
			$your_source =~ s/\r\n/\n/g;
			$your_source =~ s/\r/\n/g;
			
			my $diff = plugin::core::Diff::_get_diff_html($orig_source, $your_source);
			$diff =~ s/\n/<br>/g;
			
			$buf .= qq|
				<ul>
				  <li>�ɲä��줿��ʬ��<ins class="diff">���Τ褦��</ins>ɽ������ޤ���</li>
				  <li>������줿��ʬ��<del class="diff">���Τ褦��</del>ɽ������ޤ���</li>
				</ul>
				<p>
				  �ǿ��ǤȤκ�ʬ���ǧ���ƺ����Խ���ԤäƤ���������
				</p>
				<div class="diff">$diff</div>
			|;
			
			$content = $orig_source;
			
		} else {
			#my $save_content = $content;
			my $mode = $wiki->get_edit_format();
			my $save_content = $wiki->convert_to_fswiki($content,$mode);

			# �ѡ����Խ��ξ��
			if($artno ne ""){
				$save_content = &make_save_source($wiki->get_page($pagename), $save_content, $artno, $wiki);
			}
			# FrontPage�Ϻ���Բ�
			if($pagename eq $wiki->config("frontpage") && $save_content eq ""){
				$buf = "<b>".&Util::escapeHTML($wiki->config("frontpage"))."�Ϻ�����뤳�ȤϤǤ��ޤ���</b>\n";

			# ����ʳ��ξ��Ͻ�����¹Ԥ��ƥ�å��������ֵ�
			} else {
				$wiki->save_page($pagename, $save_content, $sage);
				
				if($content ne ""){
					$wiki->redirect($pagename, $artno);
				} else {
					if($artno eq ""){
						$wiki->set_title($pagename."�������ޤ���");
						return Util::escapeHTML($pagename)."�������ޤ�����";
					} else {
						$wiki->set_title($pagename."�Υѡ��Ȥ������ޤ���");
						return Util::escapeHTML($pagename)."�Υѡ��Ȥ������ޤ�����";
					}
				}
			}
		}
	#--------------------------------------------------------------------------
	# ��ʬ��ǧ����
	} elsif($cgi->param("diff") ne ""){
		if($wiki->config('page_max') ne '' && $wiki->config('page_max') > 0){
			if(length($content) > $wiki->config('page_max')){
				return $wiki->error('�ڡ�������¸��ǽ�ʺ��祵������Ķ���Ƥ��ޤ���');
			}
		}
		$time = $cgi->param("lastmodified");
		
		my $mode = $wiki->get_edit_format();
		my $orig_source = undef;
		if($artno eq ""){
			$orig_source = $wiki->convert_from_fswiki($wiki->get_page($pagename), $mode);
		} else {
			$orig_source = $wiki->convert_from_fswiki(&read_by_part($wiki->get_page($pagename), $artno), $mode);
		}
		my $your_source = $content;
		$your_source =~ s/\r\n/\n/g;
		$your_source =~ s/\r/\n/g;
		
		$buf .= qq|
			<ul>
			  <li>�ɲä��줿��ʬ��<ins class="diff">���Τ褦��</ins>ɽ������ޤ���</li>
			  <li>������줿��ʬ��<del class="diff">���Τ褦��</del>ɽ������ޤ���</li>
			</ul>
		|;
			
		if($orig_source eq $your_source){
			$buf .= '<p class="error">��ʬ�Ϥ���ޤ���</p>';
		} else {
			my $diff = plugin::core::Diff::_get_diff_html($your_source, $orig_source);
			$diff =~ s/\n/<br>/g;
			$buf .= qq|<div class="diff">$diff</div>|;
		}
		
	#--------------------------------------------------------------------------
	# �ץ�ӥ塼����
	} elsif($cgi->param("preview") ne ""){
		if($wiki->config('page_max') ne '' && $wiki->config('page_max') > 0){
			if(length($content) > $wiki->config('page_max')){
				return $wiki->error('�ڡ�������¸��ǽ�ʺ��祵������Ķ���Ƥ��ޤ���');
			}
		}
		$time = $cgi->param("lastmodified");
		$buf = "�ʲ��Υץ�ӥ塼���ǧ���Ƥ������С���¸�ץܥ���򲡤��Ƥ���������<br>";
		if($content eq ""){
			if($pagename eq $wiki->config("frontpage") && $artno eq ""){
				$buf = $buf."<b>��".&Util::escapeHTML($wiki->config("frontpage"))."�Ϻ�����뤳�ȤϤǤ��ޤ��󡣡�</b>";
			} else {
				if($artno eq ""){
					$buf = $buf."<b>�ʥڡ������Ƥ϶��Ǥ�����������Ȥ��Υڡ����Ϻ������ޤ�����</b>";
				} else {
					$buf = $buf."<b>�ʥڡ������Ƥ϶��Ǥ�����������Ȥ��Υѡ��ȤϺ������ޤ�����</b>";
				}
			}
		}
		$content = $wiki->convert_to_fswiki($content,$format);
		$buf = $buf."<br>".$wiki->process_wiki($content);

	} elsif($wiki->page_exists($pagename)) {
		#�ڡ�����¸�ߤ�����
		if($artno eq ""){
			$content = $wiki->get_page($pagename);
		} else {
			$content = &read_by_part($wiki->get_page($pagename), $artno);
		}
	} elsif($template ne ""){
		#�ƥ�ץ졼�Ȥ���ꤵ�줿���
		$content = $wiki->get_page($template);
	}
	
	#--------------------------------------------------------------------------
	# ���ϥե�����
	$wiki->set_title($pagename."���Խ�",1);

	my $tmpl = HTML::Template->new(filename=>$wiki->config('tmpl_dir')."/editform.tmpl",
                                   die_on_bad_params => 0);

	$tmpl->param({SCRIPT_NAME   => $wiki->create_url(),
				  PAGE_NAME     => $pagename,
				  CONTENT       => $wiki->convert_from_fswiki($content, $format),
				  LAST_MODIFIED => $time,
				  ACTION        => 'EDIT',
				  EXISTS_PAGE   => $wiki->page_exists($pagename),
				  SAGE          => $sage});
	
	if($artno ne ""){
		$tmpl->param(OPTIONAL_PARAMS=>[{NAME=>'artno', VALUE=>$artno}]);
	}

	$buf .= $tmpl->output();

	# �ץ饰���������
	$buf .= $wiki->get_editform_plugin();
	
	return $buf;
}

#==============================================================================
# �ѡ����Խ��ξ����Խ���ʬ�μ��Ф�
#==============================================================================
sub read_by_part {
	my $page  = shift;
	my $num   = shift;
	my $count = 0;
	my $buf   = "";
	my $level = 0;
	my $flag  = 0;
	foreach my $line (split(/\n/,$page)){
		if($line=~/^(!{1,3})/){
			if($flag==1 && $level<=length($1)){
				last;
			}
			if($count==$num){
				$flag  = 1;
				$level = length($1);
			}
			$count++;
		}
		if($flag==1){
			$buf .= $line."\n";
		}
	}
	return $buf;
}

#==============================================================================
# �ѡ����Խ��ξ�����¸�ѥ������κ���
#==============================================================================
sub make_save_source {
	my $org   = shift;
	my $edit  = shift;
	my $num   = shift;
	my $wiki  = shift;
	my $count = 0;
	my $buf   = "";
	my $level = "";
	my $flag  = "";
	foreach my $line (split(/\n/,$org)){
		if($line=~/^(!{1,3})/){
			if($flag==1 && $level<=length($1)){
				$flag = 0;
			}
			if($count==$num){
				$flag  = 1;
				$level = length($1);
				$buf .= $edit;
				# �Ǹ夬���ԤǤʤ����������Ԥ��ɲáʼ��Υ��������Ȥ��äĤ��Ƥ��ޤ������
				$buf .= "\n" unless($edit =~ /\n$/);
			}
			$count++;
		}
		if($flag==0){
			$buf .= "$line\n";
		}
	}
	return $buf;
}

#==============================================================================
# �ڡ���ɽ�����Υեå��᥽�å�
# ���Խ��ץ�˥塼��ͭ���ˤ��ޤ�
#==============================================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	my $login    = $wiki->get_login_info();
	
	# �Խ���˥塼������
	if($wiki->can_modify_page($pagename)){
		$wiki->add_menu("�Խ�",$wiki->create_url({ action=>"EDIT",page=>$pagename }));
	}
}

1;
