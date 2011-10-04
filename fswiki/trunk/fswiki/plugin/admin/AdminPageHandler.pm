###############################################################################
#
# �ڡ������������⥸�塼��
#
###############################################################################
package plugin::admin::AdminPageHandler;
use strict;
#==============================================================================
# ���󥹥ȥ饯��
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	
	# �ե��륿�������¸����ե�����
	$self->{filter_file} = "filter.dat";
	
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
	
	if($cgi->param("freeze") ne ""){
		$self->freeze_page($wiki);
		$self->reload($wiki);
		
	} elsif($cgi->param("unfreeze") ne ""){
		$self->unfreeze_page($wiki);
		$self->reload($wiki);
		
	} elsif($cgi->param("delete") ne ""){
		$self->delete_page($wiki);
		$self->reload($wiki);
		
	} elsif($cgi->param("delete_files") ne ""){
		$self->delete_page($wiki);
		$self->delete_files($wiki);
		$self->reload($wiki);
		
	} elsif($cgi->param("show_all") ne ""){
		$self->show_all($wiki);
		$self->reload($wiki);
		
	} elsif($cgi->param("show_user") ne ""){
		$self->show_user($wiki);
		$self->reload($wiki);
		
	} elsif($cgi->param("show_admin") ne ""){
		$self->show_admin($wiki);
		$self->reload($wiki);
		
	}
	return $self->page_list($wiki);
}

#==============================================================================
# �ڡ����κ��
#==============================================================================
sub delete_page {
	my $self = shift;
	my $wiki = shift;
	my @pages = $wiki->get_CGI->param("pages");
	foreach(@pages){
		$wiki->save_page($_,"");
	}
}

#==============================================================================
# ź�եե�����κ��
#==============================================================================
sub delete_files {
	my $self = shift;
	my $wiki = shift;
	my @pages = $wiki->get_CGI->param("pages");
	foreach my $pagename (@pages){
		my @files = glob($wiki->config('attach_dir')."/".&Util::url_encode($pagename).".*");
		foreach my $file (@files){
			unlink($file);
		}
	}
}

#==============================================================================
# �����˸���
#==============================================================================
sub show_all {
	my $self = shift;
	my $wiki = shift;
	my @pages = $wiki->get_CGI->param("pages");
	foreach(@pages){
		$wiki->set_page_level($_,0);
	}
}

#==============================================================================
# �桼���Τ߻��Ȳ�ǽ
#==============================================================================
sub show_user {
	my $self = shift;
	my $wiki = shift;
	my @pages = $wiki->get_CGI->param("pages");
	foreach(@pages){
		$wiki->set_page_level($_,1);
	}
}

#==============================================================================
# �����ԤΤ߻��Ȳ�ǽ
#==============================================================================
sub show_admin {
	my $self = shift;
	my $wiki = shift;
	my @pages = $wiki->get_CGI->param("pages");
	foreach(@pages){
		$wiki->set_page_level($_,2);
	}
}

#==============================================================================
# �ڡ��������
#==============================================================================
sub freeze_page {
	my $self = shift;
	my $wiki = shift;
	my @freeze_list = $wiki->get_freeze_list;
	my @pages = $wiki->get_CGI->param("pages");
	foreach my $page (@pages){
		my $flag = 1;
		foreach(@freeze_list){
			if($_ eq $page){
				$flag = 0;
				last;
			}
		}
		if($flag){
			$wiki->freeze_page($page);
		}
	}
}

#==============================================================================
# �ڡ����������
#==============================================================================
sub unfreeze_page {
	my $self = shift;
	my $wiki = shift;
	my @freeze_list = $wiki->get_freeze_list;
	my @pages = $wiki->get_CGI->param("pages");
	foreach my $page (@pages){
		my $flag = 0;
		foreach(@freeze_list){
			if($_ eq $page){
				$flag = 1;
				last;
			}
		}
		if($flag){
			$wiki->un_freeze_page($page);
		}
	}
}

