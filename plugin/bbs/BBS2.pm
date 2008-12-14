###############################################################################
#
# <p>�Ǽ���������ƥե��������Ϥ��ޤ����������Ƥ����ڡ����Ȥʤꡢ�ڡ��������⥵�ݡ��Ȥ��ޤ���</p>
# <pre>
# {{bbs2 �Ǽ��Ĥ�̾��,ɽ�����}}
# </pre>
# <p>
#   bbs�ץ饰����Ȥΰ㤤�ϣ������Ƥ����ĤΥڡ����Ȥ��ƺ������졢
#   ����ɽ������뤳�ȤǤ��������ϻ���������ɽ������뤿�ᡢ
#   ��������������˲������ư���Խ�����ɬ�פ�����ޤ���
#   ɽ��������ά��������10�鷺��ɽ������ޤ���
# </p>
# <p>
#   �ǥե���ȤǤϳ���Ƶ������ֿ��ѤΥ����ȥե����ब���Ϥ���ޤ�����
#   no_comment���ץ�����Ĥ����OFF�ˤ��뤳�Ȥ��Ǥ��ޤ���
# </p>
# <pre>
# {{bbs2 �Ǽ��Ĥ�̾��,ɽ�����,no_comment}}
# </pre>
# <p>
#   reverse_comment���ץ�����Ĥ���ȳƵ����ˤĤ�comment�ץ饰�����
#   reverse���ץ�����Ĥ��뤳�Ȥ��Ǥ��������Ȥ������ɽ�������褦�ˤʤ�ޤ���
# </p>
# <pre>
# {{bbs2 �Ǽ��Ĥ�̾��,ɽ�����,reverse_comment}}
# </pre>
# <p>
#   no_list���ץ�����Ĥ���ȵ����ΰ�����ɽ����������ƥե����������ɽ�����ޤ���
#   ���ξ���bbs2list�ץ饰�����ȤäƵ����ΰ�����ɽ�����뤳�Ȥ��Ǥ��ޤ���
# </p>
# <pre>
# {{bbs2 �Ǽ��Ĥ�̾��,no_list}}
# </pre>
#
###############################################################################
package plugin::bbs::BBS2;
use strict;
#==============================================================================
# ���󥹥ȥ饯��
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# �Ǽ������ϥե�����
#==============================================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my $name   = shift;
	my $once   = shift;
	my $option = shift;
	
	if($name eq ""){
		return &Util::paragraph_error("�Ǽ��Ĥ�̾�������ꤵ��Ƥ��ޤ���");
	}
	if($once eq "" || !&Util::check_numeric($once)){
		$option = $once;
		$once   = 10;
	}
	
	my $cgi = $wiki->get_CGI;
	my $page = $cgi->param("page");
	
	# ���ϥե�����
	my $tmpl = HTML::Template->new(filename=>$wiki->config('tmpl_dir')."/bbs.tmpl",
	                               die_on_bad_params=>0);
	
	# ̾�������
	my $postname = $cgi->cookie(-name=>'post_name');
	if($postname eq ''){
		my $login = $wiki->get_login_info();
		if(defined($login)){
			$postname = $login->{id};
		}
	}
	$tmpl->param(NAME=>$postname);
	
	my $buf = "<form method=\"post\" action=\"".$wiki->create_url()."\">\n".
	          $tmpl->output.
	          "<input type=\"hidden\" name=\"action\" value=\"BBS2\">\n".
	          "<input type=\"hidden\" name=\"bbsname\" value=\"".&Util::escapeHTML($name)."\">\n";
	
	if($option eq "no_comment"){
		$buf .="<input type=\"hidden\" name=\"option\" value=\"no_comment\">\n";
	} elsif($option eq "reverse_comment"){
		$buf .="<input type=\"hidden\" name=\"option\" value=\"reverse_comment\">\n";
	}
	
	$buf .= "</form>";
	
	# �����ΰ�����Ϣ���no_list���ץ���󤬤Ĥ���줿����ɽ�����ʤ���
	if($option ne "no_list"){
		$buf .= $wiki->process_wiki("{{bbs2list $name,$once}}");
	}
	
	return $buf;
}

1;
