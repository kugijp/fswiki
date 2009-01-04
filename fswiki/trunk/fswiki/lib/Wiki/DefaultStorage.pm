###############################################################################
# <p>
# FSWiki�ǥե���ȤΥ��ȥ졼���ץ饰����
# </p>
# <p>
# setup.dat��backup=1�⤷����backup�ǥ��쥯�ƥ��֤��ά�������ϣ�����Τߡ�
# backup=2�ʾ�⤷����0����ꤷ����������Хå����åפ��б����ޤ���
# backup=0����ꤷ������̵���¤˥Хå����åפ�Ԥ��ޤ���
# </p>
###############################################################################
package Wiki::DefaultStorage;
use File::Copy;
use strict;
use vars qw($MODTIME_FILE $PAGE_LIST_FILE);

# �ڡ����κǽ�����������Ͽ����ե�����
$MODTIME_FILE = "modtime.dat";

# �ڡ��������Υ���ǥå������Ǽ����ե�����
$PAGE_LIST_FILE = "pagelist.cache";

#==============================================================================
# <p>
# ���󥹥ȥ饯��
# </p>
#==============================================================================
sub new {
	my $class  = shift;
	my $wiki   = shift;
	my $backup = $wiki->{config}->{'backup'};
	
	if(!defined($backup) || $backup eq ""){
		$backup = 1;
	}
	
	my $self = {};
	$self->{wiki}          = $wiki;
	$self->{backup}        = $backup;
	$self->{exists_cache}  = {};
	$self->{modtime_cache} = undef;
	return bless $self,$class;
}

#==============================================================================
# <p>
# �ڡ��������
# </p>
#==============================================================================
sub get_page {
	my $self = shift;
	my $page = shift;
	my $path = shift;
	
	my $dir = $self->{wiki}->config('data_dir');
	if($path ne ""){
		$dir = "$dir/$path";
	}
	
	my $content = "";
	my $filename = &Util::make_filename($dir,&Util::url_encode($page),"wiki");
	if(-e $filename){
		open(DATA,$filename) or die $!;
		binmode(DATA);
		while(<DATA>){
			$content = $content.$_;
		}
		close(DATA);
	}
	
	return $content;
}

#==============================================================================
# <p>
# �ڡ�������¸
# </p>
#==============================================================================
sub save_page {
	my $self    = shift;
	my $page    = shift;
	my $content = shift;
	my $sage    = shift;
	my $wiki    = $self->{wiki};
	
	$content = '' if($content =~ /^[\r\n]+$/s); # added for opera
	
	# �ڡ���̾�ȥڡ������Ƥ�����
	$page = Util::trim($page);
	$content =~ s/\r\n/\n/g;
	$content =~ s/\r/\n/g;
	
	my $wikifile = &Util::make_filename($wiki->config('data_dir'),&Util::url_encode($page),"wiki");
	my $tmpfile  = "$wikifile.tmp";
	
	Util::file_lock($wikifile,1);
	
	# �Хå����å�
	my $BACKUP = $self->get_page($page);
	if($BACKUP ne '' && $BACKUP eq $content){
		Util::file_unlock($wikifile);
		return 0;
	}
	my $flag = '';
	if($BACKUP ne ""){
		$flag = 'update';
		my $backupfile = "";
		if($self->{backup}==1){
			$backupfile = &Util::make_filename($wiki->config('backup_dir'),&Util::url_encode($page),"bak");
		} else {
			$self->_rename_old_history($page);
			my $number = $self->_get_backup_number($page);
			$backupfile = &Util::make_filename($wiki->config('backup_dir'),&Util::url_encode($page),"$number.bak");
		}
		open(DATA,">$backupfile") or die $!;
		binmode(DATA);
		print DATA $BACKUP;
		close(DATA);
	} else {
		# backup���ʤ����ϡ�page_level��ǥե�����ͤ����ꤹ�롣
		$flag = 'create';
		my $login = $wiki->get_login_info();
		my $level = 0;
		if (defined($login)) {
			if ($login->{type} == 1) {
				$level = 1;
			} elsif ($login->{type} == 0) {
				$level = 2;
			}
		}
		if ($level > $wiki->config('refer_level')) {
			$level = $wiki->config('refer_level');
		}
		$wiki->set_page_level($page, $level);
	}

	# ����������Ͽ�ե����뤬�ʤ����Ϻ���
	unless(-e $wiki->config('config_dir')."/".$MODTIME_FILE){
		my @list = $self->get_page_list();
		my $hash = {};
		foreach my $p (@list){
			$hash->{$p}=$self->get_last_modified($p);
		}
		&Util::save_config_hash($wiki,$MODTIME_FILE,$hash);
	}
	# �񤭹���
	if($content eq ""){
		$self->_create_page_list_file($page, 'remove');
		unlink($wikifile);
		$wiki->set_page_level($page);
		# ������������
		my $modtime = &Util::load_config_hash($wiki,$MODTIME_FILE);
		delete $modtime->{$page};
		&Util::save_config_hash($wiki,$MODTIME_FILE,$modtime);
		# ������ϥХå����åץե������Ĥ�
		#unlink(&Util::make_filename($wiki->config('backup_dir'),&Util::url_encode($page),"bak"));
	} else {
		$self->_create_page_list_file($page, $flag);
		# ��񤭤���
		open(DATA,">$tmpfile") or die $!;
		binmode(DATA);
		print DATA $content;
		close(DATA);		
		# sage�Ǥʤ����Ϲ��������򹹿�
		if($sage != 1){
			my $modtime = &Util::load_config_hash($wiki,$MODTIME_FILE);
			$modtime->{$page} = time();
			&Util::save_config_hash($wiki,$MODTIME_FILE,$modtime);
		}
	}
	
	rename($tmpfile, $wikifile);
	Util::file_unlock($wikifile);
	
	return 1;
}

