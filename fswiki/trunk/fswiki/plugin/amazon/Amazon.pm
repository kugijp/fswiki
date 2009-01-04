package plugin::amazon::Amazon;
###############################################################################
#
# <p>���ꤷ�����Ҥν�Ƥ�amazon�����������ɽ������amazon�ν�ɾ�ڡ����إ�󥯤�Ϥ�ޤ���</p>
# <pre>
#   {{amazon aid}}
# </pre>
# <p>
#   setup.dat �� amazon_aid �Ȥ�����������ꤹ��� amazon �Υ���������ID �Ĥ��ǥ�󥯤��Ϥ��ޤ���
# </p>
# <p>
#   ���᡼����¸�ߤ��ʤ����ɤ�����ǧ���뤿���amazon�Υ����Ф���³���Ƥ���Τǡ�
#   �ץ�����ͳ�ǳ��˽Ф�ɬ�פ�������ϡ��ץ�������������setup.dat�����ꤷ�Ƥ���ɬ�פ�����ޤ���
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
# �ѥ饰��ե᥽�å�
#==============================================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $item = shift;
	$item = Util::escapeHTML($item);
	my $noimg = 'http://images-jp.amazon.com/images/G/09/icons/books/comingsoon_books.gif';
	my $aid = $wiki->config('amazon_aid');
	my $link = 'http://www.amazon.co.jp/exec/obidos/ASIN/' .  $item;
	$link .= '/' . $aid if $aid;
	my $image;
	if($item =~ /^4/){
		$image = "http://images-jp.amazon.com/images/P/$item.09.MZZZZZZZ.jpg";
	} else {
		$image = "http://images-jp.amazon.com/images/P/$item.01.MZZZZZZZ.jpg";
	}
	
	my $response = &Util::get_response($wiki,$image);
	$image = $noimg if (length($response) < 1024);
	
	my $buf = "<div class=\"amazon\"><a href='$link'><img src='$image'></a></div>";
	return $buf;
}

1;
