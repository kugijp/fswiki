################################################################################
# <p>
#   FSWiki���Τǻ��Ѥ����桼�ƥ���ƥ��ؿ������󶡤���⥸�塼��Ǥ���
# </p>
################################################################################
package Util;
use strict;

#===============================================================================
# <p>
#   die��exit�Υ����Х饤������Ԥ��ޤ���
# </p>
#===============================================================================
sub override_die{
	our @original_exit_handler;
	@original_exit_handler or @original_exit_handler = (\&CORE::GLOBAL::die,\&CORE::GLOBAL::exit);
	*CORE::GLOBAL::die = \&Util::_die;
	*CORE::GLOBAL::exit = \&Util::_exit;
}

BEGIN {
	require Util;
#	*CORE::GLOBAL::die = \&Util::_die;
#	*CORE::GLOBAL::exit = \&Util::_exit;
	exists($ENV{MOD_PERL}) or override_die();
}

#===============================================================================
# <p>
#   �������Ϥ��줿ʸ�����URL���󥳡��ɤ����֤��ޤ���
# </p>
# <pre>
# $str = Util::url_encode($str)
# </pre>
#===============================================================================
sub url_encode {
	my $retstr = shift;
	$retstr =~ s/([^ 0-9A-Za-z])/sprintf("%%%.2X", ord($1))/eg;
	$retstr =~ tr/ /+/;
	return $retstr;
}

#===============================================================================
# <p>
#   �������Ϥ��줿ʸ�����URL�ǥ����ɤ����֤��ޤ���
# </p>
# <pre>
# $str = Util::url_decode($str);
# </pre>
#===============================================================================
sub url_decode{
	my $retstr = shift;
	$retstr =~ tr/+/ /;
	$retstr =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
	return $retstr;
}

#===============================================================================
# <p>
#   Cookie��path�˻��ꤹ��ʸ�����������ޤ���
# </p>
# <pre>
# $path = Util::cookie_path($wiki);
# </pre>
#===============================================================================
sub cookie_path {
	my $wiki = shift;
	my $script_name = quotemeta($wiki->config('script_name'));
	my $path = $ENV{'REQUEST_URI'};
	$path =~ s/\?.*//;
	$path =~ s/$script_name$//;
	return $path;
}

#===============================================================================
# <p>
#   �ǥ��쥯�ȥꡢ�ե�����̾����ĥ�Ҥ��礷�ƥե�����̾���������ޤ���
# </p>
# <pre>
# my $filename = Util::make_filename(�ǥ��쥯�ȥ�̾,�ե�����̾,��ĥ��);
# </pre>
#===============================================================================
sub make_filename {
	my $dir  = shift;
	my $file = shift;
	my $ext  = shift;
	
	return $dir."/".$file.".".$ext;
}

