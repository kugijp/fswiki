###############################################################################
#
# �ѥ�᡼������EUC�Ѵ�����CGI���饹
#
###############################################################################
package CGI2;
use CGI;
use CGI::Session;
use vars qw(@ISA);
use strict;
@ISA = qw(CGI);

#==============================================================================
# ���󥹥ȥ饯��
#==============================================================================
sub new {
	my $class = shift;
	$ENV{PATH_INFO} =~ s/^$ENV{SCRIPT_NAME}//;
	my $self  = CGI->new();
	
	return bless $self,$class;
}

#==============================================================================
# �����ॢ���Ȥ��Ƥ��륻�å������˴����ޤ�
#==============================================================================
sub remove_session {
	my $self = shift;
	my $wiki = shift;
	
	my $dir   = $wiki->config('session_dir');
	my $limit = $wiki->config('session_limit');
	
	opendir(SESSION_DIR,$dir) or die "$!: $dir";
	my $timeout = time() - (60 * $limit);
	while(my $entry = readdir(SESSION_DIR)){
		if($entry =~ /^cgisess_/){
			my @status = stat("$dir/$entry");
			if($status[9] < $timeout){
				unlink("$dir/$entry");
			}
		}
	}
	closedir(SESSION_DIR);
}

#==============================================================================
# CGI::Session���֥������Ȥ����
#==============================================================================
sub get_session {
	my $self  = shift;
	my $wiki  = shift;
	my $start = shift;
	
	# ���å���󳫻ϥե饰��Ω�äƤ��餺��Cookie�˥��å����ID��
	# ¸�ߤ��ʤ����ϥ��å������������ʤ�
	if(!defined($self->{session_cache})){
		if((not defined $start or $start!=1) && $self->cookie(-name=>'CGISESSID') eq ""){
			return undef;
		}
		my $dir   = $wiki->config('session_dir');
		my $limit = $wiki->config('session_limit');
		my $path  = &Util::cookie_path($wiki);
		my $session = CGI::Session->new("driver:File",$self,{Directory=>$dir});
		my $cookie  = CGI::Cookie->new(-name=>'CGISESSID',-value=>$session->id(),-expires=>"+${limit}m",-path=>$path);
		print "Set-Cookie: ".$cookie->as_string()."\n";
		$self->{session_cache} = $session;
		return $session;
		
	} else {
		return $self->{session_cache};
	}
}

#==============================================================================
# �ѥ�᡼��������ޤ�������
#==============================================================================
sub param {
	my $self  = shift;
	my $name  = shift;
	my $value = shift;
	
	# ɬ��EUC�ؤ��Ѵ���Ԥ�
	if(Util::handyphone()){
		if(defined($name)) {
			#my @array = map {&Jcode::convert(\$_, "euc")} $self->CGI::param($name,$value);
			#return @array;
			my @values = $self->CGI::param($name,$value);
			my @array = ();
			foreach my $value (@values){
				&Jcode::convert(\$value,"euc");
				push(@array,$value);
			}
			if($#array==0){
				return $array[0];
			} elsif($#array!=-1){
				return @array;
			} else {
				return undef;
			}
		} else {
			return map { &Jcode::convert(\$_, "euc") } $self->CGI::param();
		}
	} else {
		if(defined($name)) {
			return $self->CGI::param($name, $value);
		} else {
			return $self->CGI::param();
		}
	}
}

#==============================================================================
# ���ߤΥڡ��������ܤ��뤿���URL��������ޤ���
#==============================================================================
sub get_url {
	my $self  = shift;
	my $url   = $self->url();
	my $query = "";
	foreach my $param ($self->param()){
		if($query eq ""){
			$query = "?";
		} else {
			$query .= "&";
		}
		$query .= &Util::url_encode($param);
		$query .= "=";
		$query .= &Util::url_encode($self->param($param));
	}
	return $url.$query;
}

#==============================================================================
# ��λ���˸ƤӽФ���ޤ���
#==============================================================================
sub finalize {
	my $self = shift;
	undef($self->{session_cache}->{_SESSION_OBJ});
	undef($self->{session_cache});
}

1;
