###############################################################################
#
# HTML�ѡ���
#
###############################################################################
package Wiki::HTMLParser;
use Wiki::Parser;
use vars qw(@ISA);
use strict;

@ISA = qw(Wiki::Parser);
#==============================================================================
# ���󥹥ȥ饯��
#==============================================================================
sub new {
	my $class   = shift;
	my $wiki    = shift;
	my $mainflg = shift;
	
	if(!defined($mainflg) || $mainflg eq ""){ $mainflg = 0; }
	
	my $self = Wiki::Parser->new($wiki);
	
	$self->{html}  = "";
	$self->{pre}   = "";
	$self->{quote} = "";
	$self->{table} = 0;
	$self->{level} = 0;
	$self->{para}  = 0;
	$self->{p_cnt} = 0;
	$self->{main}  = $mainflg;
	return bless $self,$class;
}

#==============================================================================
# �ꥹ��
#==============================================================================
sub l_list {
	my $self  = shift;
	my $level = shift;
	my $obj   = shift;
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	}
	
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	my $html = join("",@$obj);

	if($level > $self->{level}){
		while($level != $self->{level}){
			$self->{html} .= "<ul>\n";
			push(@{$self->{close_list}},"</ul>\n");
			$self->{level}++;
		}
	} elsif($level <= $self->{level}){
		while($level-1 != $self->{level}){
			if($self->{'list_close_'.$self->{level}} == 1){
				$self->{html} .= "</li>\n";
				$self->{'list_close_'.$self->{level}} = 0;
			}
			if($level == $self->{level}){
				last;
			}
			$self->{html} .= pop(@{$self->{close_list}});
			$self->{level}--;
		}
	}
	
	$self->{html} .= "<li>".$html;
	$self->{'list_close_'.$level} = 1;
}

#==============================================================================
# �ֹ��դ��ꥹ��
#==============================================================================
sub l_numlist {
	my $self  = shift;
	my $level = shift;
	my $obj   = shift;
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	}
	
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	my $html = join("",@$obj);
	
	if($level > $self->{level}){
		while($level != $self->{level}){
			$self->{html} .= "<ol>\n";
			push(@{$self->{close_list}},"</ol>\n");
			$self->{level}++;
		}
	} elsif($level <= $self->{level}){
		while($level-1 != $self->{level}){
			if($self->{'list_close_'.$self->{level}} == 1){
				$self->{html} .= "</li>\n";
				$self->{'list_close_'.$self->{level}} = 0;
			}
			if($level == $self->{level}){
				last;
			}
			$self->{html} .= pop(@{$self->{close_list}});
			$self->{level}--;
		}
	}
	
	$self->{html} .= "<li>".$html;
	$self->{'list_close_'.$level} = 1;
}

#==============================================================================
# �ꥹ�Ȥν�λ
#==============================================================================
sub end_list {
	my $self  = shift;
	while($self->{level} != 0){
		if($self->{'list_close_'.($self->{level})} == 1){
			$self->{html} .= "</ll>\n";
		}
		$self->{html} .= pop(@{$self->{close_list}});
		$self->{level}--;
	}
}

