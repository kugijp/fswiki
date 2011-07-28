###############################################################################
#
# ������ɥѡ���
#
###############################################################################
package Wiki::Keyword;
use strict;

# 1 ʸ���˥ޥå���������ɽ��
my $ascii	  = '[\x00-\x7F]';				  # ASCII	  �� 1 ʸ��
my $twoBytes   = '[\x8E\xA1-\xFE][\xA1-\xFE]';   # EUC 2 Byte �� 1 ʸ��
my $threeBytes = '\x8F[\xA1-\xFE][\xA1-\xFE]';   # EUC 3 Byte �� 1 ʸ��
my $AsciiOrEUC = "$ascii|$twoBytes|$threeBytes"; # ASCII/EUC  �� 1 ʸ��

my $keyword_cache  = 'keywords.cache';  # �Ť�������ɥ���å���ե�����
my $keyword_cache2 = 'keywords2.cache'; # ������������ɥ���å���ե�����

#==============================================================================
# ���󥹥ȥ饯��
#==============================================================================
sub new {
	my $class     = shift;
	my $wiki      = shift;
	my $interwiki = shift;
	my $self      = {};
	
	$self->{wiki}      = $wiki;
	$self->{keywords}  = [];
	$self->{interwiki} = $interwiki;
	
	$self = bless($self,$class);
	$self->load_keywords();
	
	return $self;
}

#==============================================================================
# ������ɤ��ޤޤ�뤫�ɤ��������å�
#==============================================================================
sub exists_keyword {
	my ($self, $str) = @_;

	my $regexp = $self->{'regexp'};
	return 0 if ($regexp eq q{});

	my $wiki   = $self->{wiki};
	$self->{g_pre} = q{};

	# $regexp �� qr/^((?:$AsciiOrEUC)*?)($keywords_regexp)/ ����������
	# $str �������������ɽ���˥ޥå������顢
	while ($str =~ /$regexp/) {
		$self->{g_pre} .= $1;
		$self->{g_post} = $';
		my $label = $self->{g_label} = $2;

		# �ޥå�����������ɤ��б����� url ��ڡ���̾�������̵����С�
		if (not exists $self->{'keyword'}->{$label}) {

			# ������ɤ��ڡ���̾�Ǳ�����ǽ�ʤ顢
			if ($wiki->page_exists($label) and $wiki->can_show($label)) {

				# �ڡ���̾�����ȥ��
				$self->{g_url}  = undef;
				$self->{g_page} = $label;
				return 1;
			}

			# ������ɤ��ڡ���̾�Ǥʤ��������Բ�ǽ�ʤ顢
			else {

				# 1 ʸ���ʤ�ƥ�����ɤ�Ƹ�����
				$label =~ /^($AsciiOrEUC)(.*)$/;
				$self->{g_pre} .= $1;
				$str = $2 . $self->{g_post};
			}
		}
		else {
			my $word = $self->{'keyword'}->{$label};

			# �ޥå�����������ɤ��б�����Τ� url �ʤ顢
			if ($word->{'type'} eq 'u') {

				# url ���
				$self->{g_url}  = $word->{'value'};
				$self->{g_page} = undef;
			}
			else {

				# wiki �ڡ������
				$self->{g_url}  = undef;
				$self->{g_page} = $word->{'value'};
			}
			return 1;
		}
	}
	return 0;
}

#==============================================================================
# ������ɤ򥭥�å���ե����뤫���ɤ߹���
#==============================================================================
sub load_keywords {
	my $self = shift;
	my $wiki = $self->{wiki};

	# ���ڡ��������ԲĤʤ顢���⤻���˽�λ��
	my $can_show_max = $wiki->_get_can_show_max();
	return if ($can_show_max < 0);

	my $keyword = $self->{'keyword'} = {};
	my $log_dir = $wiki->config('log_dir');
	my $cachefile = $log_dir . '/' . $keyword_cache2;
	$self->{'regexp_list'} = [];

	READ_CACHE: # ����å����ͭ��Ƚ�ꡢ�ڤ��ɹ���
	while (1) {

		# ����å��夬̵������ɹ��߽�����ȴ���롣
		last READ_CACHE if (not -e $cachefile);

		my $cache_time = (stat $cachefile)[9];
		my $pagelistfile = $log_dir . '/' . $Wiki::DefaultStorage::PAGE_LIST_FILE;

		# DefaultStorage �Υڡ���̾�������Ť���Х���å�������Ѥ��ʤ���
		last READ_CACHE if ($cache_time < (stat $pagelistfile)[9]);

		my $showlevel_file = $wiki->config('config_dir') . '/showlevel.log';

		# �������¥ǡ������Ť���Х���å�������Ѥ��ʤ���
		last READ_CACHE if ($cache_time < (stat $showlevel_file)[9]);

		my $keyword_file = $wiki->config('data_dir') . '/Keyword.wiki';

		# �����������ڡ������Ť���Х���å�������Ѥ��ʤ���
		last READ_CACHE if ($cache_time < (stat $keyword_file)[9]);

		# ������ɥ���å���ե����뤫���ɹ��ߡ�
		my $buf = Util::load_config_text(undef, $cachefile);
		my @list = split /\n/, $buf;
		my ($type, $label, $value);

		# �ǽ�� 3 �ԡ��ƥ桼��������Υ����������ɽ��
		foreach my $level (0 .. 2) {
			my $line = shift @list;
			($type, $label, $value) = split /\t/, $line;

			# �ե�����������۾�ʤ顢�ɹ��ߤ�λ��
			if ($type ne 'r' or $label + 0 != $level) {
				$self->{'regexp_list'} = [];
				last READ_CACHE;
			}
			push @{ $self->{'regexp_list'} }, $value;
		}

		# 4 ���ܰʹߡ�������ɤ� url �ޤ��� �ڡ���̾���б��ط����ɤ߹��ࡣ
		foreach my $line (@list) {
			($type, $label, $value) = split /\t/, $line;
			$keyword->{$label} = { 'type'  => $type, 'value' => $value, };
		}
		last READ_CACHE;
	}

	# ���λ����ǡ������������ɽ�����������Ƥʤ���С�
	if (not @{ $self->{'regexp_list'} }) {

		# ������ɥǡ�������������������ɥ���å���ե��������¸��
		$self->parse();
		$self->save_keywords();
	}

	# ���ߤΥ桼���θ��¤��б����륭���������ɽ���򥳥�ѥ��롣
	my $regexp = $self->{'regexp_list'}->[$can_show_max];
	$self->{'regexp'} = qr/^((?:$AsciiOrEUC)*?)($regexp)/;
}

