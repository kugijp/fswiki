############################################################
#
# Google�θ����ܥå�����ɽ�����뵡ǽ���󶡤��ޤ���
#
############################################################
package plugin::google::Install;
use strict;

sub install {
	my $wiki = shift;
	
	$wiki->add_paragraph_plugin("google","plugin::google::Google","HTML");
}

1;
