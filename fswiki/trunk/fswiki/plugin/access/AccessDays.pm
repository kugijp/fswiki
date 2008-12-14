###############################################################################
# 
# <p>������������¿����˥ڡ���̾������x��ɽ�����ޤ���</p>
# <p>������ɽ����������Ǥ��ޤ���</p>
# <pre>
# {{accessdays 5(���x��},5(y��ʬ)}}
# </pre>
# <p>�ǥե���Ȥ�5��,5���Ǥ���</p>
# 
###############################################################################
package plugin::access::AccessDays;
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
# �ѥ饰��մؿ�
#==============================================================================
sub paragraph {
	my $self    = shift;
	my $wiki    = shift;
	my $maxrank = shift;
	my $maxdays = shift;
	my $access  = {};
	my $buf     = "";

	if($maxrank eq ""){
	    $maxrank = 5;
	}

	if($maxdays eq ""){
	    $maxdays = 5;
	}

	open(LOG,$wiki->config('log_dir')."/".$wiki->config('access_log_file')) or return "";

	while(my $line=<LOG>){
		chomp $line;
		my ($page,$date) = split(/ /,$line);
		($date =~ m|\d{4}/\d{2}/\d{2}|o) or next;
		$access->{$date}={} unless defined($access->{$date});
		$page = Util::url_decode($page);
		$access->{$date}->{$page}++;
	}
	close(LOG);
	
	my @days = keys(%{$access});

	@days = sort {
	    return $b cmp $a;
	} @days;
	
	foreach my $day (@days){
		my $tmpday = $day;
		# recentdays��Ʊ�����շ�����
		$tmpday =~ s/\/0/\//g; 
		$buf .= "'''$tmpday'''\n";
		my @pages = keys(%{$access->{$day}});
		@pages = sort {
			my $count1=$access->{$day}->{$a};
			my $count2=$access->{$day}->{$b};
			return $count2 <=> $count1;
		}@pages;
		
		my $rank = $maxrank;
		foreach my $page (@pages){
			# ������줿�ڡ����Ȼ��ȸ��¤Τʤ��ڡ�����ʤ�
			next if (!$wiki->page_exists($page) || !$wiki->can_show($page));
			my $pagecount = $access->{$day}->{$page};
			$buf .= "*[[$page]]($pagecount)\n";
			$rank--;
			last unless $rank;
		}
		
		$maxdays--;
		last unless $maxdays;
	}
	
	return $buf;
}

1;
