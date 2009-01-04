###############################################################################
#
# Wiki�ڡ����򥫥ƥ��饤�����뤿��Υץ饰������󶡤��ޤ���
#
###############################################################################
package plugin::category::Install;
use strict;

sub install {
	my $wiki = shift;
	$wiki->add_paragraph_plugin("category_list","plugin::category::CategoryList","HTML");
	$wiki->add_inline_plugin("category","plugin::category::Category","HTML");
	$wiki->add_handler("CATEGORY","plugin::category::CategoryHandler");
	
	# �ڡ�������¸����������˥���å���򹹿�
	$wiki->add_hook("save_after","plugin::category::CategoryCache");
	$wiki->add_hook("delete"    ,"plugin::category::CategoryCache");
}

1;
