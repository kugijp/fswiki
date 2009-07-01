############################################################
# 
# <p>���ԥ����Ȥ�񤭹��ि��Υե��������Ϥ��ޤ���</p>
# <pre>
# {{comment}}
# </pre>
# <p>
#   �̾�����Ȥ���ƥե�����β����ɲä���Ƥ����ޤ�����
#   ���ץ����ǥե�����ξ�˿����ɽ������褦�ˤǤ��ޤ���
# </p>
# <pre>
# {{comment reverse}}
# </pre>
# <p>
#   tail���ץ�����Ĥ���ȥڡ����κǸ�˥����Ȥ��ɲä��ޤ���
#   �եå��ʤɤ�comment�ץ饰��������֤������ڡ����˥����Ȥ�
#   �Ĥ���������ͭ���Ǥ���
# </p>
# <pre>
# {{comment tail}}
# </pre>
# 
############################################################
package plugin::comment::Comment;
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
# �����ȥե�����
#===========================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $opt  = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $page = $cgi->param("page");
	
	if(!defined($self->{$page})){
		$self->{$page} = 1;
	} else {
		$self->{$page}++;
	}
	
	# ̾�������
	my $name = Util::url_decode($cgi->cookie(-name=>'fswiki_post_name'));
	if($name eq ''){
		my $login = $wiki->get_login_info();
		if(defined($login)){
			$name = $login->{id};
		}
	}
	
	my $tmpl = HTML::Template->new(filename=>$wiki->config('tmpl_dir')."/comment.tmpl",
	                               die_on_bad_params=>0);
	$tmpl->param(NAME=>$name);
	
	my $buf = "<form method=\"post\" action=\"".$wiki->create_url()."\">\n".
	          $tmpl->output().
	          "<input type=\"hidden\" name=\"action\" value=\"COMMENT\">\n".
	          "<input type=\"hidden\" name=\"page\" value=\"".&Util::escapeHTML($page)."\">\n".
	          "<input type=\"hidden\" name=\"count\" value=\"".$self->{$page}."\">\n".
	          "<input type=\"hidden\" name=\"option\" value=\"".&Util::escapeHTML($opt)."\">\n".
	          "</form>\n";
	
	return $buf;
}

1;
