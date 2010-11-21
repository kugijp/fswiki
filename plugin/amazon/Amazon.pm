package plugin::amazon::Amazon;
###############################################################################
#
# <p>���ꤷ�����Ҥν�Ƥ�amazon�����������ɽ������amazon�ν�ɾ�ڡ����إ�󥯤�Ϥ�ޤ���</p>
# <pre>
#   {{amazon asin[,comment]}}
# </pre>
# <p>
#   setup.dat �� amazon_aid �Ȥ�����������ꤹ��� amazon �Υ���������ID �Ĥ��ǥ�󥯤��Ϥ��ޤ���
# </p>
# <p>
#   ���᡼����¸�ߤ��ʤ����ɤ�����ǧ���뤿���amazon�Υ����Ф���³���Ƥ���Τǡ�
#   �ץ�����ͳ�ǳ��˽Ф�ɬ�פ�������ϡ��ץ�������������setup.dat�����ꤷ�Ƥ���ɬ�פ�����ޤ���
# </p>
# <p>
#   comment ����������������ȡ���Ʋ����Τ����ˤ���ʸ���󤫤��󥯤�Ϥ�ޤ���
# </p>
#
###############################################################################
use LWP::UserAgent;
#use HTTP::Response;
#use HTTP::Request;

#==============================================================================
# ���󥹥ȥ饯��
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}
#==============================================================================
# ����饤��᥽�å�
#==============================================================================
sub inline {
	my $self    = shift;
	my $wiki    = shift;
	my $item    = shift;
	my $comment = shift;
	
	$item = Util::escapeHTML($item);
	my $buf;
	my $link;
	my $aid = $wiki->config('amazon_aid');

	if(Util::handyphone()){
		if ($aid != '' ){
			$link = 'http://www.amazon.co.jp/gp/aw/rd.html?uid=NULLGWDOCOMO&at='. $aid .'&a='. $item .'&dl=1&url=%2Fgp%2Faw%2Fd.html';
		} else {
			$link = 'http://www.amazon.co.jp/gp/aw/rd.html?uid=NULLGWDOCOMO&a='. $item .'&dl=1&url=%2Fgp%2Faw%2Fd.html';
		}
	} else {
		$link = 'http://www.amazon.co.jp/exec/obidos/ASIN/' .  $item;
		$link .= '/' . $aid . '/ref=nosim' if $aid;
	}

	if($comment eq ""){
		my $noimg = 'http://images-jp.amazon.com/images/G/09/icons/books/comingsoon_books.gif';
		my $image;
		my $response;
		for my $num ( '09','01' ) {
			$image = "http://images-jp.amazon.com/images/P/$item.$num.MZZZZZZZ.jpg";
			$response = &Util::get_response($wiki,$image);
			last unless (length($response) < 1024);
		}
		$image = $noimg if (length($response) < 1024);
		$buf = '<img src="'.$image.'">';
	} else{
		$buf = Util::escapeHTML($comment);
	}
	
	return '<span class="amazonb"><a href="'.$link.'">'.$buf.'</a></span>';
}

1;
