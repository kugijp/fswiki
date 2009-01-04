##############################################################
#
# ToDo�ץ饰����Υ��������ϥ�ɥ顣
# �����å����줿ToDo��ֺѡפ��ѹ����ޤ���
#
##############################################################
package plugin::todo::ToDoHandler;
use strict;

#=============================================================
# ���󥹥ȥ饯��
#=============================================================
sub new{
    my $class = shift;
    my $self = {};
    return bless $self,$class;
}

#=============================================================
# ���������᥽�å�
# ToDo�δ�λ����
#=============================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;

	my $buf = "";
	my $source  = $cgi->param("source");
	my @params  = $cgi->all_parameters;
	my $content = $wiki->get_page($source);
	my $page    = $cgi->param("page");

	# todo�����
	@params = grep(/^todo\.\d+/,@params);
	my ($param,$dothing);
	foreach $param (@params){
		#�᥿ʸ���򥯥�������
		my $dothing = quotemeta($cgi->param($param));
		# �ѥޡ������դ���
		$content =~ s/((^|\n)\*)\s*(\d+)\s+($dothing)(\n|$)/$1 �� $3 $4$5/;
	}
	$wiki->save_page($source,$content);

	# ��Ȥ��ɽ�����Ƥ����ڡ�����ɽ��
	$wiki->redirect($page);
}

1;
