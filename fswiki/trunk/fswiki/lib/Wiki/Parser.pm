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
				$self->{block}->{level}++;
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
			if(index($line,"::")==0){
				if($self->{dt} ne "" || $self->{dd} ne ""){
					$self->multi_explanation;
				}
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
	my $self   = shift;
	my $source = shift;
	my @array  = ();
		
	# �ץ饰����
	if($source =~ /{{/){
		my $pre  = $`;
		my $post = $';
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		my $plugin = $self->{wiki}->parse_inline_plugin($post);
		unless($plugin){
			push @array,'{{';
			push @array,$self->parse_line($post);
		} else {
			my $info   = $self->{wiki}->get_plugin_info($plugin->{command});
			if($info->{TYPE} eq "inline"){
				push @array,$self->plugin($plugin);
			} else {
				push @array,$self->parse_line("<<".$plugin->{command}."�ץ饰�����¸�ߤ��ޤ���>>");
			}
			if($post ne ""){ push(@array,$self->parse_line($plugin->{post})); }
		}
		
	# InterWikiName
	} elsif($self->{interwiki}->exists_interwiki($source)){
		my $pre   = $self->{interwiki}->{g_pre};
		my $post  = $self->{interwiki}->{g_post};
		my $label = $self->{interwiki}->{g_label};
		my $url   = $self->{interwiki}->{g_url};
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		push @array,$self->url_anchor($url,$label);
		if($post ne ""){ push(@array,$self->parse_line($post)); }
	
	# �ڡ�����̾���
	} elsif($source =~ /\[\[([^\[]+?)\|([^\|\[]+?)\]\]/){
		my $pre   = $`;
		my $post  = $';
		my $label = $1;
		my $page  = $2;
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		push @array,$self->wiki_anchor($page,$label);
		if($post ne ""){ push(@array,$self->parse_line($post)); }

	# URL��̾���
	} elsif($source =~ /\[([^\[]+?)\|((http|https|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!\$&=:;\*#\@']*)\]/
	    ||  $source =~ /\[([^\[]+?)\|(file:[^\[\]]*)\]/
	    ||  $source =~ /\[([^\[]+?)\|((\/|\.\/|\.\.\/)+[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!\$&=:;\*#\@']*)\]/){
		my $pre   = $`;
		my $post  = $';
		my $label = $1;
		my $url   = $2;
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		if(index($url,'"') >= 0 || index($url,'><') >= 0 || index($url, 'javascript:') >= 0){
			push @array,$self->parse_line("<<�����ʥ�󥯤Ǥ���>>");
		} else {
			push @array,$self->url_anchor($url,$label);
		}
		if($post ne ""){ push(@array,$self->parse_line($post)); }
		
	# URL���
	} elsif($source =~ /(http|https|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!\$&=:;\*#\@']*/
	    ||  $source =~ /(file:[^\[\]]*)/){
		my $pre   = $`;
		my $post  = $';
		my $url = $&;
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		if(index($url,'"') >= 0 || index($url,'><') >= 0 || index($url, 'javascript:') >= 0){
			push @array,$self->parse_line("<<�����ʥ�󥯤Ǥ���>>");
		} else {
			push @array,$self->url_anchor($url);
		}
		if($post ne ""){ push(@array,$self->parse_line($post)); }
		
	# �ڡ������
	} elsif($source =~ /\[\[([^\|]+?)\]\]/){
		my $pre   = $`;
		my $post  = $';
		my $page = $1;
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		push @array,$self->wiki_anchor($page);
		if($post ne ""){ push(@array,$self->parse_line($post)); }
	
	# Ǥ�դ�URL���
	} elsif($source =~ /\[([^\[]+?)\|(.+?)\]/){
		my $pre   = $`;
		my $post  = $';
		my $label = $1;
		my $url   = $2;
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		if(index($url,'"') >= 0 || index($url,'><') >= 0 || index($url, 'javascript:') >= 0){
			push @array,$self->parse_line("<<�����ʥ�󥯤Ǥ���>>");
		} else {
			# URI�����
			my $wiki = $self->{wiki};
			my $uri = $wiki->config('server_host');
			if($uri eq ""){
				$uri = $wiki->get_CGI()->url(-path_info => 1);
			} else {
				$uri = $uri . $wiki->get_CGI->url(-absolute => 1) . $wiki->get_CGI()->path_info();
			}
			push @array,$self->url_anchor($uri."/../".$url, $label);
		}
		if($post ne ""){ push(@array,$self->parse_line($post)); }
	
	# �ܡ���ɡ�������å������ä���������
	} elsif($source =~ /((''')|('')|(==)|(__))(.+?)(\1)/){
		my $pre   = $`;
		my $post  = $';
		my $type  = $1;
		my $label = $6;
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		if($type eq "'''"){
			push @array,$self->bold($label);
		} elsif($type eq "__"){
			push @array,$self->underline($label);
		} elsif($type eq "''"){
			push @array,$self->italic($label);
		} elsif($type eq "=="){
			push @array,$self->denialline($label);
		}
		if($post ne ""){ push(@array,$self->parse_line($post)); }
	
	# �������
	} elsif($self->{keyword}->exists_keyword($source)){
		my $pre   = $self->{keyword}->{g_pre};
		my $post  = $self->{keyword}->{g_post};
		my $label = $self->{keyword}->{g_label};
		my $url   = $self->{keyword}->{g_url};
		my $page  = $self->{keyword}->{g_page};
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		if(defined($url) && $url ne ""){
			push @array,$self->url_anchor($url,$label);
		} else {
			push @array,$self->wiki_anchor($page,$label);
		}
		if($post ne ""){ push(@array,$self->parse_line($post)); }
		
	# WikiName
	} elsif($self->{wiki}->config('wikiname')==1 && $source =~ /[A-Z]+?[a-z]+?([A-Z]+?[a-z]+)+/){
		my $pre   = $`;
		my $post  = $';
		my $page  = $&;
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		push @array,$self->wiki_anchor($page);
		if($post ne ""){ push(@array,$self->parse_line($post)); }
		
	# ���顼��å�����
	} elsif($source =~ /(<<)(.+?)(>>)/){
		my $pre   = $`;
		my $post  = $';
		my $label = $2;
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		push @array,$self->error($label);
		if($post ne ""){ push(@array,$self->parse_line($post)); }
		
	} else {
		push @array,$self->text($source);
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
