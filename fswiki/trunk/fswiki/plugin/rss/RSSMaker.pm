###############################################################################
#
# RSS�ץ饰����
#
###############################################################################
package plugin::rss::RSSMaker;
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
# ���������ϥ�ɥ�᥽�å�
#==============================================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI();
	my $file = $wiki->config('log_dir')."/rss.cache";
	
	# ����å���ե����뤬�ʤ����Ϻ�������
	unless(-e $file){
		&make_rss($wiki,$file);
	}
	
	# RSS��쥹�ݥ�
	print "Content-Type: text/xml\n\n";
	open(RSS,$file);
	binmode(RSS);
	while(<RSS>){
		print $_;
	}
	close(RSS);
	
	exit();
}

#==============================================================================
# �եå��᥽�å�
#==============================================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $hook = shift;
	
	if($hook eq "initialize"){
		$wiki->add_head_info("<link rel=\"alternate\" type=\"application/rss+xml\" title=\"RSS\" href=\"".$wiki->create_url({action=>"RSS"})."\">");
	} else {
		&make_rss($wiki,$wiki->config('log_dir')."/rss.cache");
	}
}

#==============================================================================
# ���դ�ե����ޥå�
#==============================================================================
sub format_date {
	my $time = shift;
	my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime($time);
	return sprintf("%04d/%02d/%02d %02d:%02d:%02d",
	               $year+1900,$mon+1,$mday,$hour,$min,$sec);
}

#==============================================================================
# RSS�ե�������������
#==============================================================================
sub make_rss {
	my $wiki = shift;
	my $file = shift;
	
	open(RSS,">$file") or die "RSS�ե�����κ����˼��Ԥ��ޤ�����";
	binmode(RSS);
	
	# ������������
	my @list = $wiki->get_page_list;
	@list = sort {
		my $mod1 = $wiki->get_last_modified2($a);
		my $mod2 = $wiki->get_last_modified2($b);
		return $mod2 <=> $mod1;
	} @list;
	
	# URI�����
	my $uri = $wiki->config('server_host');
	if($uri eq ""){
		$uri = $wiki->get_CGI()->url(-path_info => 1);
	} else {
		$uri = $uri . $wiki->get_CGI->url(-absolute => 1) . $wiki->get_CGI()->path_info();
	}
	
	# RSS��ե�����˽񤭽Ф�
#	print "Content-Type: text/xml\n\n";
	print RSS "<?xml version=\"1.0\" encoding=\"EUC-JP\"?>\n";
	print RSS "<!DOCTYPE rss PUBLIC \"-//Netscape Communications//DTD RSS 0.91//EN\"\n";
	print RSS "            \"http://my.netscape.com/publish/formats/rss-0.91.dtd\">\n";
	print RSS "<rss version=\"0.91\">\n";
	print RSS "  <channel>\n";
	print RSS "    <title>".$wiki->config('site_title')."</title>\n";
	print RSS "    <link>$uri?action=RSS</link>\n";
	print RSS "    <description>".$wiki->config('site_title')." RecentChanges</description>\n";
	print RSS "    <language>ja</language>\n";
	my $count = 0;
	foreach my $page (@list){
		
		# ��������Ƥ���ڡ����Τ�
		next if($wiki->get_page_level($page)!=0);
		
		if($count==15){
			last;
		}
		print RSS "    <item>\n";
		print RSS "      <title>".Util::escapeHTML($page)."</title>\n";
		print RSS "      <link>$uri?page=".Util::url_encode($page)."</link>\n";
		print RSS "      <description>".&format_date($wiki->get_last_modified2($page))."</description>\n";
		print RSS "    </item>\n";
		$count++;
	}
	print RSS "  </channel>\n";
	print RSS "</rss>\n";
	
	close(RSS);
}

1;
