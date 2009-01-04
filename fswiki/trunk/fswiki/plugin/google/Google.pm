######################################################################
#
# <p>Google�θ����ܥå�����ɽ�����ޤ���</p>
# <pre>
# {{google}}
# </pre>
# <p>�����ȸ�����ǽ��������뤳�Ȥ�Ǥ��ޤ���</p>
# <pre>
# {{google ������̾}}
# </pre>
# <p>���ܸ�Υڡ������鸡�������뤿��������ɽ�����뤳�Ȥ��Ǥ��ޤ���</p>
# <pre>
# {{google l}}
# </pre>
# <p>Menu������Google���ȥƥ����ȥܥå����ȥܥ����Ĥ����֤Ǥ��ޤ���</p>
# <pre>
# {{google v}}
# </pre>
# <p>������̤򿷤�����ǳ����褦�˽���ޤ���</p>
# <pre>
# {{google t}}
# </pre>
# <p>Google���Υ��������طʿ������Ǥ��ޤ���</p>
# <pre>
# {{google (25|40|50|60)(wht|gry|blk)}}
# </pre>
# <p>
#   ���ο�����������(����Υ��Ȥ���Ψ)�����Υ���ե��٥åȤ�
#   =�طʿ�(wht=��gry=������blk=��)�ˤʤäƤ��ޤ���
#   �ºݤΥ��ΰ����ϡ�
#   =<a href='http://www.google.co.jp/intl/ja/logos.html'>Google ������</a>
#   �򻲾Ȥ��Ƥ���������
# </p>
# <p>�ƥ����ȥܥå�������������Ǥ��ޤ���</p>
# <pre>
# {{google s��}}
# </pre>
# <p>����1��255�δ֤ǻ��ꤷ�Ƥ���������</p>
# <p>ɽ�����֤λ��꤬����ޤ���</p>
# <pre>
# {{google (center|right|left)}}
# </pre>
# <p>
#   �����Υ��ץ�����ʻ�Ѥ��뤳�Ȥ�Ǥ��ޤ���
#   ����ޤǶ��ڤäƵ��Ҥ��Ƥ��������������Ǥ�դǤ���
# </p>
# <pre>
# {{google ������̾,l,v,t,25wht,s��,center}}
# </pre>
#
######################################################################
package plugin::google::Google;
use strict;

#=====================================================================
# ���󥹥ȥ饯��
#=====================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#=====================================================================
# �ѥ饰��ե᥽�å�
#=====================================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my @args = @_;

	my $error = undef;
	my $logo = '40wht';
	my $domain = undef;
	my $lang = undef;
	my $size = 31;
	my $align = "center";
	my $target = '';
	my $vertical_br = '';
	my $logolist = '|25wht|40wht|50wht|60wht|25gry|40gry|50gry|60gry|25blk|40blk|50blk|60blk|';

	foreach my $arg (@args) {
		$arg = Util::trim($arg);
		if (index($logolist, '|' . lc($arg) . '|') >= 0) {
			$logo = lc($arg);
		} elsif (lc($arg) eq 'v') {
			$vertical_br = '<br>';
		} elsif (lc($arg) eq 'l') {
			$lang = 1;
		} elsif (lc($arg) eq 't') {
			$target = 'target=blank';
		} elsif ($arg =~ /^s([0-9]+)/) {
			$size = $1;
			if (($size < 1) || ($size > 255)) {
				$error = '��������1��255�ǻ��ꤷ�Ƥ���������';
			}
		} elsif ($arg =~ /(center|right|left)/) {
			$align = $1;
		} else {
			if (defined($domain)) {
				$error = '�ɥᥤ��ʣ�����ꤵ��Ƥ��ޤ���';
			} elsif (($arg eq '') || ($arg =~ /[^-0-9A-Za-z.]/)) {
				$error = '�ɥᥤ��̾�˻��ѤǤ��ʤ�ʸ��������ޤ���';
			} else {
				$domain = $arg;
			}
		}
	}
	return &Util::paragraph_error($error) if defined($error);

	if ($vertical_br ne '') {
		my $siteoption = '';

		$siteoption .= <<"EOD" if defined($domain);
<input type=hidden name=domains value="${domain}"><br><input type=radio name=sitesearch value="">WWW <input type=radio name=sitesearch value="${domain}" checked>${domain}
EOD

		$siteoption .= <<"EOD" if defined($lang);
<br><input type=radio name=lr value="" checked>���������� <input type=radio name=lr value=lang_ja >���ܸ�
EOD

		$siteoption = "<font size=-1>${siteoption}</font>" if $siteoption ne '';

		return <<"EOD";
<!-- Google  -->
<div class="plugin_google" align="$align">
<form method=GET action="http://www.google.co.jp/search" $target>
<a href="http://www.google.co.jp/"><IMG SRC="http://www.google.com/logos/Logo_${logo}.gif" border="0" ALT="Google" align="absmiddle"></a> <INPUT type=submit name=btnG VALUE="����"><input type=hidden name=hl value="ja"><input type=hidden name=ie value="EUC-JP"><br>
<INPUT TYPE=text name=q size=${size} maxlength=255 value="">${siteoption}
</form>
</div>
<!-- Google -->
EOD
	} else {
		my $siteoption = '';

		$siteoption .= <<"EOD" if defined($domain);
<input type=hidden name=domains value="${domain}"><br><input type=radio name=sitesearch value=""> WWW �򸡺� <input type=radio name=sitesearch value="${domain}" checked> ${domain} �򸡺�
EOD

		$siteoption .= <<"EOD" if defined($lang);
<br><input type=radio name=lr value="" checked>���������Τ��鸡�� <input type=radio name=lr value=lang_ja >���ܸ�Υڡ����򸡺�
EOD

		$siteoption = "<font size=-1>${siteoption}</font>" if $siteoption ne '';

		return <<"EOD";
<!-- Google  -->
<div class="plugin_google" align="$align">
<FORM method=GET action="http://www.google.co.jp/search" $target>
<TABLE style="border: none"><tr><td  style="border: none" align=center>
<A HREF="http://www.google.co.jp/">
<IMG SRC="http://www.google.com/logos/Logo_${logo}.gif" 
border="0" ALT="Google" align="absmiddle"></A>
</td>
<td  style="border: none" align=center>
<INPUT TYPE=text name=q size=${size} maxlength=255 value="">
<input type=hidden name=hl value="ja">
<input type=hidden name=ie value="EUC-JP">
<INPUT type=submit name=btnG VALUE="Google����">${siteoption}
</td></tr></TABLE>
</FORM>
</div>
<!-- Google -->
EOD
	}
}

1;
