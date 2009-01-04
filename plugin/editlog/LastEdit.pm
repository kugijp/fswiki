############################################################
#
# <p>�ڡ����κǽ������Ԥȹ���������ɽ�����ޤ���</p>
# <pre>
# {{lastedit ɽ�����,�ڡ���̾}}
# </pre>
# <p>
# ������ά����ȺǸ�Σ����ɽ�����ޤ���
# �ڡ���̾���ά����ȸ���ɽ������Ƥ���ڡ����κǽ������Ԥȹ���������ɽ�����ޤ���
# </p>
#
############################################################
package plugin::editlog::LastEdit;
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
	my $self = shift;
	my $wiki = shift;
	my $max  = shift;
	my $page = shift;
	my $cgi  = $wiki->get_CGI();
	
	return "��������Ϥ���ޤ���" if $wiki->config('log_dir') eq "";
	return "��������Ϥ���ޤ���" if ! -e $wiki->config('log_dir')."/useredit.log";
	
	if($page eq ""){ $page = $cgi->param("page"); }
	if($max  eq ""){ $max  = 1; }
	
	my @editlist;
	open(DATA,$wiki->config('log_dir')."/useredit.log") or die $!;
	while(<DATA>){
		my($date, $time, $unixtime, $action, $subject, $id) = split(" ",$_);
		if($subject eq Util::url_encode($page)){
			push(@editlist,{ACTION=>$action,DATE=>$date,TIME=>$time,ID=>$id,UNIXTIME=>$unixtime});
		}
	}
	close(DATA);
	
	if($#editlist==-1){
		return "��������Ϥ���ޤ���";
	}
	
	@editlist = sort { $b->{UNIXTIME}<=>$a->{UNIXTIME} } @editlist;
	my $content = "";
	my $count   = 0;
	foreach my $edit (@editlist){
		if($count >= $max){
			last;
		}
		if($edit->{ID} ne ""){
			$content .= "*[$edit->{ACTION}] $edit->{DATE} $edit->{TIME} by $edit->{ID}\n";
		} else {
			$content .= "*[$edit->{ACTION}] $edit->{DATE} $edit->{TIME}\n";
		}
		$count++;
	}
	
	return $content;
}

1;
