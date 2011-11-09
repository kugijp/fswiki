################################################################################
# <p>
#   Wiki�ե����ޥåȤ�ʸ�����ѡ��������񼰤��б������եå��᥽�åɤθƤӽФ���Ԥ��ޤ���
#   Wiki::Parser��Ѿ����������Υեå��᥽�åɤ򥪡��С��饤�ɤ��뤳�Ȥ�Ǥ�դΥե����ޥåȤؤ��Ѵ�����ǽ�Ǥ���
# </p>
################################################################################
package Wiki::Parser;
use strict;
use Wiki::Keyword;
use Wiki::InterWiki;

$Wiki::Parser::keyword   = undef;
$Wiki::Parser::interwiki = undef;

#===============================================================================
# <p>
# ���󥹥ȥ饯����
# </p>
# <pre>
# my $parser = Wiki::HTMLParser-&gt;new($wiki);
# </pre>
#===============================================================================
sub new {
	my $class = shift;
	my $wiki  = shift;
	
	my $self = {};
	$self->{wiki} = $wiki;
	
	# Keyword��InterWiki�Ϲ�®���Τ���⥸�塼���ѿ��Ȥ����ݻ�����
	#�ʤ�����mod_perl+Farm�ξ��ϥ���ʤΤ����new�����
	if(exists $ENV{MOD_PERL}){
		$self->{interwiki} = Wiki::InterWiki->new($wiki);
		$self->{keyword}   = Wiki::Keyword->new($wiki,$self->{interwiki});
	} else {
		unless(defined($Wiki::Parser::keyword)){
			$Wiki::Parser::interwiki = Wiki::InterWiki->new($wiki);
			$Wiki::Parser::keyword   = Wiki::Keyword->new($wiki,$Wiki::Parser::interwiki);
		}
		$self->{interwiki} = $Wiki::Parser::interwiki;
		$self->{keyword}   = $Wiki::Parser::keyword;
	}
	
	$self->{dl_flag} = 0;
	$self->{dt} = "";
	$self->{dd} = "";
	
	return bless $self,$class;
}

