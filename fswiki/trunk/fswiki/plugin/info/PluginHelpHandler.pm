##############################################################
#
# PluginHelp�Υ��������ϥ�ɥ顣
#
##############################################################
package plugin::info::PluginHelpHandler;
use strict;
#=============================================================
# ���󥹥ȥ饯��
#=============================================================
sub new {
    my $class = shift;
    my $self = {};
    return bless $self,$class;
}

#=============================================================
# ���������ϥ�ɥ�᥽�å�
#=============================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	my $name   = $cgi->param("name");
	my $plugin = $cgi->param("plugin");
	my $comment = &get_comment($wiki,$plugin);
	
	$wiki->set_title(&Util::escapeHTML($name)."�ץ饰����");
	return $comment;
}

#=============================================================
# �����Ȥ��������᥽�å�
#=============================================================
sub get_comment {
	my $wiki   = shift;
	my $plugin = shift;
	my $comment = "";
	my $fname = $wiki->config("plugin_dir").'/'.&Util::get_module_file($plugin);
	open(MODULE,$fname) || die "$fname�Υ����ץ�˼��Ԥ��ޤ�����";
	my $comment = "";
	my $flag = 0;
	while(<MODULE>){
		if(!/^#/ || /^##/){
			if($flag==0){ next; } else { last; }
		}
		$flag = 1;
		s/\#+//;
		s/\={2,}//;
		s/^\s+//; s/\s+$//;
		if($_ ne ""){
			$comment .= $_."\n";
		}
	}
	close(MODULE);
	return $comment;
}

1;
