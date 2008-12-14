############################################################
# 
# ToDoAdd�ץ饰����Υ��������ϥ�ɥ顣
# ToDo���ɲä��ޤ���
# 
############################################################
package plugin::todo::ToDoAddHandler;
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
# ToDo���ɲ�
#===========================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $priority = $cgi->param("priority");
	my $dothing  = $cgi->param("dothing");
	my $dist     = $cgi->param("dist");
	my $page     = $cgi->param("page");
	
	# �ե����ޥåȥץ饰����ؤ��б�
	my $format = $wiki->get_edit_format();
	$priority = $wiki->convert_to_fswiki($priority,$format,1);
	$dothing  = $wiki->convert_to_fswiki($dothing ,$format,1);
	
	if($priority =~ /\d+/ && $dothing ne "" && $dist ne ""){
		my $content = $wiki->get_page($dist);
		$content =~ s/(^|\n)\*\s*\d+\s+\Q$dothing\E(\n|$)/$1* $priority $dothing$2/
		 or
		$content =~ s/(^|.*\n)(\Q{{todoadd}}\E)/$1* $priority $dothing\n$2/
		 or
		$content =~ s/(\n?)$/\n* $priority $dothing$1/;
		$wiki->save_page($dist,$content);
		$wiki->do_hook("save_end");
	}
	
	$wiki->redirect($page);
}

1;