#------------------------------------------------------------------------------
# <p>
# �ڡ��������Υ���ǥå����ե������������������ޤ���
# �������˥ڡ���̾�����������'create'��'update'��'remove'�Τ����줫����ꤷ�ޤ���
# ����ǥå����ե����뤬¸�ߤ��ʤ����ϰ����˴ؤ�餺����ǥå����ե�����κ�����Ԥ��ޤ���
# </p>
#------------------------------------------------------------------------------
sub _create_page_list_file {
	my $self = shift;
	my $page = shift;
	my $flag = shift;
	my $wiki = $self->{'wiki'};
	my $file = $wiki->config('log_dir')."/".$PAGE_LIST_FILE;
	my $buf = "";
	
	unless(-e $file){
		opendir(DIR, $wiki->config('data_dir')) or die $!;
		my ($entry,@list);
		while($entry = readdir(DIR)){
			my $name = &Util::url_decode(substr($entry,0,rindex($entry,".")));
			my $type = substr($entry,rindex($entry,"."));
			my $flag = 0;
			if($type eq ".wiki"){
				$buf .= "$name\n";
			}
		}
		closedir(DIR);
		Util::save_config_text(undef, $file, $buf);
	} else {
		if($flag eq "remove"){
			my $names = Util::load_config_text(undef, $file);
			$names =~ s/(^|\n)\Q$page\E\n/\n/;
			Util::save_config_text(undef, $file, $names);
		} elsif($flag eq 'update'){
			# �ڡ����ι������ϲ��⤷�ʤ�
		} elsif($flag eq 'create') {
			open(DATA, ">>$file");
			print DATA "$page\n";
			close(DATA);
		}
	}
}

#------------------------------------------------------------------------------
# <p>
# �Хå����åץե��������Ϳ���������ֹ���������ץ饤�١��ȥ᥽�å�
# </p>
#------------------------------------------------------------------------------
sub _get_backup_number {
	my $self = shift;
	my $page = shift;
	my $wiki = $self->{wiki};
	my $num  = 0;
	my @backups = glob($wiki->config('backup_dir')."/".&Util::url_encode($page).".*.bak");
	foreach my $backup (@backups){
		if($backup =~ /^.+\.([0-9]+)\.bak$/){
			if($num < $1){
				$num = $1;
			}
		}
	}
	return $num + 1;
}

