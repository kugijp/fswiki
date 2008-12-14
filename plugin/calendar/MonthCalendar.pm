###################################################################
#
# <p>calendar�ץ饰����Ǻ��������ڡ����Τ�����������ʬ�Υڡ������Ƥ����ɽ�����ޤ���</p>
# <pre>
# {{monthcalendar ������̾}}
# </pre>
# <p>
#   �ǥե���ȤǤ�����ΰ�����ɽ�����ޤ�����ǯ�����ꤹ�뤳�Ȥ�Ǥ��ޤ���
# </p>
# <pre>
# {{monthcalendar ������̾,ǯ,��}}
# </pre>
#
###################################################################
package plugin::calendar::MonthCalendar;
use strict;
use plugin::calendar::CalendarHandler;
#==================================================================
# ���󥹥ȥ饯��
#==================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==================================================================
# �ѥ饰���
#==================================================================
sub paragraph {
	my $self  = shift;
	my $wiki  = shift;
	my $name  = shift;
	my $year  = shift;
	my $month = shift;
	
	if ($name eq "") {
		return &Util::paragraph_error("������̾�����ꤵ��Ƥ��ޤ���","WIKI");
	}
	
	if(!defined($year) || !defined($month)){
		my ($sec, $min, $hour, $mday, $mon, $year2, $wday) = localtime(time());
		$year  = $year2 + 1900;
		$month = $mon + 1;
	}
	
	return plugin::calendar::CalendarHandler::make_month_pages($wiki,$year,$month,$name);
}

1;
