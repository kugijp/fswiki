##############################################################
#
# <p>�ץ饰����δʰץإ�פ�ɽ�����ޤ���</p>
# <pre>
# {{pluginhelp}}
# </pre>
# <p>
#   �Ȥ���ȥ��󥹥ȡ��뤵��Ƥ���ץ饰����ΰ����ȴ�ñ��
#   ����������ɽ������ޤ����ץ饰����̾�򥯥�å������
#   ���Υץ饰����ξܺ٤�������ɽ������ޤ���
# </p>
# <p>
#   �ޤ������ץ����ǥץ饰����̾����ꤹ��ȡ�
#   ���Υץ饰����Υإ�פ�ɽ�����뤳�Ȥ��Ǥ��ޤ���
# </p>
# <pre>
# {{pluginhelp �ץ饰����̾,�ץ饰����̾,...}}
# </pre>
#
##############################################################
package plugin::info::PluginHelp;
use strict;
use plugin::info::PluginHelpHandler;
#=============================================================
# ���󥹥ȥ饯��
#=============================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#=============================================================
# �ѥ饰��ե᥽�å�
#=============================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my @plugin = @_;
	my $buf    = "";
	
	# ���ꤷ���ץ饰����Τ�ɽ��
	if ( scalar(@plugin) > 0 ) {
		$buf .= "<dl>\n";
		for my $p ( @plugin ) {
			$buf .= "<dt>".Util::escapeHTML($p)."</dt>\n";
			if (my $plugin = $wiki->{"plugin"}->{$p}->{CLASS}) {
				my $comment = &plugin::info::PluginHelpHandler::get_comment($wiki,$plugin);
				$buf .= "<dd>$comment</dd>\n";
			} else {
				$buf .= "<dd><font class=\"error\">{{".Util::escapeHTML($p)."}}�ץ饰�����¸�ߤ��ޤ���</font></dd>\n"
			}
		}
		$buf .= "</dl>\n";
		
	# ���ƤΥץ饰�����ɽ��
	} else {
		my @plugins = sort { $a cmp $b } keys(%{$wiki->{"plugin"}});
		
		foreach my $p (@plugins){
			my $name   = $p;
			my $plugin = $wiki->{"plugin"}->{$p}->{CLASS};
			my $comment = &plugin::info::PluginHelpHandler::get_comment($wiki,$plugin);
			my $comment = (split(/\n/,$comment))[0];
			$comment = &Util::delete_tag($comment);
			
			$buf .= "<dl>".
			        "<dt><a href=\"".$wiki->create_url({ action=>"PLUGINHELP", name=>$name, plugin=>$plugin })."\">$name</a></dt>".
			        "<dd>$comment</dd></dl>\n";
		}
	}
	return $buf;
}

1;