#==============================================================================
# ������ɤΥ���å���ե�����򹹿�
#==============================================================================
sub save_keywords {
	my $self = shift;

	# FSWiki ɸ��Υ�����ɥ���å���⤳�Υ����ߥ󥰤Ǻ����
	my $log_dir = $self->{wiki}->config('log_dir');
	my $cache   = "$log_dir/$keyword_cache";
	unlink $cache if (-e $cache);

	# �ƥ桼��������Υ����������ɽ����Хåե����ɲá�
	my $buf = q{};
	foreach my $level (0 .. 2) {
		$buf .= "r\t$level\t" . $self->{'regexp_list'}->[$level] . "\n";
	}

	# ������ɤ� url �ޤ��ϥڡ���̾���б��ط���Хåե����ɲá�
	my $keyword = $self->{'keyword'};
	my $word;
	foreach my $label (keys %$keyword){
		$word = $keyword->{$label};
		$buf .= $word->{'type'} . "\t$label\t" . $word->{'value'} . "\n";
	}

	# �Хåե������Ƥ򥭥�å���ե��������¸��
	Util::save_config_text(undef, "$log_dir/$keyword_cache2", $buf);
}

#==============================================================================
# �ѡ����ʥ��󥹥ȥ饯������ƤФ�ޤ���
#==============================================================================
sub parse {
	my $self = shift;
	my $wiki = $self->{wiki};
	$self->{'keyword'} = {};
	my @keywordlist = ([], [], []);

	require Regexp::Assemble;

	my $ra = Regexp::Assemble->new;

	# �ڡ����Υ����ȥ�󥯤�ͭ���ʾ�硢�ڡ���̾�⥭����ɤ˴ޤࡣ
	if ($wiki->config('auto_keyword_page') == 1) {
		my $no_slash_page = $wiki->config('keyword_slash_page') ne '1';
		my %hash = ();
		my ($page, $pat, $level, $label);

		# �ڡ���̾�ο������� \d\d* ���ˤ��ѥ������̲��γ�ǧ
		foreach $page ($wiki->get_page_list()){
			next if ($no_slash_page and index($page, '/') != -1);
			$pat = quotemeta $page;
			$pat =~ s{\d+}{\\d\\d\*}g;	 # �ڡ���̾�ο������� \d\d* ���ִ���
			$hash{$pat}->{'count'}++;	  # $pat �˶��̲��Ǥ���ڡ����ο�
			$hash{$pat}->{'page'} = $page; # �ڡ���̾(count = 1 �ΤȤ�)
		}

		# ���̲��Ǥ����������ƤΥѥ�����ˤĤ��ơ�
		foreach $pat (sort keys %hash) {

			# ���Υѥ�����˶��̲��Ǥ���ڡ������� 1 �ڡ����ΤߤΤȤ���
			if ($hash{$pat}->{'count'} == 1) {
				$page = $hash{$pat}->{'page'}; # ���Υڡ���̾�������
				$level = $wiki->get_page_level($page);

				# �ڡ���������٥���Υ�����ɥꥹ�Ȥ˥ڡ���̾���ɲá�
				push @{ $keywordlist[$level] }, $page;
				next;
			}

			# ���Υѥ�����˶��̲��Ǥ���ڡ�������ʣ���ڡ����ΤȤ���
			# ���̲��ѥ����������ɽ�����ɲá�
			# (���������Ƭ��������Ⱦ�ѱѿ��ʤ顢ñ�춭�� \b ���ɲ�)��
			$pat  = "\\b$pat" if ($pat =~ /^(?:\w|\\d)/);
			$pat .= "\\b"	 if ($pat =~ /(?:\w|\\d\*)$/);
			$ra->add($pat);
		}
	}

	# �ڡ�����Keyword�פ�¸�ߤ���С��������Ƥ��ɤࡣ
	if ($wiki->page_exists('Keyword')) {

		# �ڡ�����Keyword�פ����Ƥ��饭����ɥǡ����������
		my $source = $wiki->get_page('Keyword');
		$source =~ s/\r//g;
		my @lines = split /\n/, $source;
		foreach my $line (@lines) {
			if (index($line, '*') == 0) {
				$self->parse_line($line);
			}
		}

		# ������ɥǡ������顢�����������ɽ���������
		my $keyword = $self->{'keyword'};
		my ($level, $page, $word);
		foreach my $label (keys %$keyword) {
			$word = $keyword->{$label};

			# ������ɤ��б�����Τ� url �ʤ顢
			if ($word->{'type'} eq 'u') {

				# ������� $label �򥭡��������ɽ�����ɲ�
				# (���������Ƭ��������Ⱦ�ѱѿ��ʤ顢ñ�춭�� \b ���ɲ�)��
				$label  = quotemeta $label;
				$label  = "\\b$label" if ($label =~ /^\w/);
				$label .= "\\b"	   if ($label =~ /\w$/);
				$ra->add($label);
			}

			# ������ɤ��б�����Τ��ڡ���̾�ʤ顢
			else {
				$page = $word->{'value'};
				$level = $wiki->get_page_level($page);

				# �ڡ���������٥���Υꥹ�Ȥ˥�����ɤ��ɲá�
				push @{ $keywordlist[$level] }, $label;
			}
		}
	}

	$self->{'regexp_list'} = [];
	my $label;

	# �ڡ���������٥���Υꥹ����Υ�����ɤ�����ɽ�����ɲá�
	foreach my $level (0 .. 2) {
		foreach my $page (@{ $keywordlist[$level] }) {

			# �ڡ���̾ $page �򥭡��������ɽ�����ɲ�
			# (���������Ƭ��������Ⱦ�ѱѿ��ʤ顢ñ�춭�� \b ���ɲ�)��
			$page  = quotemeta $page;
			$page  = "\\b$page" if ($page =~ /^\w/);
			$page .= "\\b"	  if ($page =~ /\w$/);
			$ra->add($page);
		}

		# �������������������ɽ����ꥹ�Ȥ���¸��
		push @{ $self->{'regexp_list'} }, $ra->clone()->as_string();
	}
}

