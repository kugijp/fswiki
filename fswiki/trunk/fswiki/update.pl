#####################################################################
#
# �w����ȍ~�ɍX�V���ꂽ�t�@�C���𒊏o����X�N���v�g
#
#####################################################################
use File::Path;
use File::Copy;

my $date = $ARGV[0];
my $dir  = $ARGV[1];

if($date eq "" || !($date =~ /^[1-2][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]$/)){
	&print_help();
	exit;
}

$date =~ s/-//g;
$date = int($date);

if($dir ne ""){
	if(-e $dir){
		print "$dir�f�B���N�g�����폜���܂��B\n";
		rmtree($dir);
	}
	if(-e "$dir.zip"){
		print "$dir.zip���폜���܂��B\n";
		unlink "$dir.zip";
	}
}

$find_flag = 0;
&search_dir($date,".",$dir);

if($dir ne ""){
	if($find_flag == 1){
		print "���k�t�@�C�����쐬���܂��B\n";
		system("zip $dir.zip -r $dir");
	}

}

#====================================================================
# �w���v��\��
#====================================================================
sub print_help {
	print "�w����t�ȍ~�ɍX�V���ꂽ�t�@�C���𒊏o���A�A�[�J�C�u���쐬���܂��B\n";
	print "\n";
	print "perl update.pl YYYY-MM-DD [�o�͐�f�B���N�g����]\n";
	print "  �f�B���N�g�������ȗ�����ƊY���t�@�C��������ʂɕ\�����ďI�����܂��B\n";
}

#====================================================================
# �f�B���N�g��������
#====================================================================
sub search_dir {
	my $date = shift;
	my $dir  = shift;
	my $to   = shift;
	my @list = ();
	
	opendir(DIR,$dir);
	while(my $entry = readdir(DIR)){
		if(index($entry,".")!=0 && $entry ne "CVS"){
			if($dir eq "." && ($entry eq "log" || $entry eq "backup" || $entry eq "attach" || $entry eq "pdf")){
				
			} elsif($dir eq "./data" && $entry ne "FrontPage" && $entry ne "Help"){
				
				
			} else {
				push(@list,"$dir/$entry");
			}
		}
	}
	closedir(DIR);
	
	foreach my $entry (@list){
		if(-d $entry){
			&search_dir($date,$entry,$to);
		} else {
			# �t�@�C���̍X�V�������`�F�b�N
			my @status = stat($entry);
			my ($sec,$min,$hour,$mday,$mon,$year)=localtime($status[9]);
			my $date_str = sprintf("%04d%02d%02d",$year+1900,$mon+1,$mday);
			
			if(int($date_str) >= $date){
				print $entry."\n";
				# �f�B���N�g�����w�肳��Ă���΃f�B���N�g���ɃR�s�[
				if($to ne ""){
					# ������Ƃ��̂ւ�L�^�i�C�E�E�E
					my $path = $dir;
					$path =~ s/^\.//;
					my $copydir = "$to$path";
					unless(-e $copydir){
						mkpath($copydir) or die "$copydir�̍쐬�Ɏ��s���܂����B";
					}
					
					my $name = $entry;
					$name =~ s/^(.*?\/)*//g;
					copy($entry,"$copydir/$name") or die "$copydir/$name�̃R�s�[�Ɏ��s���܂����B";
					
					$find_flag = 1;
				}
			}
		}
	}
}
