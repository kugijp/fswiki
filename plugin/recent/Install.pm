############################################################
#
# ����������˥ڡ��������ɽ�����뤿��Υ���饤��ץ饰������󶡤��ޤ���
#
############################################################
package plugin::recent::Install;
use strict;

sub install {
	my $wiki = shift;
	$wiki->add_paragraph_plugin("recent"    ,"plugin::recent::Recent"    ,"WIKI");
	$wiki->add_paragraph_plugin("recentdays","plugin::recent::RecentDays","WIKI");
}

1;
