############################################################
# 
# <p>�ʰ�Ū����ɼ�ե����������в��ɽ�����ޤ���</p>
# <pre>
# {{vote ��ɼ̾,����1,����2,}}
# </pre>
# <p>
#   �㤨�аʲ��Τ褦�˻��Ѥ��ޤ���
#   �������ˤϤ�����ɼ�򼨤��狼��䤹��̾����Ĥ��Ƥ���������
#   ��������ʹߤ��ºݤ�ɽ�������������ܤˤʤ�ޤ���
# </p>
# <pre>
# {{vote FSWiki�δ���,�褤,����,����}}
# </pre>
#
############################################################
package plugin::vote::Vote;
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
# ��ɼ�ե�����
#===========================================================
sub paragraph {
	my $self     = shift;
	my $wiki     = shift;
	my $votename = shift;
	my @itemlist = @_;
	my $cgi      = $wiki->get_CGI;
	my $page     = $cgi->param("page");
	
	# �����Υ��顼�����å�
	if($votename eq ""){
		return &Util::paragraph_error("��ɼ̾�����ꤵ��Ƥ��ޤ���","Wiki");
	}
	if($#itemlist == -1){
		return &Util::paragraph_error("����̾�����ꤵ��Ƥ��ޤ���","Wiki");
	}
	
	# �ɤ߹���
	my $filename = &Util::make_filename($wiki->config('log_dir'),
	                                    &Util::url_encode($votename),"vote");
	my $hash = &Util::load_config_hash(undef,$filename);
	
	# ɽ���ѥƥ����Ȥ��Ȥ�Ω�Ƥ�
	my $buf = ",����,��ɼ��\n";
	
	foreach my $item (@itemlist) {
		my $count = $hash->{$item};
		unless(defined($count)){
			$count=0;
		}
		$buf .= ",$item,$countɼ - [��ɼ|".$wiki->create_url({
			page=>$page,
			vote=>$votename,
			item=>$item,
			action=>'VOTE'
		})."]\n";
	}
	return $buf;
}

1;
