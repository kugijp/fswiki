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
			$subject = Util::url_decode($subject);
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
	
	my $theme_uri = $wiki->config('theme_uri');
	my $buf = qq|
<script type="text/javascript" src="${theme_uri}/resources/jsdifflib/difflib.js"></script>
<script type="text/javascript" src="${theme_uri}/resources/jsdifflib/diffview.js"></script>
<link href="${theme_uri}/resources/jsdifflib/diffview.css" type="text/css" rel="stylesheet" />
<script type="text/javascript">
function diffUsingJS() {
    // get the baseText and newText values from the two textboxes, and split them into lines
    var base   = difflib.stringAsLines(document.getElementById("baseText").value);
    var newtxt = difflib.stringAsLines(document.getElementById("newText").value);

    // create a SequenceMatcher instance that diffs the two sets of lines
    var sm = new difflib.SequenceMatcher(base, newtxt);

    // get the opcodes from the SequenceMatcher instance
    // opcodes is a list of 3-tuples describing what changes should be made to the base text
    // in order to yield the new text
    var opcodes = sm.get_opcodes();
    var diffoutputdiv = document.getElementById("diffoutputdiv")
    while (diffoutputdiv.firstChild) diffoutputdiv.removeChild(diffoutputdiv.firstChild);

    // build the diff view and add it to the current DOM
    diffoutputdiv.appendChild(diffview.buildView({
        baseTextLines: base,
        newTextLines: newtxt,
        opcodes: opcodes,
        // set the display titles for each resource
        baseTextName: "Base Text",
        newTextName: "New Text",
        contextSize: null,
        viewType: 1 // 1 or 0
    }));
}
</script>
$diff
<div id="diffoutputdiv"/>
<script type="text/javascript">
  diffUsingJS();
</script>
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
	
	my $source2 = '';
	if($to ne ''){
		$source2 = $wiki->get_backup($page, $to);
	} else {
		$source2 = $wiki->get_page($page);
	}
	my $format  = $wiki->get_edit_format();
	
	$source1 = $wiki->convert_from_fswiki($source1, $format);
	$source2 = $wiki->convert_from_fswiki($source2, $format);
	
	return '<input id="newText" type="hidden" value="'.Util::escapeHTML($source1).'">'.
	       '<input id="baseText" type="hidden" value="'.Util::escapeHTML($source2).'">';
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
