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
	} elsif($wiki->{storage}->backup_type eq "all"){
		if($cgi->param("generation") eq ""){
			return $self->show_history($wiki,$pagename);
		} else {
			return $self->show_diff($wiki,$pagename,$cgi->param("generation"));
		}
	} else {
		return $self->show_diff($wiki,$pagename,0);
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
	my $buf   = "<ul>\n";
	my $count = 0;
	my @list  = $wiki->{storage}->get_backup_list($pagename);
	foreach my $time (@list){
		$buf .= "<li><a href=\"".$wiki->create_url({ action=>"DIFF",page=>$pagename,generation=>($#list-$count) })."\">".&Util::escapeHTML($time).
		        "</a>��<a href=\"".$wiki->create_url({ action=>"SOURCE",page=>$pagename,generation=>($#list-$count) })."\">������</a>".
		        "</li>\n";
		$count++;
	}
	return $buf."</ul>\n";
}

#==============================================================================
# ��ʬ��ɽ��
#==============================================================================
sub show_diff {
	my $self       = shift;
	my $wiki       = shift;
	my $pagename   = shift;
	my $generation = shift;
	
	$wiki->set_title($pagename."���ѹ���");
	my ($diff, $rollback) = $self->get_diff_html($wiki,$pagename,$generation);
	
	my $buf = qq|
		<ul>
		  <li>�ɲä��줿�Ԥ�<ins class="diff">���Τ褦��</ins>ɽ������ޤ���</li>
		  <li>������줿�Ԥ�<del class="diff">���Τ褦��</del>ɽ������ޤ���</li>
		</ul>
		<pre>$diff</pre>
	|;
	
	if($wiki->can_modify_page($pagename) && $rollback){
		$buf .= qq|
			<form action="@{[$wiki->create_url()]}" method="POST">
				<input type="submit" value="���ΥС��������᤹"/>
				<input type="hidden" name="action" value="DIFF"/>
				<input type="hidden" name="page" value="@{[Util::escapeHTML($pagename)]}"/>
				<input type="hidden" name="rollback" value="@{[Util::escapeHTML($generation)]}"/>
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
	return "�ڡ������礭�����뤿�ẹʬ��ɽ���Ǥ��ޤ���" if($#msg1 >= 999);
	my @msg2 = split(/\n/,$source2);
	return "�ڡ������礭�����뤿�ẹʬ��ɽ���Ǥ��ޤ���" if($#msg2 >= 999);
	my $msgrefA = \@msg2;
	my $msgrefB = \@msg1;
	
	traverse_sequences($msgrefA, $msgrefB,
		{
			MATCH => sub {
				my ($a, $b) = @_;
				$diff_text .= Util::escapeHTML($msgrefA->[$a])."\n";
			},
			DISCARD_A => sub {
				my ($a, $b) = @_;
				$diff_text .= "<del class=\"diff\">".Util::escapeHTML($msgrefA->[$a])."</del>\n";
			},
			DISCARD_B => sub {
				my ($a, $b) = @_;
				$diff_text .= "<ins class=\"diff\">".Util::escapeHTML($msgrefB->[$b])."</ins>\n";
			}
		});
	
	return ($diff_text, $source2 ne "");
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
	$wiki->add_menu("��ʬ",$wiki->create_url({ action=>"DIFF",page=>$pagename }));
}

1;
