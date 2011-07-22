################################################################
#
# �ڡ����ι��������������ȥ饤��ʤɤξ����ɽ�����뤿���
# �ץ饰������󶡤��ޤ���
#
################################################################
package plugin::info::Install;
use strict;

sub install{
	my $wiki = shift;
	
	$wiki->add_inline_plugin("counter","plugin::info::Counter","WIKI");
	$wiki->add_inline_plugin("lastmodified","plugin::info::LastModified","WIKI");
	$wiki->add_inline_plugin("pagename","plugin::info::PageName","WIKI");
	$wiki->add_paragraph_plugin("outline","plugin::info::Outline","HTML");
	$wiki->add_paragraph_plugin("todayslink","plugin::info::TodaysLink","HTML");
	
	$wiki->add_paragraph_plugin("pluginhelp","plugin::info::PluginHelp","HTML");
	$wiki->add_handler("PLUGINHELP","plugin::info::PluginHelpHandler");
}
1;
