################################################################################
#
# <p>��������ɽ�����ޤ���</p>
# <pre>
# {{calendar ������̾}}
# </pre>
# <p>
#   �������Ρ�&lt;&lt;�פ򥯥�å���������
#   ��&gt;&gt;�פ򥯥�å��������
#   ǯ��򥯥�å�����Ȥ��η�Υ������ȥڡ������Ƥ����ɽ�����ޤ���
#   �ޤ��������������դ򥯥�å�����ȳ����������դΥڡ�����ɽ��
#   �ʥڡ�����¸�ߤ��ʤ������Խ����̤�ɽ���ˤ��ޤ���
# </p>
# <p>
#   ���ץ������Խ����̤˸��ܤȤ���ɽ�������ƥ�ץ졼�ȥڡ�������ꤹ�뤳�Ȥ��Ǥ��ޤ���
# </p>
# <pre>
# {{calendar ������̾[,�ƥ�ץ졼�ȤȤʤ�ڡ���̾[,ɽ�������]]}}
# </pre>
# <p>
#   ɽ��������<code>[Ⱦ��10�ʿ�]next</code>�Ƚ񤯤ȡ�[Ⱦ��10�ʿ�]���Υ���������ɽ�����ޤ���
#   ɽ��������<code>[Ⱦ��10�ʿ�]prev</code>�Ƚ񤯤ȡ�[Ⱦ��10�ʿ�]�����Υ���������ɽ�����ޤ���
#   ɽ��������<code>[Ⱦ�Ѥ�1��12]</code>�Ƚ񤯤ȡ�[1��12]��Υ���������ɽ�����ޤ���
#   ����¾��ɽ��������̵�뤵��ޤ���
# </p>
# <p>
#   �ʲ��˥������ץ饰����λ�����򼨤��ޤ���
# </p>
# <pre>
# {{calendar ͽ��ɽ}}
# {{calendar ͽ��ɽ,ͽ��ɽ�ƥ�ץ졼��}}
# {{calendar ͽ��ɽ,ͽ��ɽ�ƥ�ץ졼��,6}} : 6��Υ�������
# {{calendar ͽ��ɽ, ,1next}} : ���Υ�������
# {{calendar ͽ��ɽ, ,2prev}} : �衹��Υ�������
# </pre>
# <p>
#   CSS��ɽ���������ѹ����뤳�Ȥ����ޤ������Ѥ��Ƥ��륯�饹̾�ϰʲ����̤�Ǥ���
# </p>
# <ul>
#   <li>today - ����������</li>
#   <li>have - ͽ��������Τ�������</li>
#   <li>navi - �ʥӥ��������С�</li>
#   <li>week - ����</li>
#   <li>calendar - ����������table��ʬ</li>
#   <li>plugin-calendar - calendar�ץ饰����ν�������</li>
# </ul>
# <p>
#   ���Ѥ��Ƥ���id̾�ϰʲ����̤�Ǥ���
# </p>
# <ul>
#   <li>calendar-[Ⱦ�Ѥ�1��12] - [1��12]����ꤵ�줿��</li>
#   <li>calendar-[Ⱦ��10�ʿ�]next - [Ⱦ��10�ʿ�]������ꤷ����</li>
#   <li>calendar-[Ⱦ��10�ʿ�]prev - [Ⱦ��10�ʿ�]��������ꤷ����</li>
#   <li>calendar-sun - ������</li>
#   <li>weekday - ʿ��</li>
#   <li>calendar-sat - ������</li>
# </ul>
#
################################################################################
package plugin::calendar::Calendar;
use strict;
use plugin::calendar::CalendarHandler;
#===============================================================================
# ���󥹥ȥ饯��
#===============================================================================
sub new {
    my $class = shift;
    my $self = {};
    return bless $self,$class;
}

#===============================================================================
# �ѥ饰���
#===============================================================================
sub paragraph {
    my $self  = shift;
    my $wiki  = shift;
    my $name  = shift;
    my $template = shift;
    my $argmon = shift;
#	my $align = shift;
    
    my $error_message = "";

    # ¸�ߤ��ʤ��ƥ�ץ졼�Ȥ���ꤵ�줿��硣
    undef $template if !$wiki->page_exists($template);

#	# ɽ�����ֻ��꤬�ʤ���硣
#	$align = "left" if $align eq "";


    # ���顼�����å�
    $error_message = "������̾�����ꤵ��Ƥ��ޤ���" if($name eq "");
#    $error_message = "ɽ������ꤵ��Ƥ��ޤ���" if($argmon eq "");
#    $error_message = "���ֻ��꤬�ְ�äƤ��ޤ���[$align]" if !(($align eq "center") || ($align eq "right") || ($align eq "left"));
    return Util::paragraph_error($error_message) if !($error_message eq "");
    
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime(time());
    $year += 1900;
    $mon  += 1;

    my $id = "";
    # ɽ����������
    if ($argmon =~ /(\d*)next/i) { # ���л���ʼ����
	my $step = ($1 > 0) ? $1 : 1;
	$mon += $step;
	$id = "calendar-${step}next";
    } elsif ($argmon =~ /(\d*)prev/i) {	# ���л���������
	my $step = ($1 > 0) ? $1 : 1;
	$mon -= $step;
	$id = "calendar-${step}prev";
    } elsif ($argmon =~ /(\d+)/) { # ���л���
	if ($1>=1 and $1<=12) {
	    $year += (($1 - $mon) >  6) ? -1 : 0;
	    $year += (($1 - $mon) < -6) ?  1 : 0;
	    $mon = $1;
	    $id = "calendar-$1";
	}
    } else {			# ����ʤ�
    }
    # ǯ���������
    if ($mon > 0) {
	$year += int (($mon - 1) / 12);
    } else {
	$year += int (($mon - 12) / 12);
    }
    $mon = ($mon - 1) % 12 + 1;

    return &plugin::calendar::CalendarHandler::make_calendar($wiki,$year,$mon,$name,$template,$id);
}

1;
