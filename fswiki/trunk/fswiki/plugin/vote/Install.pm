############################################################
#
# �ʰ���ɼ�ե������ɽ����Ԥ��ޤ���
#
############################################################
package plugin::vote::Install;
use strict;

sub install {
	my $wiki = shift;
	$wiki->add_paragraph_plugin("vote","plugin::vote::Vote", "WIKI");
	$wiki->add_handler("VOTE","plugin::vote::VoteHandler");
}

1;