#==============================================================================
# �إåɥ饤��
#==============================================================================
sub l_headline {
	my $self  = shift;
	my $level = shift;
	my $obj   = shift;
	my $wiki  = $self->{wiki};
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	}
	
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	my $html  = join("",@$obj);
	
	# �ᥤ���ɽ���ΰ�Ǥʤ��Ȥ�
	if(!$self->{main}){
		$self->{html} .= "<h".($level+1).">".$html."</h".($level+1).">\n";

	# �ᥤ���ɽ���ΰ�ξ��ϥ��󥫤����
	} else {
		if($level==2){
			$self->{html} .= "<h".($level+1)."><a name=\"p".$self->{p_cnt}."\"><span class=\"sanchor\">&nbsp;</span>".
			                 $html."</a></h".($level+1).">\n";
		} else {
			$self->{html} .= "<h".($level+1)."><a name=\"p".$self->{p_cnt}."\">".$html."</a></h".($level+1).">\n";
		}
		# �ѡ����Խ���ON�����Խ���ǽ�ʾ����Խ����󥫤����
		if($self->{no_partedit}!=1){
			my $page = $wiki->get_CGI()->param("page");
			my $part_edit = "";
			# �ѡ��ȥ�󥯤�ON�ξ��ϰ�ư�ѤΥ��󥫤����
			if ($wiki->config("partlink") == 1) {
				$part_edit .= "<a class=\"partedit\" href=\"#\">TOP</a> ";
				$part_edit .= "<a class=\"partedit\" href=\"#p".($self->{p_cnt} - 1)."\">��</a> ";
				$part_edit .= "<a class=\"partedit\" href=\"#p".($self->{p_cnt} + 1)."\">��</a> ";
			}
			# �ѡ����Խ���ON�����Խ���ǽ�ʾ����Խ����󥫤����
			if($wiki->config("partedit")==1 && $wiki->can_modify_page($page)){
				unless(defined($self->{partedit}->{$page})){
					$self->{partedit}->{$page} = 0;
				} else {
					$self->{partedit}->{$page}++;
				}
				# InterWiki�����ξ��
				my $full = $page;
				my $path = $self->{wiki}->config('script_name');
				if(index($page,":")!=-1){
					($path,$page) = split(/:/,$page);
					$path = $self->{wiki}->config('script_name')."/$path";
				}
				$part_edit .= "<a class=\"partedit\" href=\"$path?action=EDIT".
				              "&amp;page=".&Util::url_encode($page).
				              "&amp;artno=".$self->{partedit}->{$full}."\" rel=\"nofollow\">�Խ�</a>";
			}
			if($part_edit ne ""){
				$self->{html} .= "<div class=\"partedit\">$part_edit</div>\n";
			}
		}
		
	}
	$self->{p_cnt}++;
}

#==============================================================================
# ��ʿ��
#==============================================================================
sub l_line {
	my $self = shift;
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	}
	
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	$self->{html} .= "<hr>\n";
}

#==============================================================================
# ������ڤ�
#==============================================================================
sub l_paragraph {
	my $self = shift;
	
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	} elsif($self->{wiki}->config('br_mode')==1){
		$self->{html} .= "<br>\n";
	}
}

#==============================================================================
# �����ѥƥ�����
#==============================================================================
sub l_verbatim {
	my $self  = shift;
	my $text  = shift;
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	}
	
	$self->end_list;
	$self->end_table;
	$self->end_quote;
	
	$text =~ s/^\s//;
	$self->{pre} .= Util::escapeHTML($text)."\n";
}

sub end_verbatim {
	my $self  = shift;
	if($self->{pre} ne ""){
		$self->{html} .= "<pre>".$self->{pre}."</pre>\n";
		$self->{pre} = "";
	}
}

#==============================================================================
# �ơ��֥�
#==============================================================================
sub l_table {
	my $self = shift;
	my $row  = shift;
	$self->end_list;
	$self->end_verbatim;
	$self->end_quote;
	
	if($self->{table}==0){
		$self->{table}=1;
		$self->{html} .= "<table>\n";
		$self->{html} .= "<tr>\n";
		foreach(@$row){
			my $html = join("",@$_);
			$self->{html} .= "<th>".$html."</th>\n";
		}
		$self->{html} .= "</tr>\n";
	} else {
		$self->{table}=2;
		$self->{html} .= "<tr>\n";
		foreach(@$row){
			my $html = join("",@$_);
			$self->{html} .= "<td>".$html."</td>\n";
		}
		$self->{html} .= "</tr>\n";
	}
}

sub end_table {
	my $self = shift;
	if($self->{table}!=0){
		$self->{table} = 0;
		$self->{html} .= "</table>\n";
	}
}

#==============================================================================
# �ѡ�����λ���ν���
#==============================================================================
sub end_parse {
	my $self = shift;
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	}
}

#==============================================================================
# �Խ񼰤˳������ʤ���
#==============================================================================
sub l_text {
	my $self = shift;
	my $obj  = shift;
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	my $html = join("",@$obj);
	
	if($self->{para}==0){
		$self->{html} .= "<p>";
		$self->{para} = 1;
	}
	$self->{html} .= $html;
	
	# br�⡼�ɤ����ꤵ��Ƥ������<br>��­��
	if($self->{wiki}->config('br_mode')==1){
		$self->{html} .= "<br>\n";
	}
}

#==============================================================================
# ����
#==============================================================================
sub l_quotation {
	my $self = shift;
	my $obj  = shift;
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	my $html = join("",@$obj);
	$self->{quote} .= "<p>".$html."</p>\n";
}

