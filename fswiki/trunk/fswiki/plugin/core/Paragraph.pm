################################################################################
#
# <p>���Ф�����Ϥ��ޤ���</p>
# <pre>
# {{paragraph ��٥�(1��3),���Ф�}}
# </pre>
# <p>
#   ���Υץ饰����ǽ��Ϥ������Ф��ˤϥѥ饰��դ��Ȥ��Խ����󥫤�ɽ������ޤ���
#   �ץ饰���󤫤鸫�Ф�����Ϥ���ɬ�פ�������˻��Ѥ��Ƥ���������
# </p>
#
################################################################################
package plugin::core::Paragraph;
use strict;
#===============================================================================
# ���󥹥ȥ饯��
#===============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===============================================================================
# �ѥ饰���
#===============================================================================
sub paragraph {
	my $self  = shift;
	my $wiki  = shift;
	my $level = shift;
	my $para  = shift;
	
	if($level eq ""){
		return &Util::paragraph_error("��٥뤬���ꤵ��Ƥ��ޤ���","WIKI");
	}
	if($level != 1 && $level != 2 && $level != 3){
		return &Util::paragraph_error("��٥��1��3�ޤǤ��ͤ�������Ǥ��ޤ���","WIKI");
	}
	if($para eq ""){
		return &Util::paragraph_error("�ѥ饰��դ����ꤵ��Ƥ��ޤ���","WIKI");
	}
	
	# ����ä�΢��
	my $parser = $wiki->get_current_parser();
	$parser->{no_partedit} = 1;
	if($level==1){
		$parser->parse("!$para\n");
	} elsif($level==2){
		$parser->parse("!!$para\n");
	} elsif($level==3){
		$parser->parse("!!!$para\n");
	}
	$parser->{no_partedit} = 0;
	
	return undef;
}

1;
