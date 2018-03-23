################################################################################
#
# Calendar�Υ��������ϥ�ɥ顣
#
################################################################################
package plugin::calendar::CalendarHandler;
use strict;
use HTTP::Status;
#===============================================================================
# ���󥹥ȥ饯��
#===============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===============================================================================
# �ڡ���̾�����
#===============================================================================
sub make_pagename {
	my $year  = shift;
	my $month = shift;
	my $day   = shift;
	my $name  = shift;
	
	return $name."/".$year."-".$month."-".$day;
}

#===============================================================================
# �����������
#===============================================================================
sub make_calendar {
	my $wiki     = shift;
	my $o_year   = shift;
	my $o_month  = shift;
	my $name     = shift;
	my $template = shift;
	my $id       = shift;

	return "���դ����ݡ����ϰϳ��Ǥ���" if($o_year >= 2030 || $o_year <= 1970);
	my $time = time();
	
	my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime($time);
	$year += 1900;
	$mon  += 1;
	my $today_year  = $year;
	my $today_month = $mon;
	my $today_day   = $mday;

	my $o_yearmon = sprintf("%04d%02d",$o_year,$o_month);

	while ($year!=$o_year || $mon!=$o_month) {
		my $yearmon = sprintf("%04d%02d",$year,$mon);
		if ($o_yearmon > $yearmon) {
			$time += 24 * 60 * 60;
		} else {
			$time -= 24 * 60 * 60;
		}
		
		($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime($time);
		$year += 1900;
		$mon  += 1;
	}

	($id ne "") and ($id = "id=\"$id\"");

	my $buf = "\n<div class=\"plugin-calendar\" $id>\n"
	         ."<table class=\"calendar\" summary=\"calendar\">\n";
	$buf .= "<tr><td class=\"image\" colspan=\"7\"></td></tr>\n";
	$buf .= "<tr>\n";
	$buf .= "  <td class=\"calendar-prev-month\" colspan=\"2\"><a href=\"".$wiki->create_url(&make_params($year,$mon,-1,$name,$template))."\">&lt;&lt;</a></td>\n";
	$buf .= "  <td class=\"calendar-current-month\" colspan=\"3\"><a href=\"".$wiki->create_url(&make_params($year,$mon, 0,$name,$template))."\">$o_year-$o_month</a></td>\n";
	$buf .= "  <td class=\"calendar-next-month\" colspan=\"2\"><a href=\"".$wiki->create_url(&make_params($year,$mon,+1,$name,$template))."\">&gt;&gt;</a></td>\n";
	$buf .= "</tr>\n";

	my @week = ("��","��","��","��","��","��","��");
	$buf .= "<tr>\n";
	foreach my $d (@week) {
		my $c = undef;
		if ($d eq "��") {
			$c = "sunday";
		} elsif ($d eq "��") {
			$c = "saturday";
		} else {
			$c = "weekday";
		}
		$buf .= "  <td class=\"calendar-$c\">$d</td>\n";
	}
	$buf .= "</tr>\n";

	my $time = $time - (($mday-1) * 24 * 60 * 60);
	my $now_month = $mon;

	my $start_flag = 1;
	while ($now_month==$mon) {
		($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime($time);
		$year += 1900;
		$mon  += 1;
		if ($mon!=$now_month) {
			last;
		}
		if ($start_flag) {
			$buf .= "<tr>\n";
			for (my $i=0;$i<$wday;$i++) {
				$buf .= "  <td class=\"calendar-day\"></td>\n";
			}
			$start_flag = 0;
		}
		my $page =&make_pagename($year,$mon,$mday,$name);
		# ͽ�꤬����� True��̵����С��⤷���ϵ��Ĥ�̵����� False��
		my $have_plan = ($wiki->page_exists($page) && $wiki->can_show($page));
		# �����Ǥ���� True������ʳ��� False��
		my $is_today = $year==$today_year && $mon==$today_month && $mday==$today_day;
		$buf .= "  <td class=\"calendar-day";

		# ��̣�Τ�������
		my @class = ();
		# ���դ�����
		$is_today and do { push @class, "today"; };
		# ͽ��Τ���
		$have_plan and do { push @class, "have"; };
 		if ($is_today || $have_plan) {
  			$buf .= " ".join(" ", @class);
 		}
		$buf .= "\">";
		
		my $param = {page=>$page};
		$param->{template} = $template if (not($have_plan) && defined($template));
		$buf .= "<a href=\"".$wiki->create_url($param)."\">$mday</a></td>\n";

		if ($wday==6) {
			$buf .= "</tr>\n";
			$start_flag = 1;
		}
		$time += 24 * 60 * 60;
	}

	if ($wday != 0) {
		# �ǽ��Ԥζ���Υ�������
		for (my $i = $wday; $i <= 6; $i++) {
			$buf .= "  <td class=\"calendar-day\"></td>\n";
		}
		$buf .= "</tr>\n";
	}
	
	return $buf."</table>\n</div>\n";
}

#===============================================================================
# ������󥫤Υѥ�᡼�������
#===============================================================================
sub make_params {
	my $year  = shift;
	my $month = shift;
	my $plus  = shift;
	my $name  = shift;
	my $template = shift;
	
	my $buf ={action=>'CALENDAR'};
	
	$month += $plus;
	if ($month==13) {
		$year += 1;
		$month = 1;
	} elsif ($month==0) {
		$year -= 1;
		$month = 12;
	}

	$buf->{year}     = $year;
	$buf->{month}    = $month;
	$buf->{name}     = $name;
	$buf->{template} = $template if defined $template;

	return $buf;
}

#===============================================================================
# ������ʬ
#===============================================================================
sub make_month_pages {
	my $wiki  = shift;
	my $year  = shift;
	my $month = shift;
	my $name  = shift;
	
	my $cgi = $wiki->get_CGI;
	my $page = $cgi->param("page");
	my $buf = "";

	for (my $i=31;$i>=1;$i--) {
		my $pagename = &make_pagename($year,$month,$i,$name);
		if ($wiki->page_exists($pagename) && $wiki->can_show($pagename)) {
			$buf .= "{{paragraph 3,[[$year-$month-$i|$pagename]]}}\n";
			$buf .= "{{include $pagename}}\n";
		}
	}
	return $buf;
}

#===============================================================================
# ���������κǿ�x���ɽ������
# RecentCalendar�����Ȥ��Τǥ᥽�åɤǤϤʤ��⥸�塼��ؿ��Ȥ��Ƽ���
#===============================================================================
sub make_recent_pages {
	my $wiki  = shift;
	my $name  = quotemeta(shift);
	my $count = shift;
	my $para  = shift;
	my $cgi   = $wiki->get_CGI;
	
	$count =~ m/\s*([-]?\d*)\s*([+]?)([-]?)/;
	my $reverse      = ($3   ?  1 : 0);
	my $count        = ($1+0 ? $1 : 1);
	my $ignore_today = ($2   ?  1 : 0);
	
	my @pages = $wiki->get_page_list;
	
	# ������̾/ǯ-��-���������Ф�
	@pages = grep(/^$name\/\d+-\d+-\d+$/,@pages);
	
	# ���������ս�˥�����
	@pages = sort {
		$a=~/^$name\/(\d+)-(\d+)-(\d+)$/;
		my $a_tmp = sprintf("%04d%02d%02d",$1,$2,$3);
		
		$b=~/^$name\/(\d+)-(\d+)-(\d+)$/;
		my $b_tmp = sprintf("%04d%02d%02d",$1,$2,$3);
		
		return $b_tmp<=>$a_tmp;
	} @pages ;
	
	if ( $reverse ) { # $reverse �����ʤ顢�ꥹ�Ȥ��ž
		@pages = reverse @pages;
	}
	
	# ̤��(���)�Τ�ΤϽ���
	my @pages2;
	my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime(time());
	my $today = sprintf("%04d%02d%02d",$year+1900,$mon+1,$mday);
	foreach (@pages) {
		$_=~/^$name\/(\d+)-(\d+)-(\d+)$/;
		my $tmp = sprintf("%04d%02d%02d",$1,$2,$3);
		if ( $reverse ) {
			if ($tmp >= ($today + ($ignore_today ? 1 : 0))) {
				push(@pages2,$_);
			}
		} else {
			if ($tmp <= ($today - ($ignore_today ? 1 : 0))) {
				push(@pages2,$_);
			}
		}
	}

	# calendar�ץ饰�����Ʊ�ͤ�ɽ��
	my $source = "";
	foreach my $page (@pages2) {
		$page =~ /((\d+)-(\d+)-(\d+))$/;
		if($wiki->can_show($page)){
			last if($count<=0);
			if ($para ne "") {
				$source .= "{{paragraph 3,[[$1|$page]]}}\n";
				$source .= "{{include $page,$para}}\n";
			} else {
				$source .= "{{paragraph 3,[[$1|$page]]}}\n";
				$source .= "{{include $page}}\n";
			}
			$count--;
		}
	}
	
	return $source;
}

#===============================================================================
# �����ʹߤκǶ�x���ɽ������
# FutureCalendar�����Ȥ��Τǥ᥽�åɤǤϤʤ��⥸�塼��ؿ��Ȥ��Ƽ���
#===============================================================================
sub make_future_pages {
	return &make_recent_pages(shift, shift, (shift)."-", shift);
}

#===============================================================================
# ���������ϥ�ɥ�᥽�å�
#===============================================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;

	my $name     = $cgi->param("name");
	my $year     = $cgi->param("year");
	my $month    = $cgi->param("month");
	my $template = $cgi->param("template");

	if (not $wiki->page_exists($template)) {
		undef $template;
	}

	if ($name eq "" || !Util::check_numeric($year) || !Util::check_numeric($month)) {
		return $wiki->error(RC_BAD_REQUEST, "�ѥ�᡼���������Ǥ���");

	} else {
		$wiki->set_title("$name/$year-$month");
		return &make_calendar($wiki,$year,$month,$name,$template).
		       $wiki->process_wiki(&make_month_pages($wiki,$year,$month,$name));
	}
}
1;
