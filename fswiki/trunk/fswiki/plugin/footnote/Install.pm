########################################################################
#
# �����񤯰٤Υץ饰����Ǥ���
#
########################################################################
package plugin::footnote::Install;
use strict;
#=======================================================================
# ���󥹥ȡ��륹����ץ�
#=======================================================================
sub install{
    my $wiki = shift;
    $wiki->add_inline_plugin("fn","plugin::footnote::Footnote","HTML");
    $wiki->add_paragraph_plugin("footnote_list","plugin::footnote::FootnoteList","HTML");
    $wiki->add_hook("footnote","plugin::footnote::FootnoteList");
}
1;
