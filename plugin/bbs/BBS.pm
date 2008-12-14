###############################################################################
#
# <p>�Ǽ���������ƥե��������Ϥ��ޤ���</p>
# <pre>
# {{bbs}}
# </pre>
# <p>
#   �ץ饰����򵭽Ҥ������˷Ǽ���������ƥե������ɽ�����ޤ���
#   �ե����फ���������ƤϤ��Υڡ������ɲä���ޤ���
# </p>
# <p>
#   �ǥե���ȤǤϳ���Ƶ������ֿ��ѤΥ����ȥե����ब���Ϥ���ޤ�����
#   no_comment���ץ�����Ĥ����OFF�ˤ��뤳�Ȥ��Ǥ��ޤ���
# </p>
# <pre>
# {{bbs no_comment}}
# </pre>
# <p>
#   reverse_comment���ץ�����Ĥ���ȳƵ����ˤĤ�comment�ץ饰�����
#   reverse���ץ�����Ĥ��뤳�Ȥ��Ǥ��������Ȥ������ɽ�������褦�ˤʤ�ޤ���
# </p>
# <pre>
# {{bbs reverse_comment}}
# </pre>
#
###############################################################################
package plugin::bbs::BBS;
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
	my $option = shift;
	my $cgi    = $wiki->get_CGI;
	
	my $page = $cgi->param("page");
	if($page eq ""){
		return "";
	}
	
	if(!defined($self->{$page})){
		$self->{$page} = 1;
	} else {
		$self->{"count"}++;
	}
	
	my $tmpl = HTML::Template->new(filename=>$wiki->config('tmpl_dir')."/bbs.tmpl",
	                               die_on_bad_params=>0);
	
	# ̾�������
	my $name = $cgi->cookie(-name=>'post_name');
	if($name eq ''){
		my $login = $wiki->get_login_info();
		if(defined($login)){
			$name = $login->{id};
		}
	}
	$tmpl->param(NAME=>$name);
	
	my $buf = "<form method=\"post\" action=\"".$wiki->create_url()."\">\n".
	          $tmpl->output.
	          "<input type=\"hidden\" name=\"action\" value=\"BBS\">\n".
	          "<input type=\"hidden\" name=\"page\" value=\"".&Util::escapeHTML($page)."\">\n".
	          "<input type=\"hidden\" name=\"count\" value=\"".$self->{$page}."\">\n";
	
	if($option eq "no_comment"){
		$buf .="<input type=\"hidden\" name=\"option\" value=\"no_comment\">\n";
	} elsif($option eq "reverse_comment"){
		$buf .="<input type=\"hidden\" name=\"option\" value=\"reverse_comment\">\n";
	}
	return $buf."</form>";
}

1;
