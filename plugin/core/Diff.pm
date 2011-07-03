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
		if($cgi->param('generation') eq '' && $cgi->param('diff') eq ''){
			return $self->show_history($wiki, $pagename);
		} else {
			if($cgi->param('generation') ne ''){
				return $self->show_diff($wiki, $pagename, '', $cgi->param('generation'));
			}
			return $self->show_diff($wiki, $pagename, $cgi->param('from'), $cgi->param('to'));
		}
	} else {
		return $self->show_diff($wiki, $pagename, '', 0);
	}
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
	my $pagename = shift;
	
	$wiki->set_title($pagename."���ѹ�����");
	my $buf   = "<form><ul>\n";
	my $count = 0;
	my @list  = $wiki->{storage}->get_backup_list($pagename);
	
	if($#list == -1){
		return "����Ϥ���ޤ���";
	}
	
	# editlog�ץ饰����Υ��������Խ��ԤΥ桼��̾�����
	my $editlog = {};
	if($wiki->config('log_dir') ne "" && -e $wiki->config('log_dir')."/useredit.log"){
		open(DATA,$wiki->config('log_dir')."/useredit.log") or die $!;
		while(<DATA>){
			my($date, $time, $unixtime, $action, $subject, $id) = split(" ",$_);
			if($subject eq $pagename){
				if($id eq ''){
					$editlog->{$unixtime} = 'anonymous';
				} else {
					$editlog->{$unixtime} = $id;
				}
			}
		}
		close(DATA);
	}
	
	foreach my $time (@list){
		$buf .= "<li>";
		if($count == 0){
			$buf .= "<input type=\"radio\" name=\"from\" value=\"\" checked>".
			        "<input type=\"radio\" name=\"to\" value=\"\" checked>";
		} else {
			$buf .= "<input type=\"radio\" name=\"from\" value=\"".($#list-$count+1)."\">".
			        "<input type=\"radio\" name=\"to\" value=\"".($#list-$count+1)."\">";
		}
		$buf .= "<a href=\"".$wiki->create_url({ action=>"DIFF",page=>$pagename,generation=>($#list-$count) })."\">".&Util::format_date($time).
		        "</a> <a href=\"".$wiki->create_url({ action=>"SOURCE",page=>$pagename,generation=>($#list-$count) })."\">������</a>";
		        
		if(defined($editlog->{$time})){
			$buf .= " by ".$editlog->{$time};
		}
		
		$buf .=  "</li>\n";
		$count++;
	}
	return $buf."</ul>".
	"<input type=\"hidden\" name=\"page\" value=\"".Util::escapeHTML($pagename)."\">".
	"<input type=\"hidden\" name=\"action\" value=\"DIFF\">".
	"<input type=\"submit\" name=\"diff\" value=\"���򤷤���ӥ����֤κ�ʬ��ɽ��\"></form>\n";
}

#==============================================================================
# ��ʬ��ɽ��
#==============================================================================
sub show_diff {
	my $self     = shift;
	my $wiki     = shift;
	my $pagename = shift;
	my $from     = shift;
	my $to       = shift;
	
	$wiki->set_title($pagename."���ѹ���");
	my ($diff, $rollback) = $self->get_diff_html($wiki,$pagename, $from, $to);
	
	$diff =~ s/\n/<br>/g;
	
	my $buf = qq|
		<ul>
		  <li>�ɲä��줿��ʬ��<ins class="diff">���Τ褦��</ins>ɽ������ޤ���</li>
		  <li>������줿��ʬ��<del class="diff">���Τ褦��</del>ɽ������ޤ���</li>
		</ul>
		<div class="diff">$diff</div>
	|;
	
	if($wiki->can_modify_page($pagename) && $rollback && $wiki->get_CGI->param('diff') eq ''){
		$buf .= qq|
			<form action="@{[$wiki->create_url()]}" method="POST">
				<input type="submit" value="���ΥС��������᤹"/>
				<input type="hidden" name="action" value="DIFF"/>
				<input type="hidden" name="page" value="@{[Util::escapeHTML($pagename)]}"/>
				<input type="hidden" name="rollback" value="@{[Util::escapeHTML($from)]}"/>
			</form>
		|;
	}
	
	return $buf;
}

#==============================================================================
# ��ʬʸ��������
#==============================================================================
sub get_diff_text {
	my $self       = shift;
	my $wiki       = shift;
	my $pagename   = shift;
	my $generation = shift;
	
	my $source1 = $wiki->get_page($pagename);
	my $source2 = $wiki->get_backup($pagename,$generation);
	my $format  = $wiki->get_edit_format();
	
	$source1 = $wiki->convert_from_fswiki($source1,$format);
	$source2 = $wiki->convert_from_fswiki($source2,$format);
	
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
	my $self     = shift;
	my $wiki     = shift;
	my $pagename = shift;
	my $from     = shift;
	my $to       = shift;
	
	my $source1 = '';
	if($from ne ''){
		$source1 = $wiki->get_backup($pagename, $from);
	} else {
		$source1 = $wiki->get_page($pagename);
	}
	my $source2 = '';
	if($to ne ''){
		$source2 = $wiki->get_backup($pagename, $to);
	} else {
		$source2 = $wiki->get_page($pagename);
	}
	my $format  = $wiki->get_edit_format();
	
	$source1 = $wiki->convert_from_fswiki($source1, $format);
	$source2 = $wiki->convert_from_fswiki($source2, $format);
	
	my $diff_text = "";
=pod
	my @msg1 = split(/\n/,$source1);
	return "�ڡ������礭�����뤿�ẹʬ��ɽ���Ǥ��ޤ���" if($#msg1 >= 999);
	my @msg2 = split(/\n/,$source2);
	return "�ڡ������礭�����뤿�ẹʬ��ɽ���Ǥ��ޤ���" if($#msg2 >= 999);
=cut
	my @msg1 = _str_jfold($source1, 1);
	my @msg2 = _str_jfold($source2, 1);
	
	my $msgrefA = \@msg2;
	my $msgrefB = \@msg1;
	
	traverse_sequences($msgrefA, $msgrefB,
		{
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
	
	return ($diff_text, $source2 ne "");
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
	
	my $pagename = $cgi->param("page");
	if($wiki->{storage}->backup_type eq 'all'){
		$wiki->add_menu("����",$wiki->create_url({ action=>"DIFF",page=>$pagename }));
	} else {
		$wiki->add_menu("��ʬ",$wiki->create_url({ action=>"DIFF",page=>$pagename }));
	}
}

1;