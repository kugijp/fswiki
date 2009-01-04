############################################################
# 
# <p>�����ƥ��֤ʥ桼�������ɽ�����ޤ���<p>
# <p>
# ������ɽ����������Ǥ��ޤ���(0������ɽ��)
# </p>
# <pre>
# {{actives 5}}
# </pre>
# <p>
# n�����ޤǤ����פ�Ȥ뤳�Ȥ�Ǥ��ޤ���
# </p>
# <pre>
# {{actives 5,7}}
# </pre>
# 
############################################################
package plugin::editlog::Actives;
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
# �Ƕ�Υ������������ꥹ��ɽ��
#===========================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $max  = shift;
	my $days = shift;
	my %count;
	my $cgi  = $wiki->get_CGI;
	
	return "��������Ϥ���ޤ���" if $wiki->config('log_dir') eq "";
	return "��������Ϥ���ޤ���" if ! -e $wiki->config('log_dir')."/useredit.log";
	
	my $oldest = 0;
	if(! $days) {
		$days = 30;
	}
	$oldest = time() - $days * 24 * 3600;
	
	open(DATA,$wiki->config('log_dir')."/useredit.log") or die $!;
	while(<DATA>){
		my($date, $time, $unixtime, $action, $subject, $id) = split(" ",$_);
		if ($unixtime > $oldest){
			$count{$id}++;
		}
	}
	close(DATA);
	
	my $content = "";
	my @members = reverse sort {$count{$a} <=> $count{$b}} keys(%count);
	if($max && $#members>$max-1){
		@members = @members[0..$max-1];
	}
	
	if($#members==-1){
		return "��������Ϥ���ޤ���";
	}
	
	foreach my $key(@members){
		if($key eq ""){
			$content .= "*̤������($count{$key})\n";
		} else {
			$content .= "*$key($count{$key})\n";
		}
	}
	
	return $content;
}

1;
