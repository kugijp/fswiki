############################################################
#
# <p>ź�դ��������ե������ɽ�����ޤ���</p>
# <pre>
# {{ref_image �ե�����̾}}
# </pre>
# <p>�̤Υڡ�����ź�դ��줿�ե�����򻲾Ȥ��뤳�Ȥ�Ǥ��ޤ���</p>
# <pre>
# {{ref_image �ե�����̾,�ڡ���̾}}
# </pre>
#
############################################################
package plugin::attach::RefImage;
use strict;
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
	my $file = shift;
	my $page = shift;
	
	if($file eq ""){
		return &Util::paragraph_error("�ե����뤬���ꤵ��Ƥ��ޤ���","WIKI");
	}
	if($page eq ""){
		$page = $wiki->get_CGI()->param("page");
	}
	unless($wiki->can_show($page)){
		return &Util::paragraph_error("�ڡ����λ��ȸ��¤�����ޤ���","WIKI");
	}
	
	my $filename = $wiki->config('attach_dir')."/".&Util::url_encode($page).".".&Util::url_encode($file);
	unless(-e $filename){
		return &Util::paragraph_error("�ե����뤬¸�ߤ��ޤ���","WIKI");
	}
	
	$wiki->get_current_parser()->l_image($page,$file);
	return undef;
}

1;