sub parse_line {
	my $self   = shift;
	my $source = shift;

	return if (not defined $source);

	# $source �����ˤʤ�ޤǷ����֤���
	while ($source ne q{}) {

		# ������ɤ��������񼰤��ʤ���н�λ��
		return if (not $source =~ /^[^\[]*(\[.+)$/);

		$source = $1;

		# ��̾���
		if ($source =~ /^\[([^\[]+?)\|((?:https?|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!&=:;\*#\@'\$]*)\]/
		 || $source =~ /^\[([^\[]+?)\|(file:[^\[\]]*)\]/
		 || $source =~ /^\[([^\[]+?)\|((?:\/|\.\/|\.\.\/)+[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!&=:;\*#\@'\$]*)\]/ ) {
			my $label = $1;
			my $url   = $2;
			$source = $';
			$self->url_anchor($url, $label);
		}

		# InterWiki
		elsif ($self->{interwiki}->exists_interwiki($source)) {
			my $label = $self->{interwiki}->{g_label};
			my $url   = $self->{interwiki}->{g_url};
			$source = $self->{interwiki}->{g_post};
			$self->url_anchor($url, $label);
		}

		# �ڡ�����̾���
		elsif ($source =~ /^\[\[([^\[]+?)\|(.+?)\]\]/) {
			my $label = $1;
			my $page  = $2;
			$source = $';
			$self->wiki_anchor($page, $label);
		}

		# Ǥ�դ�URL���
		elsif ($source =~ /^\[([^\[]+?)\|(.+?)\]/) {
			my $label = $1;
			my $url   = $2;
			$source = $';
			$self->url_anchor($url, $label);
		}

		# �ʾ�� macth ���ʤ��ä��ʤ顢1 ʸ���ʤ�롣
		else {
			$source =~ s/^.//;
		}
	}
}

#==============================================================================
# URL����
#==============================================================================
sub url_anchor {
	my ($self, $url, $name) = @_;

	$self->{'keyword'}->{$name} = { 'type' => 'u', 'value' => $url };
}

#==============================================================================
# Wiki����
#==============================================================================
sub wiki_anchor {
	my ($self, $page, $name) = @_;

	$self->{'keyword'}->{$name} = { 'type' => 'w', 'value' => $page };
}

1;
