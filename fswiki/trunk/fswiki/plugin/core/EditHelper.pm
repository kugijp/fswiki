############################################################
#
# �Խ����̤˥إ�פ�ɽ������ץ饰����
#
############################################################
package plugin::core::EditHelper;
#use strict;
#===========================================================
# ���󥹥ȥ饯��
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# �إ�פ�ɽ�����ޤ���
#===========================================================
sub editform {
	my $self = shift;
	my $wiki = shift;
	if(!Util::handyphone && $wiki->page_exists("EditHelper")){
	    return $wiki->process_wiki($wiki->get_page("EditHelper"));
	} else {
		return "<div>[<a href=\"".$wiki->create_page_url("Help")."\" target=\"_blank\">�إ��</a>]</div>";
	}
}

1;
