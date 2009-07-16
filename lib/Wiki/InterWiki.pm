###############################################################################
#
# InterWikiName�Υѡ���
#
###############################################################################
package Wiki::InterWiki;
use strict;

#==============================================================================
# ���󥹥ȥ饯��
#==============================================================================
sub new {
	my $class = shift;
	my $wiki  = shift;
	my $self  = {};

	$self->{wiki} = $wiki;
	$self->{interwiki} = [];
	bless $self,$class;

	$self->_parse();
	$self->_add_children($wiki);

	return bless $self;
}

#==============================================================================
# ��Wiki��InterWiki���ɲ�
#==============================================================================
sub _add_children {
	my $self = shift;
	my $wiki = shift;

	eval {
		my @children = $wiki->get_wiki_list();
		$self->_add_child($wiki,"",@children);
	}
}
#==============================================================================
# ��Wiki��InterWiki���ɲáʺƵ�Ū��call�����᥽�åɡ�
#==============================================================================
sub _add_child {
	my $self   = shift;
	my $wiki   = shift;
	my $parent = shift;
	my @items  = @_;
	my $prev   = "";

	foreach my $item (@items){
		if(ref($item) eq "ARRAY"){
			if($parent eq ""){
				$self->_add_child($wiki,"$prev",@$item);
			} else {
				$self->_add_child($wiki,"$parent/$prev",@$item);
			}
		} else {
			if($parent eq ""){
				$self->add_inter_wiki($wiki->config('script_name')."/$item?page=","$item");
			} else {
				$self->add_inter_wiki($wiki->config('script_name')."/$parent/$item?page=","$parent/$item");
			}
			$prev = $item;
		}
	}
}

#==============================================================================
# �ѡ����ʥ��󥹥ȥ饯������ƤФ�ޤ���
#==============================================================================
sub _parse {
	my $self = shift;
	my $wiki = $self->{wiki};
	if($wiki->page_exists("InterWikiName")){
		my $source = $wiki->get_page("InterWikiName");
		$source =~ s/\r//g;
		my @lines = split(/\n/,$source);
		foreach my $line (@lines){
			if(index($line,"*")==0){
				$self->_parse_line($line);
			}
		}
	}
}

#==============================================================================
# ���Ԥ�ѡ���
#==============================================================================
sub _parse_line {
	my $self   = shift;
	my $source = shift;
	# ��̾���
	if ($source =~ /\[([^\[]+?)\|((http|https|ftp|mailto):[\w\.,%~^+\-%\/\?\(\)!\$&=:;\*#\@']*)\]\s*([\w\-]+)/
	 || $source =~ /\[([^\[]+?)\|((file:[^\[\]]*))\]\s*([\w\-]+)/
	 || $source =~ /\[([^\[]+?)\|((\/|\.\/|\.\.\/)+[\w\.,%~^+\-%\/\?\(\)!\$&=:;\*#\@']*)\]\s*([\w\-]+)/) {
		my $label = $1;
		my $url   = $2;
		my $enc   = $4;
		$self->add_inter_wiki($url,$label,$enc);
	}
	# ʸ�������ɤλ���ʤ�
	elsif ($source =~ /\[([^\[]+?)\|((http|https|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!\$&=:;\*#\@']*)\]/
	    || $source =~ /\[([^\[]+?)\|(file:[^\[\]]*)\]/
	    || $source =~ /\[([^\[]+?)\|((\/|\.\/|\.\.\/)+[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!\$&=:;\*#\@']*)\]/) {
		my $label = $1;
		my $url   = $2;
		my $enc   = "";
		$self->add_inter_wiki($url,$label,$enc);
	}
	# Ǥ�դ�URL���
	elsif ($source =~ /\[([^\[]+?)\|(.+?)\]\s*([\w\-]+)/) {
		my $label = $1;
		my $url   = $2;
		my $enc   = $3;
		$self->add_inter_wiki($url,$label,$enc);
	}
	# Ǥ�դ�URL���(ʸ�������ɤλ���ʤ�)
	elsif ($source =~ /\[([^\[]+?)\|(.+?)\]/) {
		my $label = $1;
		my $url   = $2;
		my $enc   = "";
		$self->add_inter_wiki($url,$label,$enc);

	}
}

#==============================================================================
# InterWikiName���ɲ�
#==============================================================================
sub add_inter_wiki {
	my $self  = shift;
	my $url   = shift;
	my $label = shift;
	my $enc   = shift;

	push(@{$self->{interwiki}},{label=>$label,quote=>quotemeta($label),url=>$url,enc=>$enc});
}

#==============================================================================
# InterWikiName���ޤޤ�뤫�ɤ��������å�
#==============================================================================
sub exists_interwiki {
	my $self = shift;
	my $str  = shift;

	return 0 if (not defined $str);

	# $str ����Ƭ�� InterWikiName �ˤʤꤦ��񼰤��ʤ���С������֤��ƽ�λ
	return 0 if (not $str =~ /^\[\[/);

	my @keywords = @{ $self->{interwiki} };

	# ������줿���Ƥ� InterWikiName �ˤĤ��Ʒ����֤���
	foreach my $keyword (@keywords) {
		my $label = $keyword->{quote};

		# ��̾�ʤ��� InterWikiName
		if ($str =~ /^\[\[$label:(.+?)\]\]/) {
			$self->{g_post} = $';
			my $enc   = $keyword->{enc};
			my $param = $1;
			$self->{g_label} = $keyword->{label}.':'.$param;
			if ($enc ne q{}) {
				&Jcode::convert(\$param, $enc);
			}
			$self->{g_url} = $keyword->{url}.Util::url_encode($param);
			return 1;
		}

		# ��̾����� InterWikiName
		elsif ($str =~ /^\[\[([^\[]+?)\|$label:(.+?)\]\]/) {
			$self->{g_post} = $';
			$self->{g_label} = $1;
			my $enc   = $keyword->{enc};
			my $param = $2;
			if ($enc ne q{}) {
				&Jcode::convert(\$param, $enc);
			}
			$self->{g_url} = $keyword->{url}.Util::url_encode($param);
			return 1;
		}
	}
	return 0;
}

1;