#------------------------------------------------------------------------------
# <p>
# ��¸�������Ķ����ʬ��������ץ饤�١��ȥ᥽�å�
# </p>
#------------------------------------------------------------------------------
sub _rename_old_history {
	my $self  = shift;
	my $page  = shift;
	my $wiki  = $self->{wiki};
	
	# ̵���¤ξ��ϲ��⤷�ʤ�
	if($self->{backup}==0){
		return;
	}
	
	my @files = glob($wiki->config('backup_dir')."/".&Util::url_encode($page).".*.bak");
	
	@files = sort {
		$a =~ /^.+\.([0-9]+)\.bak$/;
		my $num_a = $1;
		$b =~ /^.+\.([0-9]+)\.bak$/;
		my $num_b = $1;
		return $num_a <=> $num_b;
	} @files;
	
	my $count = 1;
	for(my $i=0;$i<=$#files;$i++){
		if($i > $#files - $self->{backup} + 1){
			my $newfile = &Util::make_filename($wiki->config('backup_dir'),&Util::url_encode($page),"$count.bak");
			move($files[$i],$newfile) or die $!;
			$count++;
		} else {
			unlink($files[$i]);
		}
	}
}

#==============================================================================
# <p>
# �ڡ����ΰ����������
# </p>
#==============================================================================
sub get_page_list {
	my $self   = shift;
	my $args   = shift;
	my $wiki   = $self->{wiki};
	my $sort   = "name";
	my $permit = "all";
	my $max    = 0;
	
	# ��������
	if(defined($args)){
		if(defined($args->{-sort})){
			$sort = $args->{-sort};
		}
		if(defined($args->{-permit})){
			$permit = $args->{-permit};
		}
		if(defined($args->{-max})){
			$max = $args->{-max};
		}
	}
	
	# �ڡ����ΰ��������
	my $file  = $wiki->config('log_dir')."/".$PAGE_LIST_FILE;
	$self->_create_page_list_file(undef, 'update') unless(-e $file);
	my $names = Util::load_config_text(undef, $file);
	my @list  = ();
	foreach my $name (split(/\n/,$names)){
		my $flag = 0;
		# ���ȸ��Τ���ڡ����Τ�
		if($permit eq "show"){
			if($wiki->can_show($name)){
				$flag = 1;
			}
			
		} elsif($permit eq "modify"){
			if($wiki->can_modify_page($name)){
				$flag = 1;
			}
			
		# ���ƤΥڡ���
		} elsif($permit eq "all"){
			$flag = 1;
		
		# ����ʳ��ξ��ϥ��顼
		} else {
			die "permit���ץ����λ��꤬�����Ǥ���";
		}
		if($flag == 1){
			push(@list,$name);
		}
	}
	
	# ̾���ǥ�����
	if($sort eq "name"){
		@list = sort { $a cmp $b } @list;
		
	# ���������ʿ����ˤ˥�����
	} elsif($sort eq "last_modified"){
		@list =  map  { $_->[0] }
		         sort { $b->[1] <=> $a->[1] }
		         map  { [$_, $wiki->get_last_modified2($_)] } @list;
	
	# ����ʳ��ξ��ϥ��顼
	} else {
		die "sort���ץ����λ��꤬�����Ǥ���";
	}
	
	return $max == 0 ? @list : splice(@list, 0, $max);
}

#==============================================================================
# <p>
# �ڡ����κǽ���������������ʪ��Ū��
# </p>
#==============================================================================
sub get_last_modified {
	my $self   = shift;
	my $page   = shift;
	my @status = stat(&Util::make_filename($self->{wiki}->config('data_dir'),&Util::url_encode($page),"wiki"));
	
	return $status[9];
}

#==============================================================================
# <p>
# �ڡ����κǽ�������������������Ū��
# </p>
#==============================================================================
sub get_last_modified2 {
	my $self    = shift;
	my $page    = shift;
	my $modtime = $self->{modtime_cache};
	
	unless(defined($modtime)){
		$modtime = &Util::load_config_hash($self->{wiki},$MODTIME_FILE);
		$self->{modtime_cache} = $modtime;
	}
	
	if(defined($modtime->{$page})){
		return $modtime->{$page};
	} else {
		return $self->get_last_modified($page);
	}
}