#===============================================================================
# <p>
# �ѡ��������򳫻Ϥ��ޤ���
# </p>
# <pre>
# $parser-&gt;parse($source);
# </pre>
#===============================================================================
sub parse {
	my $self   = shift;
	my $source = shift;
	
	$self->start_parse;
	$source =~ s/\r//g;
	
	my @lines = split(/\n/,$source);
	
	foreach my $line (@lines){
		chomp $line;
		
		# ʣ���Ԥ�����
		$self->multi_explanation($line);
		
		my $word1 = substr($line,0,1);
		my $word2 = substr($line,0,2);
		my $word3 = substr($line,0,3);
		
		# ����
		if($line eq "" && !$self->{block}){
			$self->l_paragraph();
			next;
		}
		
		# �֥�å��񼰤Υ���������
		if($word2 eq "\\\\" || $word1 eq "\\"){
			my @obj = $self->parse_line(substr($line, 1));
			$self->l_text(\@obj);
			next;
		}
		
		# �ѥ饰��եץ饰����
		if($line =~ /^{{(.+}})$/){
			if(!$self->{block}){
				my $plugin = $self->{wiki}->parse_inline_plugin($1);
				my $info   = $self->{wiki}->get_plugin_info($plugin->{command});
				if($info->{TYPE} eq "paragraph"){
					$self->l_plugin($plugin);
				} else {
					my @obj = $self->parse_line($line);
					$self->l_text(\@obj);
				}
				next;
			}
		} elsif($line =~ /^{{(.+)$/){
			if ($self->{block}) {
				my $plugin = $self->{wiki}->parse_inline_plugin($1);
				my $info   = $self->{wiki}->get_plugin_info($plugin->{command});
				$self->{block}->{level}++ if($info->{TYPE} ne "inline");
				$self->{block}->{args}->[0] .= $line."\n";
				next;
			}
			my $plugin = $self->{wiki}->parse_inline_plugin($1);
			my $info   = $self->{wiki}->get_plugin_info($plugin->{command});
			if($info->{TYPE} eq "block"){
				unshift(@{$plugin->{args}}, "");
				$self->{block} = $plugin;
				$self->{block}->{level} = 0;
			} else {
				my @obj = $self->parse_line($line);
				$self->l_text(\@obj);
			}
			next;
		}
		if($self->{block}){
			if($line eq "}}"){
				if ($self->{block}->{level} > 0) {
					$self->{block}->{level}--;
					$self->{block}->{args}->[0] .= $line."\n";
					next;
				}
				my $plugin = $self->{block};
				delete($self->{block});
				$self->l_plugin($plugin);
			} else {
				$self->{block}->{args}->[0] .= $line."\n";
			}
			next;
		}
		
		# PRE
		if($word1 eq " " || $word1 eq "\t"){
			$self->l_verbatim($line);
			
		# ���Ф�
		} elsif($word3 eq "!!!"){
			my @obj = $self->parse_line(substr($line,3));
			$self->l_headline(1,\@obj);
			
		} elsif($word2 eq "!!"){
			my @obj = $self->parse_line(substr($line,2));
			$self->l_headline(2,\@obj);
			
		} elsif($word1 eq "!"){
			my @obj = $self->parse_line(substr($line,1));
			$self->l_headline(3,\@obj);

		# ����
		} elsif($word3 eq "***"){
			my @obj = $self->parse_line(substr($line,3));
			$self->l_list(3,\@obj);
			
		} elsif($word2 eq "**"){
			my @obj = $self->parse_line(substr($line,2));
			$self->l_list(2,\@obj);
			
		} elsif($word1 eq "*"){
			my @obj = $self->parse_line(substr($line,1));
			$self->l_list(1,\@obj);
			
		# �ֹ��դ�����
		} elsif($word3 eq "+++"){
			my @obj = $self->parse_line(substr($line,3));
			$self->l_numlist(3,\@obj);
			
		} elsif($word2 eq "++"){
			my @obj = $self->parse_line(substr($line,2));
			$self->l_numlist(2,\@obj);
			
		} elsif($word1 eq "+"){
			my @obj = $self->parse_line(substr($line,1));
			$self->l_numlist(1,\@obj);
			
		# ��ʿ��
		} elsif($line eq "----"){
			$self->l_line();
		
		# ����
		} elsif($word2 eq '""'){
			my @obj = $self->parse_line(substr($line,2));
			$self->l_quotation(\@obj);
			
		# ����
		} elsif(index($line,":")==0 && index($line,":",1)!=-1){
			if(index($line,":::")==0){
				$self->{dd} .= substr($line,3);
				next;
			}
			if($self->{dt} ne "" || $self->{dd} ne ""){
				$self->multi_explanation;
			}
			if(index($line,"::")==0){
				$self->{dt} = substr($line,2);
				$self->{dl_flag} = 1;
				next;
			}
			my $dt = substr($line,1,index($line,":",1)-1);
			my $dd = substr($line,index($line,":",1)+1);
			my @obj1 = $self->parse_line($dt);
			my @obj2 = $self->parse_line($dd);
			$self->l_explanation(\@obj1,\@obj2);
			
		# �ơ��֥�
		} elsif($word1 eq ","){
			if($line =~ /,$/){
				$line .= " ";
			}
			my @spl = map {/^"(.*)"$/ ? scalar($_ = $1, s/\"\"/\"/g, $_) : $_}
						  ($line =~ /,\s*(\"[^\"]*(?:\"\"[^\"]*)*\"|[^,]*)/g);
			my @array;
			foreach my $value (@spl){
				my @cell = $self->parse_line($value);
				push @array,\@cell;
			}
			$self->l_table(\@array);
			
		# ������
		} elsif($word2 eq "//"){
		
		# ����ʤ���
		} else {
			my @obj = $self->parse_line($line);
			$self->l_text(\@obj);
		}
	}
	
	# ʣ���Ԥ�����
	$self->multi_explanation;
	
	# �ѡ�����Υ֥�å��ץ饰���󤬤��ä���硢�Ȥꤢ����ɾ�����Ƥ�����
	if($self->{block}){
		$self->l_plugin($self->{block});
		delete($self->{block});
	}
	
	$self->end_parse;
}

#===============================================================================
# <p>
# ʣ���Ԥ�����ʸ��������ޤ���
# </p>
#===============================================================================
sub multi_explanation {
	my $self = shift;
	my $line = shift;
	if($self->{dl_flag}==1 && (index($line,":")!=0 || !defined($line))){
		my @obj1 = $self->parse_line($self->{dt});
		my @obj2 = $self->parse_line($self->{dd});
		$self->l_explanation(\@obj1,\@obj2);
		$self->{dl_flag} = 0;
		$self->{dt} = "";
		$self->{dd} = "";
	}
}

#===============================================================================
# <p>
# ����ʬ��ѡ������ޤ���parse�᥽�åɤ��椫��ɬ�פ˱����ƸƤӽФ���ޤ���
# </p>
#===============================================================================
sub parse_line {
	my ($self, $source) = @_;

	return () if (not defined $source);

	my @array = ();
	my $pre   = q{};
	my @parsed = ();

	# $source �����ˤʤ�ޤǷ����֤���
	SOURCE:
	while ($source ne q{}) {

		# �ɤΥ���饤�� Wiki �񼰤���Ƭ�ˤ� match ���ʤ����
		if (!($source =~ /^(.*?)((?:{{|\[\[?|https?:|mailto:|f(?:tp:|ile:)|'''?|==|__|<<).*)$/)) {
			# ������ɸ������ִ������Τ߼»ܤ��ƽ�λ����
			push @array, $self->_parse_line_keyword($pre . $source);
			return @array;
		}

		$pre   .= $1;	# match ���ʤ��ä���Ƭ��ʬ��ί��Ƥ����Ƹ�ǽ�������
		$source = $2;	# match ��ʬ�ϸ�³�����ˤƾܺ٥����å���Ԥ�
		@parsed = ();

		# �ץ饰����
		if ($source =~ /^{{/) {
			$source = $';
			my $plugin = $self->{wiki}->parse_inline_plugin($source);
			unless($plugin){
				push @parsed, '{{';
				push @parsed, $self->parse_line($source);
			} else {
				my $info = $self->{wiki}->get_plugin_info($plugin->{command});
				if($info->{TYPE} eq "inline"){
					push @parsed, $self->plugin($plugin);
				} else {
					push @parsed, $self->parse_line("<<".$plugin->{command}."�ץ饰�����¸�ߤ��ޤ���>>");
				}
				if ($source ne "") {
					$source = $plugin->{post};
				}
			}
		}

		# InterWikiName
		elsif ($self->{interwiki}->exists_interwiki($source)) {
			my $label = $self->{interwiki}->{g_label};
			my $url   = $self->{interwiki}->{g_url};
			$source = $self->{interwiki}->{g_post};
			push @parsed, $self->url_anchor($url, $label);
		}

		# �ڡ�����̾���
		elsif ($source =~ /^\[\[([^\[]+?)\|([^\|\[]+?)\]\]/) {
			my $label = $1;
			my $page  = $2;
			$source = $';
			push @parsed, $self->wiki_anchor($page, $label);
		}

		# URL��̾���
		elsif ($source
			=~ /^\[([^\[]+?)\|((?:http|https|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!&=:;\*#\@'\$]*)\]/
			|| $source =~ /^\[([^\[]+?)\|(file:[^\[\]]*)\]/
			|| $source
			=~ /^\[([^\[]+?)\|((?:\/|\.\/|\.\.\/)+[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!&=:;\*#\@'\$]*)\]/
			)
		{
			my $label = $1;
			my $url   = $2;
			$source = $';
			if (   index($url, q{"}) >= 0
				|| index($url, '><') >= 0
				|| index($url, 'javascript:') >= 0)
			{
				push @parsed, $self->parse_line('<<�����ʥ�󥯤Ǥ���>>');
			}
			else {
				push @parsed, $self->url_anchor($url, $label);
			}
		}

		# URL���
		elsif ($source
			=~ /^(?:https?|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!&=:;\*#\@'\$]*/
			|| $source =~ /^file:[^\[\]]*/)
		{
			my $url = $&;
			$source = $';
			if (   index($url, q{"}) >= 0
				|| index($url, '><') >= 0
				|| index($url, 'javascript:') >= 0)
			{
				push @parsed, $self->parse_line('<<�����ʥ�󥯤Ǥ���>>');
			}
			else {
				push @parsed, $self->url_anchor($url);
			}
		}

		# �ڡ������
		elsif ($source =~ /^\[\[([^\|]+?)\]\]/) {
			my $page = $1;
			$source = $';
			push @parsed, $self->wiki_anchor($page);
		}

		# Ǥ�դ�URL���
		elsif ($source =~ /^\[([^\[]+?)\|(.+?)\]/) {
			my $label = $1;
			my $url   = $2;
			$source = $';
			if (   index($url, q{"}) >= 0
				|| index($url, '><') >= 0
				|| index($url, 'javascript:') >= 0)
			{
				push @parsed, $self->parse_line('<<�����ʥ�󥯤Ǥ���>>');
			}
			else {

				# URI�����
				my $wiki = $self->{wiki};
				my $uri  = $wiki->config('server_host');
				if ($uri eq q{}) {
					$uri = $wiki->get_CGI()->url(-path_info => 1);
				}
				else {
					$uri
						= $uri
						. $wiki->get_CGI->url(-absolute => 1)
						. $wiki->get_CGI()->path_info();
				}
				push @parsed, $self->url_anchor($uri . '/../' . $url, $label);
			}
		}

		# �ܡ���ɡ�������å������ä���������
		elsif ($source =~ /^('''?|==|__)(.+?)\1/) {
			my $type  = $1;
			my $label = $2;
			$source = $';
			if ($type eq q{'''}) {
				push @parsed, $self->bold($label);
			}
			elsif ($type eq q{__}) {
				push @parsed, $self->underline($label);
			}
			elsif ($type eq q{''}) {
				push @parsed, $self->italic($label);
			}
			else {							   ## elsif ($type eq q{==}) {
				push @parsed, $self->denialline($label);
			}
		}

		# ���顼��å�����
		elsif ($source =~ /^<<(.+?)>>/) {
			my $label = $1;
			$source = $';
			push @parsed, $self->error($label);
		}

		# ����饤�� Wiki �����Τˤ� macth ���ʤ��ä��Ȥ�
		else {
			# 1 ʸ���ʤࡣ
			if ($source =~ /^(.)/) {
				$pre .= $1;
				$source = $';
			}
			
			# parse ��̤� @array ����¸������������Ф��Ʒ����֤���
			next SOURCE;
		}

		# ����饤�� Wiki �����Τ� macth �������
		# parse ��̤� @array ����¸���������

		# �⤷ $pre ��ί�ޤäƤ���ʤ顢������ɤν�����»ܡ�
		if ($pre ne q{}) {
			push @array, $self->_parse_line_keyword($pre);
			$pre = q{};
		}

		push @array, @parsed;
	}

	# �⤷ $pre ��ί�ޤäƤ���ʤ顢������ɤν�����»ܡ�
	if ($pre ne q{}) {
		push @array, $self->_parse_line_keyword($pre);
	}

	return @array;
}

#========================================================================
# <p>
# parse_line() ����ƤӽФ��졢������ɤθ������ִ�������Ԥ��ޤ���
# </p>
#========================================================================
sub _parse_line_keyword {
	my $self   = shift;
	my $source = shift;

	return () if (not defined $source);

	my @array = ();

	# $source �����ˤʤ�ޤǷ����֤���
	while ($source ne q{}) {

		# �������
		if ($self->{keyword}->exists_keyword($source)) {
			my $pre   = $self->{keyword}->{g_pre};
			my $label = $self->{keyword}->{g_label};
			my $url   = $self->{keyword}->{g_url};
			my $page  = $self->{keyword}->{g_page};
			$source = $self->{keyword}->{g_post};
			if ($pre ne q{}) {
				push @array, $self->_parse_line_keyword($pre);
			}
			if (defined($url) && $url ne q{}) {
				push @array, $self->url_anchor($url, $label);
			} else {
				push @array, $self->wiki_anchor($page, $label);
			}

		}

		# WikiName
		elsif ($self->{wiki}->config('wikiname') == 1 && $source =~ /[A-Z]+?[a-z]+?(?:[A-Z]+?[a-z]+)+/) {
			my $pre  = $`;
			my $page = $&;
			$source  = $';
			if ($pre ne q{}) {
				push @array, $self->_parse_line_keyword($pre);
			}
			push @array, $self->wiki_anchor($page);
		}

		# ������ɤ� WikiName �⸫�Ĥ���ʤ��ä��Ȥ�
		else {
			push @array, $self->text($source);
			return @array;
		}
	}
	return @array;
}

#===============================================================================
# <p>
# �ѡ����򳫻����˸ƤӽФ���ޤ���
# ���֥��饹��ɬ�פʽ�����������ϥ����С��饤�ɤ��Ƥ���������
# </p>
#===============================================================================
sub start_parse {}

#===============================================================================
# <p>
# �ѡ�����λ��˸ƤӽФ���ޤ���
# ���֥��饹��ɬ�פʽ�����������ϥ����С��饤�ɤ��Ƥ���������
# </p>
#===============================================================================
sub end_parse {}

#===============================================================================
# <p>
# URL���󥫤˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub url_anchor {}

#===============================================================================
# <p>
# �ڡ���̾���󥫤˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub wiki_anchor {}

#===============================================================================
# <p>
# ������å��˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub italic {}

#===============================================================================
# <p>
# �ܡ���ɤ˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub bold {}

#===============================================================================
# <p>
# �����˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub underline {}

#===============================================================================
# <p>
# �Ǥ��ä����˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub denialline {}

#===============================================================================
# <p>
# �ץ饰����˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub plugin {}

#===============================================================================
# <p>
# �ƥ����Ȥ˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub text{}

#===============================================================================
# <p>
# ���ܤ˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub l_list {}

#===============================================================================
# <p>
# �ֹ��դ����ܤ˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub l_numlist {}

#===============================================================================
# <p>
# ���Ф��˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub l_headline {}

#===============================================================================
# <p>
# PRE�����˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub l_verbatim {}

#===============================================================================
# <p>
# ��ʿ���˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub l_line {}

#===============================================================================
# <p>
# �äˤʤˤ�ʤ��Ԥ˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub l_text {}

#===============================================================================
# <p>
# �����˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub l_explanation {}

#===============================================================================
# <p>
# ���Ѥ˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub l_quotation {}

#===============================================================================
# <p>
# �ѥ饰��դζ��ڤ�˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub l_paragraph {}

#===============================================================================
# <p>
# �ơ��֥�˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub l_table {}

#===============================================================================
# <p>
# �ѥ饰��եץ饰����˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub l_plugin {}

#===============================================================================
# <p>
# �����˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub l_image {}

#===============================================================================
# <p>
# ���顼��å������˥ޥå��������˸ƤӽФ���ޤ���
# ���֥��饹�ˤƽ�����������ޤ���
# </p>
#===============================================================================
sub error {}

1;
