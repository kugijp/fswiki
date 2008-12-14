###############################################################################
#
# <p>bugtrack�ץ饰�������Ƥ��줿�Х��ΰ�����ɽ�����ޤ���</p>
# <p>
#   ��2������form��Ϳ����Ⱦ����ѹ��ѤΥե����ब������ޤ���
# </p>
# <pre>
# {{buglist �ץ�������̾[,form]}}
# </pre>
#
###############################################################################
package plugin::bugtrack::BugList;
use strict;
use plugin::bugtrack::BugState;
#==============================================================================
# ���󥹥ȥ饯��
#==============================================================================
sub new {
	my $class = shift;
	my $self  = {};
	return bless $self,$class;
}

#==============================================================================
# ����饤��᥽�å�
#==============================================================================
sub paragraph {
	my $self    = shift;
	my $wiki    = shift;
	my $project = shift;
	my $form    = shift;

	if($project eq ""){
		return &Util::paragraph_error("�ץ�������̾�����ꤵ��Ƥ��ޤ���");
	}

	# form�ʳ���ʸ�����̵��
	if($form ne "form"){
	    $form = 0;
	}
	
	my @pages = $wiki->get_page_list();
	my $bugs  = {};
	my $quote = quotemeta($project);
	foreach(@pages){
		if($_ =~ /^BugTrack-$quote\/([0-9]+)$/){
			my $pagename = $_;
			my $count    = $1;
			my $category = "";
			my $status   = "";
			my $priority = "";
			my $name     = "";
			my $subject  = "";
			my $date     = "";
			
			my $page = $wiki->get_page($pagename);
			my @lines = split(/\n/,$page);
			my $first = 0;
			foreach(@lines){
				$_ =~ s/\r//;
				if($first==0 && $_ =~ /^!!!(.*)/){
					$subject = $1;
					$first = 1;
				} elsif($_ =~ /^\*���ƥ��ꡧ\s*(.*)/){
					$category = $1;
				} elsif($_ =~ /^\*ͥ���١�\s*(.*)/){
					$priority = $1;
				} elsif($_ =~ /^\*���֡�\s*(.*)/){
					$status = $1;
				} elsif($_ =~ /^\*��Ƽԡ�\s*(.*)/){
					$name = $1;
				} elsif($_ =~ /^\*������\s*(.*)/){
					$date = $1;
				}
			}
			my $bug = {page     =>$pagename,
			           count    =>$count,
			           category =>$category,
			           status   =>$status,
			           priority =>$priority,
			           name     =>$name,
			           date     =>$date,
			           subject  =>$subject,
			           form     =>$form };
			
			push(@{$bugs->{$status}},$bug);
		}
	}
	
	my $buf = "";
	
	# ���ޥ�����
	my $bug_teian    = 0;
	my $bug_chakushu = 0;
	my $bug_kanryo   = 0;
	my $bug_released = 0;
	my $bug_horyu    = 0;
	my $bug_kyakka   = 0;
	
	$bug_teian    = @{$bugs->{"���"}}       if(defined($bugs->{"���"}));
	$bug_chakushu = @{$bugs->{"���"}}       if(defined($bugs->{"���"}));
	$bug_kanryo   = @{$bugs->{"��λ"}}       if(defined($bugs->{"��λ"}));
	$bug_released = @{$bugs->{"��꡼����"}} if(defined($bugs->{"��꡼����"}));
	$bug_horyu    = @{$bugs->{"��α"}}       if(defined($bugs->{"��α"}));
	$bug_kyakka   = @{$bugs->{"�Ѳ�"}}       if(defined($bugs->{"�Ѳ�"}));
	my $bug_count = $bug_teian + $bug_chakushu + $bug_kanryo + $bug_released + $bug_horyu + $bug_kyakka;
	
	$buf .= "<p>��ơ�$bug_teian / ��ꡧ$bug_chakushu / ��λ��$bug_kanryo / ��꡼���ѡ�$bug_released ".
	        "/ ��α��$bug_horyu / �Ѳ���$bug_kyakka / ��ס�$bug_count</p>\n";
	
	# ���������
	$buf .= "<table border>\n".
	        "  <tr>\n".
	        "    <th><br></th>\n".
	        "    <th>���ƥ���</th>\n".
	        "    <th>ͥ����</th>\n".
	        "    <th>����</th>\n".
	        "    <th>��Ƽ�</th>\n".
	        "    <th>���ޥ�</th>\n".
	        "  </tr>\n";
	
	my $tmp = $buf;
	
	$buf .= make_row(@{$bugs->{"���"}}       ,"#FFDDDD",$wiki);
	$buf .= make_row(@{$bugs->{"���"}}       ,"#FFFFDD",$wiki);
	$buf .= make_row(@{$bugs->{"��λ"}}       ,"#DDFFDD",$wiki);
	$buf .= make_row(@{$bugs->{"��꡼����"}} ,"#DDDDFF",$wiki);
	$buf .= make_row(@{$bugs->{"��α"}}       ,"#DDDDDD",$wiki);
	$buf .= make_row(@{$bugs->{"�Ѳ�"}}       ,"#FFFFFF",$wiki);
	
	if($buf eq $tmp){
		$buf .= "  <tr><td colspan=\"6\" align=\"center\">�Х���ݡ��ȤϤ���ޤ���</td></tr>\n";
	}
	
	return $buf .= "</table>\n";
}

#==============================================================================
# ����ʬ�Υǡ�������Ϥ��������Ѵؿ�
#==============================================================================
sub make_row {
	my $wiki  = pop;
	my $color = pop;
	my @row   = sort {$b->{count}<=>$a->{count}} @_;
	my $buf = "";
	
	foreach(@row){
		$buf .= "  <tr bgcolor=\"$color\">\n".
		        "    <td><a href=\"".$wiki->create_page_url($_->{page})."\">".&Util::escapeHTML($_->{page})."</a></td>\n".
		        "    <td>".&Util::escapeHTML($_->{category})."</td>\n".
		        "    <td>".&Util::escapeHTML($_->{priority})."</td>\n".
		        "    <td>".&Util::escapeHTML($_->{status})."</td>\n".
		        "    <td>".&Util::escapeHTML($_->{name})."</td>\n".
		        "    <td>".&Util::escapeHTML($_->{subject})."</td>\n".
		        "  </tr>\n";

		# �ե������ɽ������
		if($_->{form}){
		    my $page = $wiki->get_CGI->param("page");
		    my $source = $_->{page};
		    my $form = &plugin::bugtrack::BugState::make_form($wiki,$page,$source);
		    $buf .= "<tr bgcolor=\"$color\"><td colspan=\"6\">".$form."</td></tr>\n";
		}
	}
	return $buf;
}

#==============================================================================
# �����ȴؿ�
#==============================================================================
#sub by_count {
#	my $a_count = $a->{count};
#	my $b_count = $b->{count};
#	return $b_count <=> $a_count;
#}

1;
