#########################################################################
#
# <p>BugTrack�ξ����ѹ��ѥץ饰����Ǥ���</p>
# <p>
#   ���֤��ѹ�����٤Υե������ɽ�����ޤ���
# </p>
# <pre>
# {{bugstate �оݤΥڡ���(��ά����ɽ�����Ƥ���ڡ���)}}
# </pre>
# <p>
#   �ե����फ����֤��ѹ�������оݤΥڡ����ΰʲ�����ʬ��
#   ���Ѥ��Ƥ�Ȥ��ɽ�����Ƥ����ڡ�����ɽ�����ޤ���
# </p>
# <pre>
# *���֡� ...
# </pre>
# 
#########################################################################
package plugin::bugtrack::BugState;
use strict;
#========================================================================
# ���󥹥ȥ饯��
#========================================================================
sub new {
    my $class = shift;
    my $self = {};
    return bless $self,$class;
}

#========================================================================
# �ѥ饰���
#========================================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my $cgi    = $wiki->get_CGI;
	my $source = shift;
	my $page   = $cgi->param("page");

	if($source eq ""){
		$source = $page;
	}

	return make_form($wiki,$page,$source);
}
#======================================================================
# BugList�Ǥ�Ȥ��ΤǴؿ���
#======================================================================
sub make_form {
    my $wiki = shift;
    my $page = shift;
    my $source = shift;

    my $content = $wiki->get_page($source);
    $content =~ /\n\*���֡�\s+(.*)/;
    my $state = $1;

    $page   = &Util::escapeHTML($page);
    $source = &Util::escapeHTML($source);

    my $buf = "<form action=\"".$wiki->create_url()."\" method=\"post\">\n".
              "  <input id=\"state_1\" name=\"state\" type=\"radio\" value=\"���\"><label for=\"state_1\">���</label>\n".
              "  <input id=\"state_2\" name=\"state\" type=\"radio\" value=\"���\"><label for=\"state_2\">���</label>\n".
              "  <input id=\"state_3\" name=\"state\" type=\"radio\" value=\"��λ\"><label for=\"state_3\">��λ</label>\n".
              "  <input id=\"state_4\" name=\"state\" type=\"radio\" value=\"��꡼����\"><label for=\"state_4\">��꡼����</label>\n".
              "  <input id=\"state_5\" name=\"state\" type=\"radio\" value=\"��α\"><label for=\"state_5\">��α</label>\n".
              "  <input id=\"state_6\" name=\"state\" type=\"radio\" value=\"�Ѳ�\"><label for=\"state_6\">�Ѳ�</label>\n".
              "  <input name=\"page\" type=\"hidden\" value=\"$page\">\n".
              "  <input name=\"source\" type=\"hidden\" value=\"$source\">\n".
              "  <input name=\"action\" type=\"hidden\" value=\"BUG_STATE\">\n".
              "  <input type=\"submit\" value=\"�ѹ�\">\n".
              "</form>";

    $buf =~ s/"$state"/$& checked="checked"/;
    return $buf;
}

1;