#==============================================================================
# �ڡ�������
#==============================================================================
sub page_list {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI();
	
	my @freeze_list = $wiki->get_freeze_list();
	my @pages       = $wiki->get_page_list();
	my $level_list  = $wiki->get_page_level();
	my $filter = $cgi->param("filter");
	my $filterType = $cgi->param("filterType");
	
	if($filterType ne "AND" && $filterType ne "OR" && $filterType ne "NOT"){
		$filterType = "AND";
	}
	
	# �ե��륿����¸���ѥ�᡼���ǻ��ꤵ��Ƥ��ʤ�����ɤ߹��ߡ�
	if(defined($filter)){
		&Util::save_config_text($wiki,$self->{filter_file},"$filterType:$filter");
	} else {
		$filter = &Util::load_config_text($wiki,$self->{filter_file});
		my $index = index($filter,":");
		if($index > 0){
			$filterType = substr($filter,0,$index);
			$filter = substr($filter,$index+1);
		}
	}
	
	my $buf = "<h2>�ڡ�������</h2>\n".
	          "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
	          "  <p>\n".
	          "    �ե��륿\n".
	          "    <input type=\"text\" name=\"filter\" size=\"30\" value=\"".Util::escapeHTML($filter)."\">\n".
	          "    <input type=\"radio\" name=\"filterType\" value=\"AND\"".($filterType eq "AND" ? " checked" : "").">AND\n".
	          "    <input type=\"radio\" name=\"filterType\" value=\"OR\"".($filterType eq "OR" ? " checked" : "").">OR\n".
	          "    <input type=\"radio\" name=\"filterType\" value=\"NOT\"".($filterType eq "NOT" ? " checked" : "").">NOT\n".
	          "    <input type=\"submit\" value=\"��ɽ��\">\n".
	          "  </p>\n".
	          "  <table>\n".
	          "  <tr>\n".
	          "    <th><br></th>\n".
	          "    <th>����</th>\n".
	          "    <th>����</th>\n".
	          "    <th width=\"200\">�ڡ���̾</th>\n".
	          "    <th>�ǽ���������</th>\n".
	          "  </tr>\n";
	
	foreach my $page (@pages){
		if($filter ne ""){
			my @dim = split(/\s+/,$filter);
			my $flag = 0;
			foreach my $word (split(/\s+/,$filter)){
				if(index($page,$word) >= 0){
					if($filterType eq "NOT"){
						$flag = 0;
						last;
					}
					$flag = 1;
				} else {
					if($filterType eq "AND"){
						$flag = 0;
						last;
					} elsif($filterType eq "NOT"){
						$flag = 1;
					}
				}
			}
			if($flag==0){
				next;
			}
		}
		$buf .= "  <tr>\n".
		        "    <td><input type=\"checkbox\" name=\"pages\" value=\"".&Util::escapeHTML($page)."\"></td>\n";
		
		# ��뤵��Ƥ��뤫Ĵ�٤�
		my $is_freeze = 0;
		foreach(@freeze_list){
			if($_ eq $page){
				$is_freeze = 1;
				last;
			}
		}
		if($is_freeze){
			$buf .= "    <td align=\"center\">���</td>\n";
		} else {
			$buf .= "    <td><br></td>\n";
		}
		
		# ���ȥ�٥��Ĵ�٤�
		if(!defined($level_list->{$page}) || $level_list->{$page}==0){
			$buf .= "    <td>����</td>\n";
		} elsif($level_list->{$page}==1){
			$buf .= "    <td>�桼��</td>\n";
		} elsif($level_list->{$page}==2){
			$buf .= "    <td>������</td>\n";
		}
		
		$buf .= "    <td><a href=\"".$wiki->create_page_url($page)."\">".&Util::escapeHTML($page)."</a></td>\n".
		        "    <td>".&Util::format_date($wiki->get_last_modified($page))."</td>\n".
		        "  </tr>\n";
	}
	
	$buf .= "  </table>\n".
	        "  <br>\n".
	        "  <input type=\"hidden\" name=\"action\" value=\"ADMINPAGE\">\n".
	        "  <h3>�ڡ��������</h3>\n".
	        "  <p>�����å������ڡ�������뤷�ޤ�����뤷���ڡ����ϥ�������Τ��Խ���ǽ�Ȥʤ�ޤ���</p>\n".
	        "  <input type=\"submit\" name=\"freeze\" value=\" �� �� \">\n".
	        "  <input type=\"submit\" name=\"unfreeze\" value=\"�����\">\n".
	        "  <h3>�ڡ����κ��</h3>\n".
	        "  <p>�����å������ڡ����������ޤ���</p>\n".
	        "  <input type=\"submit\" name=\"delete\" value=\" �� �� \">\n".
	        "  <input type=\"submit\" name=\"delete_files\" value=\"ź�եե��������\">\n".
	        "  <h3>���ȸ��¤�����</h3>\n".
	        "  <p>�����å������ڡ����λ��ȸ��¤����ꤷ�ޤ���</p>\n".
	        "  <input type=\"submit\" name=\"show_all\"   value=\" �� �� \">\n".
	        "  <input type=\"submit\" name=\"show_user\"  value=\"�桼���Τ�\">\n".
	        "  <input type=\"submit\" name=\"show_admin\" value=\"�����ԤΤ�\">\n".
	        "</form>\n";
	
	$wiki->set_title("�ڡ����δ���");
	return $buf."</ul>\n";
}

#==============================================================================
# �ڡ�������������
#==============================================================================
sub reload {
	my $self = shift;
	my $wiki = shift;
	$wiki->redirectURL( $wiki->create_url({ action=>"ADMINPAGE" }) );
}

1;