#===============================================================================
# <p>
#   �������Ϥ��줿ʸ�����HTML�����򥨥������פ����֤��ޤ���
# </p>
# <pre>
# $str = Util::escapeHTML($str);
# </pre>
#===============================================================================
sub escapeHTML {
	my($retstr) = shift;
	my %table = (
		'&' => '&amp;',
		'"' => '&quot;',
		'<' => '&lt;',
		'>' => '&gt;',
	);
	$retstr =~ s/([&\"<>])/$table{$1}/go;
	$retstr =~ s/&amp;#([0-9]{1,5});/&#$1;/go;
	$retstr =~ s/&#(0*(0|9|10|13|38|60|62));/&amp;#$1;/g;
#	$retstr =~ s/&amp;([a-zA-Z0-9]{2,8});/&$1;/go;
	return $retstr;
}


#===============================================================================
# <p>
#   ���դ�&quot;yyyyǯmm��dd�� hh��miʬss��&quot;�����˥ե����ޥåȤ��ޤ���
# </p>
# <pre>
# my $date = Util::format_date(time());
# </pre>
#===============================================================================
sub format_date {
	my $t = shift;
	my ($sec, $min, $hour, $mday, $mon, $year) = localtime($t);
	return sprintf("%04dǯ%02d��%02d�� %02d��%02dʬ%02d��",
	               $year+1900,$mon+1,$mday,$hour,$min,$sec);
}

#===============================================================================
# <p>
#   ʸ�����ξü�ζ�����ڤ���Ȥ��ޤ���
# </p>
# <pre>
# $text = Util::trim($text);
# </pre>
#===============================================================================
sub trim {
	my $text = shift;
	if(!defined($text)){
		return "";
	}
	$text =~ s/^(?:\s)+//o;
	$text =~ s/(?:\s)+$//o;
	return $text;
}


#===============================================================================
# <p>
#   ������������ʸ����Τߤ�������ޤ���
# <p>
# <pre>
# my $html = "<B>ʸ����</B>";
# # &lt;B&gt;��&lt;/B&gt;��������&quot;ʸ����&quot;�Τ߼���
# my $text = Util::delete_tag($html);
# </pre>
#===============================================================================
sub delete_tag {
	my $text = shift;
	$text =~ s/<(.|\s)+?>//g;
	return $text;
}

#===============================================================================
# <p>
#   ���ͤ��ɤ��������å����ޤ������ͤξ��Ͽ��������Ǥʤ����ϵ����֤��ޤ���
# </p>
# <pre>
# if(Util::check_numeric($param)){
#   # �����ξ��ν���
# } else {
#   # �����Ǥʤ����ν���
# }
# </pre>
#===============================================================================
sub check_numeric {
	my $text = shift;
	if($text =~ /^[0-9]+$/){
		return 1;
	} else {
		return 0;
	}
}


#===============================================================================
# <p>
#   �����Ԥ˥᡼����������ޤ���
#   setup.dat���������Ƥ˱�����sendmail���ޥ�ɤ⤷����SMTP�̿��ˤ�äƥ᡼�뤬��������ޤ���
#   �ɤ�������ꤵ��Ƥ��ʤ�����������Ԥ鷺�����顼�ˤ�ʤ�ޤ���
#   SMTP�����������硢���Υ᥽�åɤ�ƤӽФ���������Net::SMTP��use����ޤ���
# </p>
# <pre>
# Util::send_mail($wiki,��̾,��ʸ);
# </pre>
#===============================================================================
sub send_mail {
	my $wiki    = shift;
	my $subject = Jcode->new(shift)->mime_encode();
	my $content = &Jcode::convert(shift,'jis');
	
	if(($wiki->config('send_mail') eq "" && $wiki->config('smtp_server') eq "") ||
	   $wiki->config('admin_mail') eq ""){
		return;
	}

	my ($sec, $min, $hour, $day, $mon, $year, $wday) = localtime(time);
	my $wday_str  = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat')[$wday];
	my $mon_str   = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')[$mon];
	my $date = sprintf("%s, %02d %s %4d %02d:%02d:%02d +0900", $wday_str, $day, $mon_str, $year+1900, $hour, $min, $sec);
	
	my $admin_mail = $wiki->config('admin_mail');
	foreach my $to (split(/,/,$admin_mail)){
		$to = trim($to);
		next if($to eq '');
		my $mail = "Subject: $subject\n".
		           "From: $to\n".
		           "To: $to\n".
		           "Date: $date\n".
		           "Content-Transfer-Encoding: 7bit\n".
		           "Content-Type: text/plain; charset=\"ISO-2022-JP\"\n".
		           "\n".
		           $content;
		
		# sendmail���ޥ�ɤ�����
		if($wiki->config('send_mail') ne ""){
			open(MAIL,"| ".$wiki->config('send_mail')." ".$to);
			print MAIL $mail;
			close(MAIL);
			
		# Net::SMTP������
		} else {
			eval("use Net::SMTP;");
			my $smtp = Net::SMTP->new($wiki->config('smtp_server'));
			$smtp->mail($to);
			$smtp->to($to);
			$smtp->data();
			$smtp->datasend($mail);
			$smtp->quit();
		}
	}
}

#===============================================================================
# <p>
#   ���饤����Ȥ��������ä��ɤ��������å����ޤ���
#   �������äξ��Ͽ��������Ǥʤ����ϵ����֤��ޤ���
# </p>
# <pre>
# if(Util::handyphone()){
#   # �������äξ��ν���
# } else {
#   # �������äǤʤ����ν���
# }
# </pre>
#===============================================================================
sub handyphone {
	my $ua = $ENV{'HTTP_USER_AGENT'};
	if(!defined($ua)){
		return 0;
	}
	if($ua=~/^DoCoMo\// || $ua=~ /^J-PHONE\// || $ua=~ /UP\.Browser/ || $ua=~ /\(DDIPOCKET\;/ || $ua=~ /\(WILLCOM\;/ || $ua=~ /^Vodafone\// || $ua=~ /^SoftBank\//){
		return 1;
	} else {
		return 0;
	}
}

#===============================================================================
# <p>
#   ���饤����Ȥ����ޡ��ȥե��󤫤ɤ��������å����ޤ���
#   ���ޡ��ȥե���ξ��Ͽ��������Ǥʤ����ϵ����֤��ޤ���
# </p>
# <pre>
# if(Util::smartphone()){
#   # ���ޡ��ȥե���ξ��ν���
# } else {
#   # ���ޡ��ȥե���Ǥʤ����ν���
# }
# </pre>
#===============================================================================
sub smartphone {
	my $ua = $ENV{'HTTP_USER_AGENT'};
	if(!defined($ua)){
		return 0;
	}
	if($ua =~ /Android/ || $ua =~ /iPhone/){
		return 1;
	} else {
		return 0;
	}
}

#===============================================================================
# load_config_hash�ؿ��ǻ��Ѥ��륢�󥨥��������Ѵؿ�
#===============================================================================
{
	my %table = ("\\\\" => "\\", "\\n" => "\n", "\\r" => "\r");

	sub _unescape {
		my $value = shift;
		$value =~ s/(\\[\\nr])/$table{$1}/go;
		return $value;
	} 
}

#===============================================================================
# <p>
#   ����ե�������Ǽ����ǥ��쥯�ȥ�ʥǥե���ȤǤ�./config�ˤ�����ꤷ���ե�������ɤ߹��ߡ�
#   �ϥå����ե���󥹤Ȥ��Ƽ������ޤ����������ˤ�$wiki���Ϥ�����������ǥե�����̾����ꤷ�ޤ���
# </p>
# <pre>
# my $hashref = Util::load_config_hash($wiki, &quot;hoge.dat&quot;);
# </pre>
#===============================================================================
sub load_config_hash {
	my $wiki     = shift;
	my $filename = shift;
	my $text = &load_config_text($wiki,$filename);
	my @lines = split(/\n/,$text);
	my $hash = {};
	foreach my $line (@lines){
		$line = &trim($line);
		if(index($line,"#")==0 || $line eq "\n" || $line eq "\r" || $line eq "\r\n"){
			next;
		}
		my ($name, @spl) = map {/^"(.*)"$/ ? scalar($_ = $1, s/\"\"/\"/g, $_) : $_}
		                     ("=$line" =~ /=\s*(\"[^\"]*(?:\"\"[^\"]*)*\"|[^=]*)/g);
		
		$name  = &trim(_unescape($name));
		my $value = &trim(_unescape(join('=', @spl)));
		
		if($name ne ''){
			$hash->{$name} = $value;
		}
	}
	return $hash;
}

#===============================================================================
# <p>
#   ����ե�������Ǽ����ǥ��쥯�ȥ�ʥǥե���ȤǤ�./config�ˤ�����ꤷ���ե�������ɤ߹��ߡ�
#   �ե��������Ƥ�ʸ����Ȥ��Ƽ������ޤ����������ˤ�$wiki���Ϥ�����������ǥե�����̾����ꤷ�ޤ���
# </p>
# <pre>
# my $content = Util::load_config_text($wiki, &quot;hoge.dat&quot;);
# </pre>
#===============================================================================
sub load_config_text {
	my $wiki     = shift;
	my $filename = shift;
	my $fullpath = $filename;
	if(defined($wiki)){
		$fullpath = $wiki->config('config_dir')."/$filename";
	}
	
	if(defined($wiki->{config_cache}->{$fullpath})){
		return $wiki->{config_cache}->{$fullpath};
	}
	
	open(CONFIG,$fullpath) or return "";
	binmode(CONFIG);
	my $buf = "";
	while(my $line = <CONFIG>){
		$buf .= $line;
	}
	close(CONFIG);
	
	$buf =~ s/\r\n/\n/g;
	$buf =~ s/\r/\n/g;
	
	$wiki->{config_cache}->{$fullpath} = $buf;
	
	return $buf;
}

#===============================================================================
# <p>
#   �������Ϥ����ϥå����ե���󥹤�����ե�������Ǽ����ǥ��쥯�ȥ�ʥǥե���ȤǤ�./config�ˤ�
#  ���ꤷ���ե�����̾����¸���ޤ����������ˤ�$wiki���Ϥ�����������ǥե�����̾����ꤷ�ޤ���
# </p>
# <pre>
# Util::save_config_hash($wiki, �ե�����̾, �ϥå����ե����);
# </pre>
#===============================================================================
sub save_config_hash {
	my $wiki     = shift;
	my $filename = shift;
	my $hash     = shift;
	my $text     = _make_quoted_text($hash);
	&save_config_text($wiki,$filename,$text);
}

#===============================================================================
# <p>
#   �������Ϥ����ƥ����Ȥ�����ե�������Ǽ����ǥ��쥯�ȥ�ʥǥե���ȤǤ�./config�ˤ�
#  ���ꤷ���ե�����̾����¸���ޤ����������ˤ�$wiki���Ϥ�����������ǥե�����̾����ꤷ�ޤ���
# </p>
# <pre>
# Util::save_config_hash($wiki, �ե�����̾, �ƥ�����);
# </pre>
#===============================================================================
sub save_config_text {
	my $wiki     = shift;
	my $filename = shift;
	my $text     = shift;
	
	$text =~ s/\r\n/\n/g;
	$text =~ s/\r/\n/g;
	
	my $fullpath = $filename;
	if(defined($wiki)){
		$fullpath = $wiki->config('config_dir')."/$filename";
	}
	
	my $tmpfile = "$fullpath.tmp";
	
	file_lock($fullpath);
	
	open(CONFIG,">$tmpfile") or die $!;
	binmode(CONFIG);
	print CONFIG $text;
	close(CONFIG);
	
	rename($tmpfile, $fullpath);
	file_unlock($fullpath);
	
	$wiki->{config_cache}->{$fullpath} = $text;
}

#===============================================================================
# <p>
#   ����ե�������ɤ߹��ߤȽ񤭹��ߤ�Ʊ��Υ�å���ǹԤ�����δؿ���
#   �ɤ߹�������Ƥ��Ѵ����ƽ񤭹��ߤ�Ԥ��褦�ʾ��˻��Ѥ��ޤ���
# </p>
# <pre>
# sub convert {
#   my $hash = shift;
#   ...
#   return $hash;
# }
# 
# Util::sync_update_config($wiki, �ե�����̾, \&convert);
# </pre>
#===============================================================================
sub sync_update_config {
	my $wiki     = shift;
	my $filename = shift;
	my $function = shift;
	
	my $fullpath = $filename;
	if(defined($wiki)){
		$fullpath = $wiki->config('config_dir')."/$filename";
	}
	
	my $tmpfile = "$fullpath.tmp";
	
	file_lock($fullpath);
	
	my $hash = load_config_hash($wiki, $filename);
	my $text = _make_quoted_text(&$function($hash));
	
	open(CONFIG,">$tmpfile") or die $!;
	binmode(CONFIG);
	print CONFIG $text;
	close(CONFIG);
	
	rename($tmpfile, $fullpath);
	file_unlock($fullpath);
	
	$wiki->{config_cache}->{$fullpath} = $text;
}

#===============================================================================
# �ϥå����ƥ����Ȥ��Ѵ����뤿��Υ桼�ƥ���ƥ���
#===============================================================================
sub _make_quoted_text {
	my $hash = shift;
	my $text = "";
	foreach my $key (sort(keys(%$hash))){
		my $value = $hash->{$key};
		
		$key =~ s/"/""/g;
		$key =~ s/\\/\\\\/g;
		$key =~ s/\n/\\n/g;
		$key =~ s/\r/\\r/g;
		
		$value =~ s/"/""/g;
		$value =~ s/\\/\\\\/g;
		$value =~ s/\n/\\n/g;
		$value =~ s/\r/\\r/g;
		
		$text .= qq{"$key"="$value"\n};
	}
	return $text;
}

#===============================================================================
# <p>
#   �������Ϥ����ե�������å����ޤ���
#   �ե�������λ���ɬ��Ʊ���ե�����̾��Util::file_unlock��ƤӽФ��Ʋ�������
#   ��å��˼��Ԥ�������die���ޤ���
# </p>
# <pre>
# Util::file_lock(�ե�����̾, ��ȥ饤����ʢ⥿���ॢ���Ȼ��֡���ά�ġ�);
# </pre>
#===============================================================================
# ��å����Ƥ���ե������Ͽ������λ����̤����Υ�å����������ݸ���Ĥ��������ɤ������Τ�ʤ���
sub file_lock {
	my $lock  = shift() . ".lock";
	my $retry = shift || 5;
#	debug("file_lock($$): $lock");
	
	if(-e $lock){
		my $mtime = (stat($lock))[9];
		rmdir($lock) if($mtime < time() - 60);
	}
	
	while(!mkdir($lock,0777)){
		die "Lock is busy." if(--$retry <= 0);
		sleep(1);
	}
}

#===============================================================================
# <p>
#   �������Ϥ����ե�����Υ�å��������ޤ���
# </p>
# <pre>
# Util::file_unlock(�ե�����̾);
# </pre>
#===============================================================================
sub file_unlock {
	my $lock  = shift() . ".lock";
	rmdir($lock);
#	debug("file_unlock($$): $lock");
}

#===============================================================================
# <p>
#   ����饤��ץ饰���󤫤饨�顼��å��������֤����˻��Ѥ��Ƥ���������
# </p>
# <pre>
#  return Util::inline_error('�ץ�������̾�����ꤵ��Ƥ��ޤ���');
# </pre>
#===============================================================================
sub inline_error {
	my $message = shift;
	my $type    = shift;
	
	if(uc($type) eq "WIKI"){
		return "<<$message>>";
	} else {
		return "<span class=\"error\">".&Util::escapeHTML($message)."</span>";
	}
}

#===============================================================================
# <p>
#   �ѥ饰��եץ饰���󤫤饨�顼��å��������֤����˻��Ѥ��Ƥ���������
# </p>
# <pre>
# return Util::paragraph_error('�ץ�������̾�����ꤵ��Ƥ��ޤ���');
# </pre>
#===============================================================================
sub paragraph_error {
	my $message = shift;
	my $type    = shift;
	
	if(uc($type) eq "WIKI"){
		return "<<$message>>";
	} else {
		return "<p><span class=\"error\">".&Util::escapeHTML($message)."</span></p>";
	}
}


#===============================================================================
# <p>
#   �����URL��GET�ꥯ�����Ȥ�ȯ�Ԥ����쥹�ݥ󥹤Υܥǥ������ֵѤ��ޤ���
#   ���δؿ���ƤӽФ���������LWP::UserAgent��use����ޤ���
# </p>
# <pre>
# my $response = Util::get_response($wiki,URL);
# </pre>
#===============================================================================
sub get_response {
	my $wiki = shift;
	my $url  = shift;

	eval("use LWP::UserAgent;");
	eval("use MIME::Base64;");

	my $ua  = LWP::UserAgent->new();
	my $req = HTTP::Request->new('GET',$url);
	
	# �ץ���������
	my $proxy_host = $wiki->config('proxy_host');
	my $proxy_port = $wiki->config('proxy_port');
	my $proxy_user = $wiki->config('proxy_user');
	my $proxy_pass = $wiki->config('proxy_pass');
	
	if($proxy_host ne "" && $proxy_port ne ""){
		$ua->proxy("http","http://$proxy_host:$proxy_port");
		if($proxy_user ne "" && $proxy_pass ne ""){
			$req->header('Proxy-Authorization'=>"Basic ".&MIME::Base64::encode("$proxy_user:$proxy_pass"));
		}
	}
	
	# �ꥯ�����Ȥ�ȯ��
	my $res = $ua->request($req);
	return $res->content();
}

#===============================================================================
# <p>
#   �⥸�塼��̾����ե�����̾��������ޤ���
#   �㤨��plugin::core::Install���Ϥ���plugin/core/Install.pm���ֵѤ���ޤ���
# </p>
# <pre>
# $file = Util::get_module_file(�⥸�塼��̾);
# </pre>
#===============================================================================
sub get_module_file {
	return join('/',split(/::/,shift)).'.pm';
}

#===============================================================================
# <p>
#   �ǥХå�����debug.log�ˤ򥫥��ȥǥ��쥯�ȥ�˽��Ϥ��ޤ���
#   Wiki::DEBUG=1�ξ��Τ߽��Ϥ�Ԥ��ޤ���
# </p>
#===============================================================================
sub debug {
	my $message = shift;
	if($Wiki::DEBUG==1){
		my $date = &Util::format_date(time());
		my $lock = "debug.log.lock";
		my $retry = 5;
		if(-e $lock){
			my $mtime = (stat($lock))[9];
			rmdir($lock) if($mtime < time() - 60);
		}
		
		while(!mkdir($lock,0777)){
			die "Lock is busy." if(--$retry <= 0);
			sleep(1);
		}
		open(LOG,">>debug.log");
		print LOG "$date $message\n";
		close(LOG);
		rmdir($lock);
	}
}

#===============================================================================
# <p>
#   Digest::Perl::MD5���Ѥ����ѥ���ɤΰŹ沽��Ԥ��ޤ���
#   �������˥ѥ���ɡ���������˥�������Ȥ��Ϥ��ޤ���
#   ���Υ᥽�åɤ�ƤӽФ���������Digest::Perl::MD5��use����ޤ���
# </p>
# <pre>
# my $md5pass = Util::md5($pass,$account);
# </pre>
#===============================================================================
sub md5 {
	my $pass = shift;
	my $salt = shift;
	
	eval("use Digest::Perl::MD5;");
	
	my $md5 = Digest::Perl::MD5->new();
	$md5->add($pass);
	$md5->add($salt);
	
	return $md5->hexdigest;
}

#===============================================================================
# <p>
#   HTTP�إå���Content-Disposition�Ԥ��������ޤ���
#   ź�եե������PDF�ʤɤ˻��Ѥ��ޤ���
# </p>
#===============================================================================
sub make_content_disposition {
	my ($filename, $disposition) = @_;
	my $ua = $ENV{"HTTP_USER_AGENT"};
	my $encoded = ($ua =~ /MSIE/ ? &Jcode::convert($filename, 'sjis') : Jcode->new($filename)->mime_encode(''));
	return "Content-Disposition: $disposition;filename=\"".$encoded."\"\n\n";
}

#===============================================================================
# <p>
#   CGI::Carp�⥸�塼��������die�ؿ��򥪡��С��饤�ɤ��ޤ���
#    ���顼��å��������������������ʪ��die�ؿ���ƤӽФ��ޤ���
# </p>
#===============================================================================
sub _die {
	my ($arg,@rest) = @_;
	$arg = join("", ($arg,@rest));
	my($pack,$file,$line,$sub) = caller(1);
	$arg .= " at $file line $line." unless $arg=~/\n$/;
	CORE::die($arg);
}

#===============================================================================
# <p>
#   exit�ؿ��򥪡��С��饤�ɤ��ޤ���
# </p>
#===============================================================================
sub _exit {
	CORE::die('safe_die');
}

#===============================================================================
# <p>
#   die��exit�Υ����Х饤�����������ޤ���
# </p>
#===============================================================================
sub restore_die{
	our @original_exit_handler;
	*CORE::GLOBAL::die = $original_exit_handler[0];
	*CORE::GLOBAL::exit = $original_exit_handler[1];
}

1;
