############################################################
#
# <p>��������֤�ɽ�����ޤ�</p>
# <pre>
# {{loginstate}}
# {{loginstate ̤������,�����桼��,���̥桼��}}
# </pre>
# <p>
# ������Ŭ���˾�ά�Ǥ��ޤ�. 
# </p>
# <p>
# ����Ȥ������Ȥ��ˤ� <code>&#61;</code> �Ȥ��Ƥ�������. 
# ��Ƭ�� <code>&#61;</code> �Ͼ�˽����ޤ�.
# </p>
# <p>
# FSWiki�����ɤȤ��ƽ��Ϥ���ޤ�.
# </p>
#
############################################################
package plugin::loginstate::LoginState;
#use strict;

sub new {
	my $class = shift;
	bless {}, $class;
}


sub inline {
	my $self = shift;
	my $wiki = shift;
	my $login_info = $wiki->get_login_info( $wiki->get_CGI() );
	my $val;

	if(!defined($login_info)){         # ̤������
		$val = "NOT LOGIN";
		$val = $_[0] if($_[0] ne '');
	} elsif($login_info->{type} == 0){ # ������
		$val = "ADMIN";
		$val = $_[1] if($_[1] ne '');
	} else {                           # ���̥桼��
		$val = "USER";
		$val = $_[2] if($_[2] ne '');
	}

	$val =~ s/^=//;
	$val;
}

1;
__END__

# Original source
# Copyright YAMASHINA Hio