sub end_quote {
	my $self = shift;
	if($self->{quote} ne ""){
		$self->{html} .= "<blockquote>".$self->{quote}."</blockquote>\n";
		$self->{quote} = "";
	}
}

#==============================================================================
# ����
#==============================================================================
sub l_explanation {
	my $self = shift;
	my $obj1 = shift;
	my $obj2 = shift;
	
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	my $html1 = join("",@$obj1);
	my $html2 = join("",@$obj2);
	
	$self->{html} .= "<dl>\n<dt>".$html1."</dt>\n<dd>".$html2."</dd>\n</dl>\n";
}

#==============================================================================
# �ܡ����
#==============================================================================
sub bold {
	my $self = shift;
	my $text = shift;
	return "<strong>".join("",$self->parse_line($text))."</strong>";
}

#==============================================================================
# ������å�
#==============================================================================
sub italic {
	my $self = shift;
	my $text = shift;
	return "<em>".join("",$self->parse_line($text))."</em>";
}

#==============================================================================
# ����
#==============================================================================
sub underline {
	my $self = shift;
	my $text = shift;
	return "<ins>".join("",$self->parse_line($text))."</ins>";
}

#==============================================================================
# �Ǥ��ä���
#==============================================================================
sub denialline {
	my $self = shift;
	my $text = shift;
	return "<del>".join("",$self->parse_line($text))."</del>";
}

#==============================================================================
# URL����
#==============================================================================
sub url_anchor {
	my $self = shift;
	my $url  = shift;
	my $name = shift;
	
	if($name eq ""){
		$name = $url;
	}
	
	if($url eq $name && $url=~/\.(gif|jpg|jpeg|bmp|png)$/i && $self->{'wiki'}->config('display_image')==1){
		return "<img src=\"".$url."\">";
	} else {
		if($self->{wiki}->config('open_new_window')==1 &&
			($self->{wiki}->config('inside_same_window')==0 ||
			($self->{wiki}->config('inside_same_window')==1 && index($url,'://') > 0))){
			return "<a href=\"$url\" target=\"_blank\">".Util::escapeHTML($name)."</a>";
		} else {
			return "<a href=\"$url\">".Util::escapeHTML($name)."</a>";
		}
	}
}

#==============================================================================
# Wiki�ڡ����ؤΥ���
#==============================================================================
sub wiki_anchor {
	my $self = shift;
	my $page = shift;
	my $name = shift;
	
	if(!defined($name) || $name eq ""){
		$name = $page;
	}
	if($self->{wiki}->page_exists($page)){
		return "<a href=\"".$self->{wiki}->create_page_url($page)."\" class=\"wikipage\">".
		       &Util::escapeHTML($name)."</a>";
	} else {
		return "<span class=\"nopage\">".&Util::escapeHTML($name)."</span>".
		       "<a href=\"".$self->{wiki}->create_page_url($page)."\">?</a>";
	}
}

#==============================================================================
# �����Υƥ�����
#==============================================================================
sub text {
	my $self = shift;
	my $text = shift;
	return &Util::escapeHTML($text);
}

#==============================================================================
# �ץ饰����
#==============================================================================
sub plugin {
	my $self   = shift;
	my $plugin = shift;
	
	my @result = $self->{wiki}->process_plugin($plugin,$self);
	return @result;
}

#==============================================================================
# �ѥ饰��եץ饰����
#==============================================================================
sub l_plugin {
	my $self   = shift;
	my $plugin = shift;
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	}
	
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	my $result = $self->{wiki}->process_plugin($plugin,$self);
	if(defined($result) && $result ne ""){
		$self->{html} .= $result;
	}
}

#==============================================================================
# ���᡼��
#==============================================================================
sub l_image {
	my $self = shift;
	my $page = shift;
	my $file = shift;
	my $wiki = $self->{wiki};
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	}
	
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	$self->{html} .= "<div><img src=\"".$wiki->create_url({action=>"ATTACH",page=>$page,file=>$file})."\"></div>\n";
}

#==============================================================================
# ���顼��å�����
#==============================================================================
sub error {
	my $self  = shift;
	my $label = shift;
	
	return "<span class=\"error\">".Util::escapeHTML($label)."</span>";
}

1;
