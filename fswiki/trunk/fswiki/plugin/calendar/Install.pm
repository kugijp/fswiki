################################################################################
#
# ��������ɽ�������դ��Ȥ˥ڡ����������ɽ�����뤿��Υץ饰������󶡤��ޤ���
#
################################################################################
package plugin::calendar::Install;
use strict;
sub install {
	my $wiki = shift;
	$wiki->add_handler("CALENDAR","plugin::calendar::CalendarHandler");
	$wiki->add_paragraph_plugin("calendar"       ,"plugin::calendar::Calendar","HTML");
	$wiki->add_paragraph_plugin("recentcalendar" ,"plugin::calendar::RecentCalendar","WIKI");
	$wiki->add_paragraph_plugin("futurecalendar" ,"plugin::calendar::FutureCalendar","WIKI");
	$wiki->add_paragraph_plugin("monthcalendar"  ,"plugin::calendar::MonthCalendar","WIKI");
}

1;
