############################################################
#
# attach�ץ饰����ν���������WikiFarm�ˤ��Wiki�����
# �ν�����Ԥ��եå��ץ饰����
#
############################################################
package plugin::attach::AttachInitializer;
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
# attach�ץ饰����ν����
#===========================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $name = shift;
	
	# remove_wiki�եå�
	if($name eq "remove_wiki"){
		my $path = $wiki->get_CGI()->param("path");
		if(-e $wiki->config('attach_dir').$path){
			rmtree($wiki->config('attach_dir').$path);
		}
		
	# initialize�եå�
	} elsif($name eq "initialize"){
		# Farm��ư��Ƥ�����ϥ����Х��ѿ�����
		my $path_info = $wiki->get_CGI()->path_info();
		if(length($path_info)>0){
			$wiki->config('attach_dir',$wiki->config('attach_dir').$path_info);
		}
		unless(-e $wiki->config('attach_dir')){
			mkpath($wiki->config('attach_dir'));
		}
	}
}

1;
