###############################################################################
#
# <p>���������Фˤ���RSS��������ư���ɽ�����ޤ���</p>
# <pre>
# {{rss RSS��URL}}
# </pre>
#
###############################################################################
package plugin::rss::RSS;
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
# �ѥ饰��ե᥽�å�
#==============================================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $url  = shift;
	
	if($url eq ""){
		return &Util::paragraph_error("RSS��URL�����ꤵ��Ƥ��ޤ���");
	}
	
	# ����å���ե�����ι������������å�
	my $filename = $url;
	my $cache = $wiki->config('log_dir')."/".&Util::url_encode($filename).".rss";
	my $readflag = 0;
	if(-e $cache){
		my @status = stat($cache);
		if($status[9]+(60*60) > time()){
			$readflag = 1;
		}
	}
	
	my $content = "";
	if($readflag==0){
		# URL����RSS�����
		$content = &Util::get_response($wiki,$url) or return &Util::paragraph_error($!);
		
		# EUC���Ѵ��ʽ��Ϥ���Ȥ����Ѵ�����Τ��ȡ�
		#&Jcode::convert(\$content, "euc");
		
		# ����å���
		open(RSS,">$cache") or return &Util::paragraph_error($!);
		print RSS $content;
		close(RSS);
		
	} else {
		# �����뤫��RSS�����
		open(RSS,$cache) or return &Util::paragraph_error($!);
		while(<RSS>){ $content .= $_; }
		close(RSS);
	}
	# XML�ե����뤫�ɤ��������å�
	if($content !~ /<(\?xml|rss) version/i){
		return &Util::paragraph_error("XML�ե�����ǤϤ���ޤ���");
	}
	my @status = stat($cache);
	
	# �ѡ�������ɽ��
	return $self->parse_rss(\$content);
}

#==============================================================================
# RSS��ѡ�������HTML������
#==============================================================================
sub parse_rss {
	my $self    = shift;
	my $content = shift;
	my $charset = $self->get_charset($content);
	my $buf     = "<ul>\n";
	
	my $version = "1.0";

	if($$content =~ /<rss .*?version=\"(.*?)\"/i){
	$version = $1;
	}

	if($version eq "1.0"){
		$$content =~ m#(/channel>|/language>)#gsi;
	}
	
	my $count=0;
	
	while ($$content =~ m|<item[ >](.+?)</item|gsi) {
		
		my $item = $1;
		
		my $link  = "";
		my $title = "";
		my $date  = "";
		
		$item =~ m#title>([^<]+)</#gsi;
		$title = $1;
		
		$item =~ m#link>([^<]+)</#gsi;
		$link = $1;
		$link =~ s/\s".*//g; # ���֥륯�����ơ������ʹߤ��ڤ���Ȥ�

		if ($version eq "2.0") {
			if ($item =~ m#pubDate>([^<]+)</#gsi) {
				$date = $1;
			}
		}
		if ($version eq "1.0") {
			#if ($item =~ m#(description|dc\:date)>([^<]+)</#gs) {
			if ($item =~ m#dc\:date>([^<]+)</#gsi) {
				$date = $1;
			}
		}
		if ($version eq "0.91") {
			if($item =~ m#description>([^<]+)</#gsi){
				$date = $1;
			}
		}
		
		# ʸ�������ɤ��Ѵ�
		&Jcode::convert(\$title,'euc',$charset);
		&Jcode::convert(\$date ,'euc',$charset);
		
		$buf .= "<li><a href=\"$link\">$title</a>";
		if($date ne ""){
			$buf .= " - $date";

		}
		$buf .= "</li>\n";
		
		$count++;
		if($count>50){ last; }
	}
	
	return $buf."</ul>\n";
}

#==============================================================================
# XML�ե����뤫�饭��饯�����åȤ��������Jcode.pm�ǻ����ǽ��ʸ������ֵѡ�
# ���ꤵ��Ƥ��ʤ��ä�����undef���֤�ޤ���
#==============================================================================
sub get_charset {
	my $self    = shift;
	my $content = shift;
	my $charset = undef;
	
	# ���󥳡��ǥ��󥰤����ꤵ��Ƥ������
	if($$content =~ /encoding="(.+?)"/){
		# �Ȥꤢ������ʸ�����Ѵ�
		my $encode = uc($1);
		
		# Shift_JIS�ξ��sjis��
		if($encode eq "SHIFT_JIS" || $encode eq "SJIS" ||
		   $encode eq "WINDOWS-31J" || $encode eq "MS932" || $encode eq "CP932"){
			$charset = "sjis";
			
		# EUC-JP�ξ��euc��
		} elsif($encode eq "EUC-JP"){
			$charset = "euc";
			
		# UTF-8�ξ��utf8��
		} elsif($encode eq "UTF-8"){
			$charset = "utf8";
			
		# JIS�ξ��jis��
		} elsif($encode eq "ISO-2022-JP" || $encode eq "JIS"){
			$charset = "jis";
		}
	}
	
	return $charset;
}

1;
