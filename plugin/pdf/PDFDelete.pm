###############################################################################
#
# �ڡ���������˺�����PDF��������եå��ץ饰����
#
###############################################################################
package plugin::pdf::PDFDelete;
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
# �եå��᥽�å�
#==============================================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $cgi = $wiki->get_CGI;
	my $pagename = $cgi->param("page");
	my $encode_page = &Util::url_encode($pagename);
	
	opendir(DIR,$wiki->config('pdf_dir')) or die $!;
	while(my $entry = readdir(DIR)){
		if(index($entry,$encode_page)==0){
			unlink($wiki->config('pdf_dir')."/$entry");
		}
	}
	closedir(DIR);
}

1;
