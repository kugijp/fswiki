####################################################################
#
# <p>ɽ����Υڡ����κǽ��������֤�ɽ�����ޤ���</p>
# <p>�����˥ڡ���̾���Ϥ����Ȥ�Ǥ��ޤ���</p>
# <pre>
# {{lastmodified page(�ڡ���̾��ά��)}}
# </pre>
#
####################################################################
package plugin::info::LastModified;
use strict;

#==================================================================
# ���󥹥ȥ饯��
#==================================================================
sub new {
    my $class = shift;
    my $self = {};
    return bless $self,$class;
}

#==================================================================
# ����饤��᥽�å�
#==================================================================
sub inline {
	my $self = shift;
	my $wiki = shift;
	my $page = shift;
	my $cgi  = $wiki->get_CGI;
	my $buf  = "";
	
	if(!defined($page) || $page eq ""){
		$page = $cgi->param("page");
	}
	
	if($page ne "" && $wiki->page_exists($page)){
		$buf .= "�ǽ��������֡�".&Util::format_date($wiki->get_last_modified2($page));
	}
	
	return $buf;
}

1;
