############################################################
#
# <p>������̾��ɽ�����ޤ�</p>
# <pre>
# {{loginname}}
# {{loginname ̤������,�����桼��,���̥桼��}}
# </pre>
# <p>
# ������Ŭ���˾�ά�Ǥ��ޤ�. 
# <code>?</code> �򤪤���, ������̾���ִ�����ޤ�.
# </p>
# <p>
# ��ά���ˤ�̾�����Ǥޤ�(̤��������� <code>-</code>
# �ˤʤ�ޤ�).
# ����Ȥ������Ȥ��ˤ� <code>&#61;</code> �Ȥ��Ƥ�������. 
# ��Ƭ�� <code>&#61;</code> �Ͼ�˽����ޤ�.
# </p>
# <p>
# FSWiki�����ɤȤ��ƽ��Ϥ���ޤ�.
# </p>
#
############################################################
package plugin::loginstate::LoginName;
#use strict;


sub new {
	my $class = shift;
	bless {}, $class;
}


sub inline {
	my $self = shift;
	my $wiki = shift;
	my $login_info = $wiki->get_login_info( $wiki->get_CGI() );

	my $name = '-';
	my $val  = '?';

	if(!defined($login_info)){         # ̤������
		$val = $_[0] if($_[0] ne '');
	} elsif($login_info->{type} == 0){ # ������
		$name = $login_info->{id};
		$val = $_[1] if($_[1] ne '');
	} else {                           # ���̥桼��
		$name = $login_info->{id};
		$val = $_[2] if($_[2] ne '');
	}

	$val =~ s/^=//;
	$val =~ s/\\(\\|\?)|(\\\@)|(\?)/$1 ? $1 : $2 ? "" : $name/ge;
	$val;
}

1;
__END__

# Original source
# Copyright YAMASHINA Hio
