############################################################
#
# Wiki�ڡ����ˣ��ԥ����Ȥ�񤭹��ि��Υץ饰������󶡤��ޤ���
#
############################################################
package plugin::comment::Install;
use strict;

sub install {
	my $wiki = shift;
	$wiki->add_paragraph_plugin("comment","plugin::comment::Comment","HTML");
	$wiki->add_handler("COMMENT","plugin::comment::CommentHandler");
}

1;
