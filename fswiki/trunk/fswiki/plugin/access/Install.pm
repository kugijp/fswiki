############################################################
#
# ������������¿����˥ڡ����ΰ�����ɽ������
# ����饤��ץ饰������󶡤��ޤ���
#
############################################################
package plugin::access::Install;
use strict;
sub install {
	my $wiki = shift;
	$wiki->add_paragraph_plugin("access"    ,"plugin::access::Access"    ,"WIKI");
	$wiki->add_paragraph_plugin("accessdays","plugin::access::AccessDays","WIKI");
}

1;
