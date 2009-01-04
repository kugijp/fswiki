############################################################
#
# <p>ź�եե�����ؤΥ��󥫤�ɽ�����ޤ���</p>
# <pre>
# {{ref �ե�����̾}}
# </pre>
# <p>�̤Υڡ�����ź�դ��줿�ե�����򻲾Ȥ��뤳�Ȥ�Ǥ��ޤ���</p>
# <pre>
# {{ref �ե�����̾,�ڡ���̾}}
# </pre>
# <p>
#   �̾�ϥ��󥫤Ȥ��ƥե�����̾��ɽ������ޤ�����
#   ��̾�Ȥ���Ǥ�դ�ʸ�����ɽ�����뤳�Ȥ�Ǥ��ޤ���
# </p>
# <pre>
# {{ref �ե�����̾,�ڡ���̾,��̾}}
# </pre>
#
############################################################
package plugin::attach::Ref;
use strict;
use plugin::attach::AttachHandler;
#===========================================================
# ���󥹥ȥ饯��
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# ����饤��ؿ�
#===========================================================
sub inline {
	my $self  = shift;
	my $wiki  = shift;
	my $file  = shift;
	my $page  = shift;
	my $alias = shift;
	
	if($file eq ""){
		return &Util::inline_error("�ե����뤬���ꤵ��Ƥ��ޤ���");
	}
	if($page eq ""){
		$page = $wiki->get_CGI()->param("page");
	}
	unless($wiki->can_show($page)){
		return &Util::paragraph_error("�ڡ����λ��ȸ��¤�����ޤ���","WIKI");
	}
	if($alias eq ""){
		$alias = $file;
	}

	my $filename = $wiki->config('attach_dir')."/".&Util::url_encode($page).".".&Util::url_encode($file);
	if(-e $filename){
		my $buf = "<a href=\"".$wiki->create_url({ action=>"ATTACH",page=>$page,,file=>$file })."\">".&Util::escapeHTML($alias)."</a>";
		
		# ��������ɲ�������
		my $count = Util::load_config_hash(undef,$wiki->config('log_dir')."/".$wiki->config('download_count_file'));
		if(defined($count->{$page."::".$file})){
			$buf .= "(".$count->{$page."::".$file}.")";
		} else {
			$buf .= "(0)";
		}
		return $buf;
		
	} else {
		return &Util::inline_error("�ե����뤬¸�ߤ��ޤ���");
	}
}

1;
