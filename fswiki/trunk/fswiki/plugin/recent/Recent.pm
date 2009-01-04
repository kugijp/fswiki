############################################################
# 
# <p>�Ƕṹ�����줿�ڡ��������ɽ�����ޤ���</p>
# <p>������ɽ����������Ǥ��ޤ���</p>
# <pre>
# {{recent 5}}
# </pre>
# <p>�Ĥ�ɽ�����뤳�Ȥ�Ǥ��ޤ���</p>
# <pre>
# {{recent 5,v}}
# </pre>
# <p>���դ��Ȥ˰���ɽ������ˤ�recentdays�ץ饰�������Ѥ��ޤ���</p>
# 
############################################################
package plugin::recent::Recent;
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
	my $way    = shift;
	my $cgi    = $wiki->get_CGI;
	
	# ɽ�����������
	if($way eq ""){
		$way = "H";
	}
	
	if($max eq "V" || $max eq "v"){
		$way = "V";
		$max = 0;
		
	} elsif($max eq "H" || $max eq "h"){
		$way = "H";
		$max = 0;
		
	} elsif($max eq ""){
		$max = 0;
	}
	
	# ɽ�����Ƥ����
	my $content = "";
	my $count   = 0;
	foreach my $page ($wiki->get_page_list({-sort   =>'last_modified',
	                                        -permit =>'show',
	                                        -max    =>$max})){
		
		if($way eq "H" || $way eq "h"){
			if($count!=0){
				$content = $content." / ";
			}
		} else {
			$content = $content."*";
		}
		
		$content = $content."[[$page]]";
		
		if($way ne "H" && $way ne "h"){
			$content .= "\n";
		}
		
		$count++;
	}
	
	return $content;
}

1;
