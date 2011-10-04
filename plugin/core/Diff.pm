###############################################################################
# 
# ��ʬ��ɽ������ץ饰����
# 
###############################################################################
package plugin::core::Diff;
use Algorithm::Diff qw(traverse_sequences);
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
	my $cgi = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	if($pagename eq ""){
		$pagename = $wiki->config("frontpage");
	}
	unless($wiki->can_show($pagename)){
		return $wiki->error("���ȸ��¤�����ޤ���");
	}
	if($cgi->param('rollback') ne ''){
		return $self->rollback($wiki, $pagename, $cgi->param('rollback'));
		
	} elsif($wiki->{storage}->backup_type eq 'all'){
		my $login = $wiki->get_login_info();
		if(defined($login) && $login->{'type'} == 0 && $cgi->param('clear') ne ''){
			# ����Υ��ꥢ
			$self->clear_history($wiki, $pagename);
			return $self->show_history($wiki, $pagename);
			
		} elsif($cgi->param('generation') eq '' && $cgi->param('diff') eq ''){
			# �����ɽ��
			return $self->show_history($wiki, $pagename);
			
		} else {
			if($cgi->param('generation') ne ''){
				# ���ꤷ����ӥ����Ǥκ�ʬ��ɽ��
				return $self->show_diff($wiki, $pagename, '', $cgi->param('generation'));
			}
			# ���ꤷ����ӥ����֤κ�ʬ��ɽ��
			return $self->show_diff($wiki, $pagename, $cgi->param('from'), $cgi->param('to'));
		}
	} else {
		# �Ǹ�ι����κ�ʬ��ɽ��
		return $self->show_diff($wiki, $pagename, '', 0);
	}
}

#==============================================================================
# ����Υ��ꥢ
#==============================================================================
sub clear_history {
	my $self = shift;
	my $wiki = shift;
	my $page = shift;
	$wiki->{storage}->delete_backup_files($wiki, $page);
}

#==============================================================================
# ���򤫤�ڡ���������
#==============================================================================
sub rollback {
	my $self = shift;
	my $wiki = shift;
	my $page = shift;
	my $gen  = shift;
	unless($wiki->can_modify_page($page)){
		return $wiki->error("�������¤�����ޤ���");
	}
	my $source = $wiki->get_backup($page,$gen);
	$wiki->save_page($page, $source);
	return $wiki->redirect($page);
}

