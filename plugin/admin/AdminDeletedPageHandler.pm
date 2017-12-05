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
# ������줿�ڡ�����Ͽ����ե�����Υѥ����֤��ؿ�
#==============================================================================
sub _get_deleted_file {
	my $wiki = shift;
	return $wiki->config('log_dir')."/".$DELETED_FILE
}

#==============================================================================
# �ڡ����κ�����˸ƤӽФ����
#==============================================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	open(FILE, ">>".&_get_deleted_file($wiki));
	binmode(FILE);
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
		$wiki->redirectURL($wiki->create_url({ action=>"ADMINDELETED"}));
	}
	if($cgi->param('forget')){
		$self->forget($wiki);
		$wiki->redirectURL($wiki->create_url({ action=>"ADMINDELETED"}));
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
# �ڡ��������˺��
#==============================================================================
sub forget {
	my $self  = shift;
	my $wiki  = shift;
	my @selected_pages = $wiki->get_CGI()->param('pages');
	my $deleted_file = &_get_deleted_file($wiki);
	
	# ����ڡ�����Ͽ����ե����뤫�����򤵤줿�ڡ�������
	Util::file_lock($deleted_file);
	open(FILE, $deleted_file);
	my $pages = {};
	my $buf = "";
	while(my $LINE = <FILE>){
		my ($page, $mod) = split(/\t/, Util::trim($LINE));
		unless($wiki->page_exists($page)){
			my $selected = 0;
			foreach my $selected_page (@selected_pages){
				if($page eq $selected_page){
					$selected = 1;
					last;
				}
			}
			if($selected == 0){
				$buf .= $page."\t".$mod."\n";
			}
		}
	}
	close(FILE);
	
	open(FILE, ">".$deleted_file);
	binmode(FILE);
	print FILE $buf;
	close(FILE);
	Util::file_unlock($deleted_file);

	# �Хå����åץե��������
	foreach my $selected_page (@selected_pages){
		my @backup_files = glob(&Util::make_filename($wiki->config('backup_dir'), &Util::url_encode($selected_page), "*"));
		foreach my $backup_file (@backup_files){
			unlink($backup_file);
		}
		my @attach_files = glob(&Util::make_filename($wiki->config('attach_dir'), &Util::url_encode($selected_page), "*"));
		foreach my $attach_file (@attach_files){
			unlink($attach_file);
		}
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
	
	open(FILE, &_get_deleted_file($wiki));
	my $pages = {};
	while(my $LINE = <FILE>){
		my ($page, $mod) = split(/\t/, Util::trim($LINE));
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
		<input type="submit" name="revert" value="����">
		<input type="submit" name="forget" value="�����˺��">
	</form>|;
	
	$wiki->set_title("������줿�ڡ���");
	return $buf;
}

1;
