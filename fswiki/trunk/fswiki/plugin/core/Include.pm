###############################################################################
#
# <p>���ꤷ���ڡ������⤷���ϻ���ڡ����λ���ѥ饰��դ򥤥󥯥롼�ɤ��ޤ���</p>
# <p>
#   �ڡ������Τ򥤥󥯥롼�ɤ�����ϰ����˥ڡ���̾����ꤷ�ޤ���
# </p>
# <pre>
# {{include �ڡ���̾}}
# </pre>
# <p>
#   ����ڡ���������Υѥ饰��դ򥤥󥯥롼�ɤ������
#   �ڡ���̾��³�����裲�����˥ѥ饰���̾����ꤷ�ޤ���
# </p>
# <pre>
# {{include �ڡ���̾,�ѥ饰���̾}}
# </pre>
#
###############################################################################
package plugin::core::Include;
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
# �ѥ饰��մؿ�
#==============================================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my $page   = shift;
	my $para   = shift;
	my $cgi    = $wiki->get_CGI;
	
	# ���顼�����å�
	if($self->{count}++ > 50){
		return &Util::paragraph_error("include�ץ饰����¿�����ޤ���","WIKI");
	}
	if($page eq ""){
		return &Util::paragraph_error("�ڡ��������ꤵ��Ƥ��ޤ���","WIKI");
	}
	if(!$wiki->page_exists($page)){
		return &Util::paragraph_error("�ڡ�����¸�ߤ��ޤ���","WIKI");
	}
	if(!$wiki->can_show($page)){
		return &Util::paragraph_error("�ڡ����λ��ȸ��¤�����ޤ���","WIKI");
	}
	if($page eq $cgi->param("page")){
		return &Util::paragraph_error("Ʊ��Υڡ�����include�Ǥ��ޤ���","WIKI");
	}
	foreach my $incpage (@{$self->{stack}}){
		if($incpage eq $page){
			return &Util::paragraph_error("Ʊ��Υڡ�����include�Ǥ��ޤ���","WIKI");
		}
	}
	
	# �����������
	my $source = $wiki->get_page($page);
	
	# �ѥ饰��դ����ꤵ��Ƥ������ϥѥ饰��դ��ڤ�Ф�
	$para = quotemeta(Util::trim($para));
	if($para ne ""){
		if($source =~ /(\n|^)!!!\s*$para\s*(\n!!!|$)/){
			return &Util::paragraph_error("�ѥ饰��դ���ʸ��¸�ߤ��ޤ���","WIKI");
		} elsif($source =~ /(\n|^)!!!\s*$para\s*\n((.|\s|\r|\n)*?)\s*(\n!!!|$)/){
			$source = $2;
		} elsif($source =~ /(\n|^)!!\s*$para\s*(\n!!|$)/){
			return &Util::paragraph_error("�ѥ饰��դ���ʸ��¸�ߤ��ޤ���","WIKI");
		} elsif($source =~ /(\n|^)!!\s*$para\s*\n((.|\s|\r|\n)*?)\s*(\n!!|$)/){
			$source = $2;
		} elsif($source =~ /(\n|^)!\s*$para\s*(\n!|$)/){
			return &Util::paragraph_error("�ѥ饰��դ���ʸ��¸�ߤ��ޤ���","WIKI");
		} elsif($source =~ /(\n|^)!\s*$para\s*\n((.|\s|\r|\n)*?)\s*(\n!|$)/){
			$source = $2;
		} else {
			return &Util::paragraph_error("�ڡ�����¸�ߤ��ޤ���","WIKI");
		}
	}
	
	# �����å��ˤĤ��̵�¥롼���ɻ��ѡ�
	push(@{$self->{stack}},$page);
	
	# ����ä�΢��
	my $pagetmp = $cgi->param("page");
	$cgi->param("page",$page);
	$wiki->get_current_parser()->parse($source);
	$cgi->param("page",$pagetmp);
	
	# �����å�������
	pop(@{$self->{stack}});
	
	return undef;
}

1;
