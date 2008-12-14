############################################################
#
# PDF�ץ饰����ν���������WikiFarm�ˤ��Wiki�������
# ������Ԥ��եå��ץ饰����
#
############################################################
package plugin::pdf::PDFInitializer;
use strict;
use File::Path;
#===========================================================
# ���󥹥ȥ饯��
#===========================================================
sub new {
	my $class = shift;
	my $self  = {};
	return bless $self,$class;
}

#===========================================================
# PDF�ץ饰����ν����
#===========================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $name = shift;
	
	# remove_wiki�եå�
	if($name eq "remove_wiki"){
		my $path = $wiki->get_CGI()->param("path");
		if(-e $wiki->config('pdf_dir').$path){
			rmtree($wiki->config('pdf_dir').$path) or die $!;
		}
	
	# initialize�եå�
	} elsif($name eq "initialize") {
		# Farm��ư��Ƥ�����ϥ����Х��ѿ�����
		my $path_info = $wiki->get_CGI()->path_info();
		$path_info =~ m<^((/[^/]+/)*)/([^/]+)$>;
		if(length($path_info)>0){
			$wiki->config('pdf_dir',$wiki->config('pdf_dir').$path_info);
		}
		
		unless(-e $wiki->config('pdf_dir')){
			mkpath($wiki->config('pdf_dir')) or die $!;
		}
	}
}

1;
