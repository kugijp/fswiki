###############################################################################
#
# Wiki�ڡ�����PDF�Ȥ���ɽ�����뤿��Υץ饰������󶡤��ޤ���
#
###############################################################################
package plugin::pdf::Install;
use strict;

sub install {
	my $wiki = shift;
	
	$wiki->add_menu("PDF","",100,1);
	$wiki->add_hook("initialize","plugin::pdf::PDFInitializer");
	$wiki->add_hook("remove_wiki","plugin::pdf::PDFInitializer");
	$wiki->add_hook("show","plugin::pdf::PDFMenu");
	$wiki->add_hook("delete","plugin::pdf::PDFDelete");
	$wiki->add_handler("PDF","plugin::pdf::PDFMaker");
}

1;
