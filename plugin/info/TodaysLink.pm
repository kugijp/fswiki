#########################################################################
#
# <p>�����Υ�󥯸���ɽ�����ޤ���</p>
# <pre>
# {{todayslink}}
# </pre>
# <p>���ץ�����ɽ���������ꤹ�뤳�Ȥ�Ǥ��ޤ���</p>
# <pre>
# {{todayslink 10}}
# </pre>
# <p>�ޤ���v���ץ�����Ĥ���ȥ�󥯸���URL��ɽ�����뤳�Ȥ�Ǥ��ޤ���</p>
# <pre>
# {{todayslink 10,v}}
# </pre>
#
#########################################################################
package plugin::info::TodaysLink;
use strict;
#========================================================================
# ���󥹥ȥ饯��
#========================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#========================================================================
# �����Υ�󥯸���ɽ�����ޤ�
#========================================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $rank = shift;# ��� $rank �̤ޤ�ɽ��
	my $way = shift;
	my $buf = "";
	
	if($way eq ""){
		$way = "H";
	}
	
	if($rank eq "v" ||$rank eq "V"){
		$way = "V";
		$rank = "";
	} elsif($rank eq "H" || $rank eq "h") {
		$way = "H";
		$rank = "";
	}

	# ���������դ����Ʊ���ե����ޥåȤ�
	my $time = time();
	my ($sec,$min,$hour,$mday,$month,$year,$wday) = localtime($time);
	$year += 1900;
	$month += 1;
	my $today =sprintf("%04d/%02d/%02d",$year,$month,$mday);
	
	my $count={};
	#log������
	open(LOG,$wiki->config('log_dir')."/".$wiki->config('access_log_file')) or return "";
	while(my $line=<LOG>){
		chomp $line;
		my ($page,$date,$time,$ip,$ref,$ua) = split(/ /,$line);
		if($date =~ /$today/){
		    $count->{$ref}++;
		}
	}
	close(LOG);
	
	my @keys = sort {
		my $count1 = $count->{$a};
		my $count2 = $count->{$b};
		return $count2<=>$count1;
	} keys(%{$count});
	
	if ($way ne "H" && $way ne "h"){
		$buf .= "<ul>\n";
	}else{
		$buf .= "[";
	}
	
	my $url = $wiki->get_CGI->url; #wiki��Υڡ����ϳ���
	$url = substr($url,index($url,":")); #XREA����include://�ˤʤ�Τ�ʬ��
	$url = quotemeta($url);
	my $i=0;
	
	foreach(@keys){
		next if($_ eq "-" ||
			/^(http|https|ftp)$url/ ||
			/^http:\/\/localhost:?/ ||
			/^http:\/\/10\./ ||
			/^http:\/\/192\.168\./ ||
			/^http:\/\/172\.((1[6-9])|(2\d)|(3[01]))\./ ||
			/^http:\/\/127\.0\.0\./  );
		
		my $ref=$_;
		my $refcount=$count->{$ref};
		
		if($way ne "H" && $way ne "h"){
			my $decodeurl = Util::url_decode($ref);
			if($decodeurl =~ /UTF-8/){
				&Jcode::convert(\$decodeurl,"euc","utf8");
			} else {
				&Jcode::convert(\$decodeurl,"euc");
			}
			$buf .= "<li><a href=\"".Util::escapeHTML($ref)."\">".Util::escapeHTML($decodeurl)."</a>($refcount)</li>\n";
		}else{
			$buf .= "|" unless ($i==0);
			$buf .= "<a href=\"$ref\">$refcount</a>";
			$i++;
		}
		$rank--;
		last unless $rank;
	}
	
	if($way ne "H" && $way ne "h"){
		$buf .= "</ul>\n" ;
	}else{
		$buf .="]";
	}
	return $buf;
}
1;