#==============================================================================
# ����ΰ�����ɽ��
# ���ȥ졼����backup_type=all�ΤȤ�
#==============================================================================
sub show_history {
	my $self = shift;
	my $wiki = shift;
	my $page = shift;
	
	$wiki->set_title("$page���ѹ�����");
	my $buf   = "<form><ul>\n";
	my $count = 0;
	my @list  = $wiki->{storage}->get_backup_list($page);
	
	if($#list == -1){
		return "����Ϥ���ޤ���";
	}
	
	# editlog�ץ饰����Υ������Խ��ԤΥ桼��̾�����
	# ��editlog�����դ�����뤳�Ȥ����ä��Τ�1�ð���ι�����Ʊ������Ȥߤʤ��褦�ˤ��Ƥޤ���
	my $editlog = {};
	if($wiki->config('log_dir') ne "" && -e $wiki->config('log_dir')."/useredit.log"){
		open(DATA,$wiki->config('log_dir')."/useredit.log") or die $!;
		while(<DATA>){
			my($date, $time, $unixtime, $action, $subject, $id) = split(" ",$_);
			if($subject eq $page){
				if($id eq ''){
					$editlog->{substr($unixtime, 0, length($unixtime) - 4)} = 'anonymous';
				} else {
					$editlog->{substr($unixtime, 0, length($unixtime) - 4)} = $id;
				}
			}
		}
		close(DATA);
	}
	
	foreach my $time (@list){
		$buf .= "<li>";
		if($count == 0){
			$buf .= "<input type=\"radio\" name=\"from\" value=\"".($#list-$count)."\" checked>".
			        "<input type=\"radio\" name=\"to\" value=\"".($#list-$count)."\" checked>";
		} else {
			$buf .= "<input type=\"radio\" name=\"from\" value=\"".($#list-$count)."\">".
			        "<input type=\"radio\" name=\"to\" value=\"".($#list-$count)."\">";
		}
		$buf .= "<a href=\"".$wiki->create_url({ action=>"DIFF",page=>$page,generation=>($#list-$count) })."\">".&Util::format_date($time).
		        "</a> <a href=\"".$wiki->create_url({ action=>"SOURCE",page=>$page,generation=>($#list-$count) })."\">������</a>";
		        
		if(defined($editlog->{substr($time, 0, length($time) - 4)})){
			$buf .= " by ".$editlog->{substr($time, 0, length($time) - 4)};
		}
		
		$buf .=  "</li>\n";
		$count++;
	}
	
	$buf .= "</ul>".
		"<input type=\"hidden\" name=\"page\" value=\"".Util::escapeHTML($page)."\">".
		"<input type=\"hidden\" name=\"action\" value=\"DIFF\">".
		"<input type=\"submit\" name=\"diff\" value=\"���򤷤���ӥ����֤κ�ʬ��ɽ��\">\n";
	
	my $login = $wiki->get_login_info();
	if(defined($login) && $login->{'type'} == 0){
		$buf .= "<input type=\"submit\" name=\"clear\" value=\"����򤹤٤ƺ��\">\n";
	}
	return $buf."</form>\n";
}

#==============================================================================
# ��ʬ��ɽ��
#==============================================================================
sub show_diff {
	my $self = shift;
	my $wiki = shift;
	my $page = shift;
	my $from = shift;
	my $to   = shift;
	
	$wiki->set_title("$page���ѹ���");
	my ($diff, $rollback) = $self->get_diff_html($wiki,$page, $from, $to);
	
	$diff =~ s/\n/<br>/g;
	
	my $buf = qq|
		<ul>
		  <li>�ɲä��줿��ʬ��<ins class="diff">���Τ褦��</ins>ɽ������ޤ���</li>
		  <li>������줿��ʬ��<del class="diff">���Τ褦��</del>ɽ������ޤ���</li>
		</ul>
		<div class="diff">$diff</div>
	|;
	
	if($wiki->can_modify_page($page) && $rollback && $wiki->get_CGI->param('diff') eq ''){
		$buf .= qq|
			<form action="@{[$wiki->create_url()]}" method="POST">
				<input type="submit" value="���ΥС��������᤹"/>
				<input type="hidden" name="action" value="DIFF"/>
				<input type="hidden" name="page" value="@{[Util::escapeHTML($page)]}"/>
				<input type="hidden" name="rollback" value="@{[Util::escapeHTML($to)]}"/>
			</form>
		|;
	}
	
	return $buf;
}

#==============================================================================
# ��ʬʸ��������
#==============================================================================
sub get_diff_text {
	my $self = shift;
	my $wiki = shift;
	my $page = shift;
	my $gen  = shift;
	
	my $source1 = $wiki->get_page($page);
	my $source2 = $wiki->get_backup($page, $gen);
	my $format  = $wiki->get_edit_format();
	
	$source1 = $wiki->convert_from_fswiki($source1, $format);
	$source2 = $wiki->convert_from_fswiki($source2, $format);
	
	my $diff_text = "";
	my @msg1 = split(/\n/,$source1);
	my @msg2 = split(/\n/,$source2);
	my $msgrefA = \@msg2;
	my $msgrefB = \@msg1;
	
	traverse_sequences($msgrefA, $msgrefB,
		{
			MATCH => sub {},
			DISCARD_A => sub {
				my ($a, $b) = @_;
				$diff_text .= "-".$msgrefA->[$a]."\n";
			},
			DISCARD_B => sub {
				my ($a, $b) = @_;
				$diff_text .= "+".$msgrefB->[$b]."\n";
			}
		});
	
	return $diff_text;
}

#==============================================================================
# ��ʬʸ�����ɽ����HTML�Ȥ��Ƽ���
#==============================================================================
sub get_diff_html {
	my $self = shift;
	my $wiki = shift;
	my $page = shift;
	my $from = shift;
	my $to   = shift;
	
	my $source1 = '';
	if($from ne ''){
		$source1 = $wiki->get_backup($page, $from);
	} else {
		$source1 = $wiki->get_page($page);
	}
	if($wiki->config('diff_max') ne '' && $wiki->config('diff_max') > 0){
		if(length($source1) > $wiki->config('diff_max')){
			return ('�ڡ������������礭�����ẹʬ��ɽ���Ǥ��ޤ���', 0);
		}
	}
	
	my $source2 = '';
	if($to ne ''){
		$source2 = $wiki->get_backup($page, $to);
	} else {
		$source2 = $wiki->get_page($page);
	}
	if($wiki->config('diff_max') ne '' && $wiki->config('diff_max') > 0){
		if(length($source2) > $wiki->config('diff_max')){
			return ('�ڡ������������礭�����ẹʬ��ɽ���Ǥ��ޤ���', 0);
		}
	}
	
	my $format  = $wiki->get_edit_format();
	
	$source1 = $wiki->convert_from_fswiki($source1, $format);
	$source2 = $wiki->convert_from_fswiki($source2, $format);
	
	return (&_get_diff_html($source1, $source2), $source2 ne "");
}

#==============================================================================
# ��ʬHTML����������ؿ�
#==============================================================================
sub _get_diff_html {
	my $source1 = shift;
	my $source2 = shift;
	
	my @lines1 = split(/\n/,$source1);
	my @lines2 = split(/\n/,$source2);
	my $linesrefA = \@lines2;
	my $linesrefB = \@lines1;
	
	my $diff_text = "";
	my $del_buffer = "";
	
	traverse_sequences($linesrefA, $linesrefB, {
		MATCH => sub {
			my ($a, $b) = @_;
			if($del_buffer ne ''){
				$diff_text .= "<del class=\"diff\">".Util::escapeHTML($del_buffer)."</del>\n";
				$del_buffer = '';
			}
			$diff_text .= Util::escapeHTML($linesrefA->[$a])."\n";
		},
		DISCARD_A => sub {
			my ($a, $b) = @_;
			$del_buffer .= $linesrefA->[$a]."\n";
		},
		DISCARD_B => sub {
			my ($a, $b) = @_;
			if($del_buffer eq ''){
				$diff_text .= "<ins class=\"diff\">".Util::escapeHTML($linesrefB->[$b])."</ins>\n";
				
			} else {
				my @msg1 = _str_jfold($linesrefB->[$b]."\n", 1);
				my @msg2 = _str_jfold($del_buffer, 1);
				my $msgrefA = \@msg2;
				my $msgrefB = \@msg1;
				
				traverse_sequences($msgrefA, $msgrefB, {
					MATCH => sub {
						my ($a, $b) = @_;
						$diff_text .= Util::escapeHTML($msgrefA->[$a]);
					},
					DISCARD_A => sub {
						my ($a, $b) = @_;
						$diff_text .= "<del class=\"diff\">".Util::escapeHTML($msgrefA->[$a])."</del><wbr>";
					},
					DISCARD_B => sub {
						my ($a, $b) = @_;
						$diff_text .= "<ins class=\"diff\">".Util::escapeHTML($msgrefB->[$b])."</ins><wbr>";
					}
				});
				
				$del_buffer = '';
			}
		}
	});
		
	if($del_buffer ne ''){
		$diff_text .= "<del class=\"diff\">".Util::escapeHTML($del_buffer)."</del>\n";
		$del_buffer = '';
	}
	
	return $diff_text;
}

#==============================================================================
# ʸ��������ʸ������ʬ��
#==============================================================================
sub _str_jfold {
  my $str    = shift;       #����ʸ����
  my $byte   = shift;       #����Х���
  my $j      = new Jcode($str);
  my @result = ();

  foreach my $buff ( $j->jfold($byte) ){
    push(@result, $buff);
  }

  return(@result);
}

#==============================================================================
# �ڡ���ɽ�����Υեå��᥽�å�
# �ֺ�ʬ�ץ�˥塼��ͭ���ˤ��ޤ�
#==============================================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	my $page = $cgi->param("page");
	if($wiki->{storage}->backup_type eq 'all'){
		$wiki->add_menu("����",$wiki->create_url({ action=>"DIFF",page=>$page }));
	} else {
		$wiki->add_menu("��ʬ",$wiki->create_url({ action=>"DIFF",page=>$page }));
	}
}

1;
