###############################################################################
#
# �ڡ������������⥸�塼��
#
###############################################################################
package plugin::admin::AdminDeletedPageHandler;
use strict;
use vars qw($DELETED_FILE);

$DELETED_FILE = "deleted.dat";

#==============================================================================
# ���󥹥ȥ饯��
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# �ڡ����κ�����˸ƤӽФ����
#==============================================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	open(FILE, ">>".$wiki->config('log_dir')."/".$DELETED_FILE);
	print FILE $wiki->get_CGI()->param("page")."\t".time()."\n";
	close(FILE);
}

#==============================================================================
# ���������ϥ�ɥ�᥽�å�
#==============================================================================
sub do_action {
	my $self  = shift;
	my $wiki  = shift;
	my $cgi   = $wiki->get_CGI;
	if($cgi->param('revert')){
		$self->revert($wiki);
	}
	return $self->deleted_page_list($wiki);
}

#==============================================================================
# ������줿�ڡ���������
#==============================================================================
sub revert {
	my $self  = shift;
	my $wiki  = shift;
	my @pages = $wiki->get_CGI()->param('pages');
	foreach my $page (@pages){
		$wiki->save_page($page, $wiki->get_backup($page, 0));
	}
}

#==============================================================================
# ������줿�ڡ����ΰ���
#==============================================================================
sub deleted_page_list {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI();
	
	my $buf = qq|
		<h2>������줿�ڡ���</h2>
		<form action="@{[$wiki->create_url()]}" method="POST">
		<table>
		<tr>
			<th></th>
			<th>�ڡ���̾</th>
			<th>�������</th>
		</tr>
	|;
	
	open(FILE, $wiki->config('log_dir')."/".$DELETED_FILE);
	my $pages = {};
	while(my $LINE = <FILE>){
		my ($page, $mod) = split(/\t/, $LINE);
		unless($wiki->page_exists($page)){
			$pages->{$page} = $mod;
		}
	}
	close(FILE);
	
	foreach my $page (sort { $pages->{$b} cmp $pages->{$a} } keys %$pages){
		my $mod = $pages->{$page};
		$buf .= qq|
		<tr>
			<td><input type="checkbox" name="pages" value="@{[&Util::escapeHTML($page)]}"></td>
			<td><a href="@{[$wiki->create_url({'action'=>'DIFF', 'page'=>$page})]}" target="_blank">@{[&Util::escapeHTML($page)]}</a></td>
			<td>@{[&Util::format_date($mod)]}</td>
		</tr>|;
	}
	
	$buf .= qq|</table>
		<input type="hidden" name="action" value="ADMINDELETED">
		<input type="submit" name="revert" value="�����å������ڡ�������������">
	</form>|;
	
	$wiki->set_title("������줿�ڡ���");
	return $buf;
}

1;
