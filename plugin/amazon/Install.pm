############################################################
#
# ���ꤷ�����Ҥν�Ƥ�amazon�����������ɽ������amazon�ν�ɾ�ڡ����إ�󥯤�Ϥ�ޤ���
#
############################################################
package plugin::amazon::Install;

sub install {
	my $wiki = shift;
	$wiki->add_paragraph_plugin("amazon","plugin::amazon::Amazon", "HTML");
}

1;
