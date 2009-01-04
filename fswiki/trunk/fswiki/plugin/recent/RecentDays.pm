############################################################
# 
# <p>�Ƕṹ�����줿�ڡ��������դ��Ȥ˰���ɽ�����ޤ���</p>
# <p>������ɽ����������ꤷ�ޤ���</p>
# <pre>
# {{recentdays 10}}
# </pre>
# <p>�������ά��������5��ʬ����Ϥ��ޤ���</p>
# 
############################################################
package plugin::recent::RecentDays;
use strict;
#===========================================================
# ���󥹥ȥ饯��
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# �ѥ饰��ե᥽�å�
#===========================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my $max    = shift;
	my $cgi    = $wiki->get_CGI;
	
	# ɽ�����������
	if($max eq ""){
		$max = 5;
	}
	
	# ɽ�����Ƥ����
	my $content = "";
	my $count   = 0;
	
	my $l_year = 0;
	my $l_mon  = 0;
	my $l_day  = 0;
	
	foreach my $page ($wiki->get_page_list({-sort=>'last_modified',-permit=>'show'})){
		
		my $modtime = $wiki->get_last_modified2($page);
		my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime($modtime);
		$year += 1900;
		$mon  += 1;
		if($l_year!=$year || $l_mon!=$mon || $l_day!=$mday){
			if($count==$max){
			    last;
			}
			$content .= "'''$year/$mon/$mday'''\n";
			$l_year = $year;
			$l_mon  = $mon;
			$l_day  = $mday;
			$count++;
		}
		$content .= "*[[$page]]\n";
	}
	
	return $content;
}

1;