#===============================================================================
# <p>
# �ڡ�����¸�ߤ��뤫�ɤ���Ĵ�٤�
# </p>
#===============================================================================
sub page_exists {
	my $self = shift;
	my $page = shift;
	my $path = shift;
	
	if($self->{exists_cache} and defined($self->{exists_cache}->{"$path:$page"})){
		return $self->{exists_cache}->{"$path:$page"};
	}
	
	my $dir = $self->{wiki}->config('data_dir');
	if(defined $path and $path ne ""){
		$dir = "$dir/$path";
	}
	
	my $exists = (-e &Util::make_filename($dir,&Util::url_encode($page),"wiki"));
	$self->{exists_cache}->{"$path:$page"} = $exists;
	
	return $exists;
}

#==============================================================================
# <p>
# �Хå����åץ����פ����(single|all)��
# setup.dat���������Ƥˤ�äơ�������Τߤξ���single��
# ����Хå����åפ�ԤäƤ������all���ֵѤ��ޤ���
# </p>
#==============================================================================
sub backup_type {
	my $self = shift;
	
	if($self->{backup}==1){
		return "single";
	} else {
		return "all";
	}
}

#==============================================================================
# <p>
# ����Хå����åפ�ԤäƤ�����˥Хå����å׻���ΰ�����������ޤ���
# ������ΤߥХå����åפ������ư��Ƥ������undef���֤��ޤ���
# </p>
#==============================================================================
sub get_backup_list {
	my $self = shift;
	my $page = shift;
	
	if($self->{backup}==1){
		return undef;
	} else {
		my $wiki = $self->{wiki};
		my @files = glob($wiki->config('backup_dir')."/".Util::url_encode($page).".*.bak");
		
		@files = sort {
			$a =~ /^.+\.([0-9]+)\.bak$/;
			my $num_a = $1;
			$b =~ /^.+\.([0-9]+)\.bak$/;
			my $num_b = $1;
			return $num_b <=> $num_a;
		} @files;
		
		my @datelist;
		
		foreach my $file (@files){
			my @status = stat($file);
			push(@datelist,Util::format_date($status[9]));
		}
		
		return @datelist;
	}
}

#==============================================================================
# <p>
# �Хå����åפ�������ޤ���
# backup_type=all�ξ����������������(0��)����ꤷ�ޤ���
# </p>
#==============================================================================
sub get_backup {
	my $self     = shift;
	my $page     = shift;
	my $gen      = shift;
	my $content  = "";
	my $filename = "";
	
	if($self->{backup}!=1){
		# ����Хå����åפ���������꤬�ʤ����Ϻǿ��ΥХå����åפ����
		if(!defined($gen) || $gen eq ""){
			my @list = $self->get_backup_list($page);
			$gen = $#list;
		}
		$filename = &Util::make_filename($self->{wiki}->config('backup_dir'),&Util::url_encode($page),($gen+1).".bak");
		Util::debug("�Хå����åץե�����̾:$filename");
	} else {
		$filename = &Util::make_filename($self->{wiki}->config('backup_dir'),&Util::url_encode($page),"bak");
	}
	if(-e $filename){
		open(DATA,$filename) or die $!;
		binmode(DATA);
		while(<DATA>){
			$content = $content.$_;
		}
		close(DATA);
	}
	
	return $content;
}

#==============================================================================
# <p>
# �ڡ�������뤷�ޤ�
# </p>
#==============================================================================
sub freeze_page {
	my $self     = shift;
	my $pagename = shift;
	
	if(!$self->is_freeze($pagename)){
		my $freeze_file = $self->{wiki}->config('log_dir')."/".$self->{wiki}->config('freeze_file');
		Util::file_lock($freeze_file);
		open(DATA,">>$freeze_file") or die $!;
		binmode(DATA);
		print DATA $pagename."\n";
		close(DATA);
		Util::file_unlock($freeze_file);
		
		# ������쥯�Ȥ�������פ����ɡ�
		push(@{$self->{freeze_list}},$pagename);
	}
}

