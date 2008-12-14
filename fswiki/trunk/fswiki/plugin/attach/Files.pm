############################################################
#
# <p>���Υڡ�����ź�դ���Ƥ���ե���������ɽ�����ޤ���</p>
# <p>Footer��Menu�˵��Ҥ��Ƥ����������Ǥ���</p>
# <pre>
# {{files}}
# </pre>
# <p>Menu�˵��Ҥ�����ʤɡ�v���ץ�����Ĥ���ȽĤ�ɽ�����뤳�Ȥ��Ǥ��ޤ���</p>
# <pre>
# {{files v}}
# </pre>
#
############################################################
package plugin::attach::Files;
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
# ź�եե�����ΰ�����ɽ�����륤��饤��ؿ�
#===========================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $way  = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	if(!defined($way)){
		$way = "";
	}
	# ���ȸ������뤫�ɤ���Ĵ�٤�
	unless($wiki->can_show($pagename)){
		return undef;
	}
	
	my ($entry,$buf);
	
	my $editFlag = &can_attach_delete($wiki, $pagename);
#	my $login = $wiki->get_login_info();
#	if(!$wiki->can_modify_page($pagename)){
#		$editFlag = 0;
#	} elsif($wiki->config('accept_attach_delete')==0 && !defined($login)){
#		$editFlag = 0;
#	} elsif($wiki->config('accept_attach_delete')==2 && (!defined($login) || $login->{type}!=0)){
#		$editFlag = 0;
#	}
	
	if($way eq "V" || $way eq "v"){
		$buf = "<ul>\n";
	}
	
	foreach my $file (&get_file_list($wiki,$pagename)){
		if($way eq "V" || $way eq "v"){
			$buf = $buf."<li><a href=\"".$wiki->create_url({action=>"ATTACH",page=>$pagename,file=>$file})."\">".
			       Util::escapeHTML($file)."</a>";
		} else {
			$buf = $buf."<a href=\"".$wiki->create_url({action=>"ATTACH",page=>$pagename,file=>$file})."\">".
			       Util::escapeHTML($file)."</a>";
		}
		
		if($editFlag){
			$buf .= "[<a href=\"".$wiki->create_url({action=>"ATTACH",CONFIRM=>"yes",page=>$pagename,file=>$file})."\">���</a>]";
		}
		
		if($way eq "V" || $way eq "v"){
			$buf .= "</li>\n";
		} else {
			$buf .= "\n";
		}
	}
	
	if($way eq "V" || $way eq "v"){
		$buf .= "</ul>\n";
	}
	
	return $buf;
}

#===========================================================
# �ե�����ΰ������������ؿ�
#===========================================================
sub get_file_list {
	my $wiki = shift;
	my $page = shift;
	my $encode_page = &Util::url_encode($page);
	my @list;
	if(-e $wiki->config('attach_dir')){
		opendir(DIR,$wiki->config('attach_dir')) or die $!;
		while(my $entry = readdir(DIR)){
			if(index($entry,$encode_page.".")==0){
				my $file = (split(/\./,$entry))[1];
				push(@list,&Util::url_decode($file));
			}
		}
		closedir(DIR);
	}
	@list = sort { $a cmp $b } @list;
	return @list;
}

#===========================================================
# ź�եե����뤬�����ǽ���ɤ���Ƚ�ꤹ��ؿ�
#===========================================================
sub can_attach_delete {
	my $wiki  = shift;
	my $page  = shift;
	my $login = $wiki->get_login_info();
	
	my $config = $wiki->config('accept_attach_delete');
	$config = 0 if($config eq "");
	
	if(!$wiki->can_modify_page($page)){
		return 0;
	} elsif($config==0 && !defined($login)){
		return 0;
	} elsif($config==2 && (!defined($login) || $login->{type}!=0)){
		return 0;
	}
	
	return 1;
}

#===========================================================
# ź�եե����뤬������ǽ���ɤ���Ƚ�ꤹ��ؿ�
#===========================================================
sub can_attach_update {
	my $wiki  = shift;
	my $page  = shift;
	my $login = $wiki->get_login_info();
	
	my $config = $wiki->config('accept_attach_update');
	$config = 1 if($config eq "");
	
	if(!$wiki->can_modify_page($page)){
		return 0;
	} elsif($config==1 && !defined($login)){
		return 0;
	} elsif($config==2 && (!defined($login) || $login->{type}!=0)){
		return 0;
	}
	
	return 1;
}

1;
