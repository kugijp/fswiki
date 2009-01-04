############################################################
# 
# <p>������������ɽ�����ޤ���</p>
# <pre>
# {{counter ������̾}}
# </pre>
# <p>������̾�Ͼ�ά�Ǥ��ޤ���</p>
# 
############################################################
package plugin::info::Counter;
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
# ����饤��ؿ�
#===========================================================
sub inline {
	my $self   = shift;
	my $wiki   = shift;
	my $name   = shift;
	
	my $count = 0;
	
	if($name eq ""){
		$name = "default";
	}
	
	my $file = $wiki->config('log_dir')."/count-".Util::url_encode($name).".txt";
	if (-e $file) {
		open(COUNT,$file) or return "";
		my $line=<COUNT>;
		$count = int($line) or $count = 0;
		close(COUNT);
	}
	$count ++;
	
	unless(-e "$file.tmp"){
		open(COUNT,">$file.tmp") or return $count;
		print COUNT $count;
		close(COUNT);
		rename("$file.tmp", $file);
	}
	
	return $count;
}

1;