#==============================================================================
# <p>
# �ڡ��������������ޤ�
# </p>
#==============================================================================
sub un_freeze_page {
	my $self = shift;
	my $pagename = shift;
	
	if($self->is_freeze($pagename)){
		my $buf = "";
		open(DATA,$self->{wiki}->config('log_dir')."/".$self->{wiki}->config('freeze_file')) or die $!;
		while(<DATA>){
			chomp $_;
			if($pagename ne $_){
				$buf .= $_."\n";
			}
		}
		close(DATA);
		
		open(DATA,">".$self->{wiki}->config('log_dir')."/".$self->{wiki}->config('freeze_file')) or die $!;
		binmode(DATA);
		print DATA $buf;
		close(DATA);
		
		# ������쥯�Ȥ�������פ����ɡ�
		@{$self->{freeze_list}} = grep(!/^\Q$pagename\E$/,@{$self->{freeze_list}});
	}
}

#==============================================================================
# <p>
# ���ꥹ�Ȥ����
# </p>
#==============================================================================
sub get_freeze_list {
	my $self = shift;
	my $path = shift;
	
	if(!defined($path)){
		$path = "";
	}
	
	if(defined($self->{"$path:freeze_list"})){
		return @{$self->{"$path:freeze_list"}};
	}
	
	my $logdir = $self->{wiki}->config('log_dir');
	if($path ne ""){
		$logdir .= "/$path";
	}
	
	my @list;
	if(!-e "$logdir/".$self->{wiki}->config('freeze_file')){
		return @list;
	}
	
	open(DATA,"$logdir/".$self->{wiki}->config('freeze_file')) or die $!;
	while(<DATA>){
		chomp $_;
		push @list,$_;
	}
	close(DATA);
	
	$self->{"$path:freeze_list"} = \@list;
	return @list;
}

#==============================================================================
# <p>
# �������Ϥ����ڡ���������椫�ɤ�������٤ޤ�
# </p>
#==============================================================================
sub is_freeze {
	my $self     = shift;
	my $pagename = shift;
	my $path     = shift;
	
	foreach my $freeze_page ($self->get_freeze_list($path)){
		if($freeze_page eq $pagename){
			return 1;
		}
	}
	
	return 0;
}

#==============================================================================
# <p>
# �ڡ����λ��ȥ�٥�����ꤷ�ޤ���
# </p>
#==============================================================================
sub set_page_level {
	my $self  = shift;
	my $page  = shift;
	my $level = shift;
	
	my $all = &Util::load_config_hash($self->{wiki},"showlevel.log");
	if(defined($level)){
		$all->{$page} = $level;
	} else {
		delete($all->{$page});
	}
	&Util::save_config_hash($self->{wiki},"showlevel.log",$all);
	$self->{":show_level"} = $all;
}

#==============================================================================
# <p>
# �ڡ����λ��ȥ�٥��������ޤ���
# </p>
#==============================================================================
sub get_page_level {
	my $self = shift;
	my $page = shift;
	my $path = shift;
	
	if(!defined($path)){
		$path = "";
	}
	
	unless(defined($self->{"$path:show_level"})){
		# config_dir�򺹤��ؤ��Ƽ¹�
		my $configdir = $self->{wiki}->config('config_dir');
		if($path ne ""){
			$self->{wiki}->config('config_dir',"$configdir/$path");
		}
		
		$self->{"$path:show_level"} = &Util::load_config_hash($self->{wiki},"showlevel.log");
		
		# config_dir�򸵤��᤹
		$self->{wiki}->config('config_dir',$configdir);
	}
	
	if(defined($page)){
		if(defined($self->{"$path:show_level"}->{$page})){
			return $self->{"$path:show_level"}->{$page};
		} else {
			#return $self->{wiki}->config('refer_level');
			return 0;
		}
	} else {
		return $self->{"$path:show_level"};
	}
}

#==============================================================================
# <p>
# ��λ���˸ƤӽФ���ޤ������󥹥����ѿ��λ��Ȥ�������ޤ���
# </p>
#==============================================================================
sub finalize {
	my $self = shift;
	undef($self->{wiki});
}

1;
