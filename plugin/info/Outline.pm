############################################################
#
# <p>�ڡ����Υ����ȥ饤���ɽ�����ޤ���</p>
# <pre>
# {{outline}}
# </pre>
#
############################################################
package plugin::info::Outline;
use strict;
use plugin::info::OutlineParser;

#===========================================================
# ���󥹥ȥ饯��
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# �ѥ饰��ե᥽�å�
#===========================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	my $p_cnt = 0;
	
	my $pagename = $cgi->param("page");
	# �ڡ����λ��ȸ��¤����뤫�ɤ���Ĵ�٤�
	unless($wiki->can_show($pagename)){
		return undef;
	}
	my $parser = plugin::info::OutlineParser->new($wiki);
	return $parser->outline($wiki->get_page($pagename));
}

1;
