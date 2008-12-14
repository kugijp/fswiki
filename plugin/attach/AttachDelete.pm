############################################################
#
# �ڡ�����������줿�Ȥ��Υեå�
#
############################################################
package plugin::attach::AttachDelete;
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
# �ڡ���������˸ƤӽФ����եå��ؿ�
#===========================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $cgi = $wiki->get_CGI;
	my $pagename = $cgi->param("page");
	my $encode_page = &Util::url_encode($pagename);
	
	opendir(DIR,$wiki->config('attach_dir')) or die $!;
	while(my $entry = readdir(DIR)){
		if(index($entry,$encode_page.".")==0){
			unlink($wiki->config('attach_dir')."/$entry");
		}
	}
	closedir(DIR);
}

1;
