###############################################################################
#
# <p>FSWiki�ʳ���ʸˡ���Խ���Ԥ����˳ƥե����ޥå��Ѥ�Help�ڡ�����ɽ�����뤿��Υץ饰����Ǥ���</p>
#
###############################################################################
package plugin::core::FormatHelp;
use strict;
#==============================================================================
# ���󥹥ȥ饯��
#==============================================================================
sub new {
	my $class = shift;
	my $self  = {};
	return bless $self,$class;
}
#==============================================================================
# �Խ��ե����ޥåȤ˱������إ�פ���Ϥ��ޤ���
#==============================================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my $cgi    = $wiki->get_CGI();
	my $format = $wiki->get_edit_format();

	# Farm�ξ��γ��ؤ����
	my $page  = "Help/$format";
	my $depth = split(/\//,$cgi->path_info());
	if($depth!=0){
		$page = ":$page";
		for(my $i=0;$i<$depth-1;$i++){
			if($i!=0){
				$page = "/$page";
			}
			$page = "..$page";
		}
	}

	# includeƱ�ͤ�΢���ǽ���
	my $source = $wiki->get_page($page);
	if($source eq ""){
		return &Util::paragraph_error("�ڡ�����¸�ߤ��ޤ���","WIKI");
	} else {
		my $pagetmp = $cgi->param("page");
		$cgi->param("page",$page);
		$wiki->get_current_parser()->parse($source);
		$cgi->param("page",$pagetmp);
		return undef;
	}
}

1;
