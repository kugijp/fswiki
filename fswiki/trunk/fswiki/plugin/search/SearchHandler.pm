############################################################
#
# ������¹Ԥ��Ʒ�̤�ɽ�����륢�������ץ饰����
# BugTrack-plugin/396
# 2009-01-09 ��
#
############################################################
package plugin::search::SearchHandler;
use strict;
#===========================================================
# ���󥹥ȥ饯��
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# ���������μ¹�
#===========================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi = $wiki->get_CGI;
	my $word = Util::trim($cgi->param("word"));

	my $buf          = "";
	my $or_search    = $cgi->param('t') eq 'or';
	my $with_content = $cgi->param('c') eq 'true';

	$wiki->set_title("����");
	$buf .= "<form method=\"GET\" action=\"".$wiki->create_url()."\">\n".
	        "������� <input type=\"text\" name=\"word\" size=\"20\" value=\"".&Util::escapeHTML($word)."\"> ";

	$buf .= "<input type=\"radio\" name=\"t\" id=\"and\" value=\"and\"";
	$buf .= " checked" if (not $or_search);
	$buf .= "><label for=\"and\">AND</label>\n";
	$buf .= "<input type=\"radio\" name=\"t\" id=\"or\" value=\"or\"";
	$buf .= " checked" if ($or_search);
	$buf .= "><label for=\"or\">OR</label>\n";
	$buf .= "<input type=\"checkbox\" id=\"contents\" name=\"c\" value=\"true\"";
	$buf .= " checked" if ($with_content);
	$buf .= "><label for=\"contents\">�ڡ������Ƥ�ޤ��</label>\n";

	$buf .=  "<input type=\"submit\" value=\" �� �� \">".
	         "<input type=\"hidden\" name=\"action\" value=\"SEARCH\">".
	         "</form>\n";

	my $ignore_case = 1;
	my $conv_upper_case = ($ignore_case and $word =~ /[A-Za-z]/);
	$word = uc $word if ($conv_upper_case);
	my @words = grep { $_ ne '' } split(/ +|��+/, $word);
	return $buf unless (@words);
	#---------------------------------------------------------------------------
	# �����¹�
	my @list = $wiki->get_page_list({-permit=>'show'});
	my $res = '';
	PAGE:
	foreach my $name (@list){
		# �ڡ���̾�⸡���оݤˤ���
		my $page = $name;
		$page .= "\n".$wiki->get_page($name) if ($with_content);
		my $pageref = ($conv_upper_case) ? \(my $page2 = uc $page) : \$page;
		my $index;

		if ($or_search) {
			# OR���� -------------------------------------------------------
			WORD:
			foreach(@words){
				next WORD if (($index = index $$pageref, $_) == -1);
				$res .= "<li>".
					    "<a href=\"".$wiki->create_page_url($name)."\">".Util::escapeHTML($name)."</a>".
						" - ".
						Util::escapeHTML(&get_match_content($wiki, $page, $index)).
						"</li>\n";
				next PAGE;
			}
		} else {
			# AND���� ------------------------------------------------------
			WORD:
			foreach(@words){
				next PAGE if (($index = index $$pageref, $_) == -1);
			}
			$res .= "<li>".
					"<a href=\"".$wiki->create_page_url($name)."\">".Util::escapeHTML($name)."</a>".
					" - ".
					Util::escapeHTML(&get_match_content($wiki, $page, $index)).
					"</li>\n";
		}
	}
	return "$buf<ul>\n$res</ul>\n" if ($res ne '');
	return $buf;
}

#===========================================================
# �����˥ޥå������Ԥ���Ф��ؿ�
#===========================================================
sub get_match_content {
	my $wiki    = shift;
	my $content = shift;
	my $index   = shift;

	# �����˥ޥå������Ԥ���Ƭʸ���ΰ��֤���롣
	# ��$content �� $index ���ܤ�ʸ��������Ƭ�����˲���ʸ����õ����
	# ��$index �ΰ��֤�ޤ�Ԥ���Ƭʸ���ΰ��֤ϲ���ʸ���μ��ʤΤ� +1 ���롣
	# ����Ƭ�����˲���ʸ����̵���ä���ǽ�ιԤʤΤǡ���̤� 0(��Ƭ)��
	#   (���Ĥ���ʤ��� rindex() = -1 �ˤʤ�Τǡ�+1 ���Ƥ��礦�� 0)
	my $pre_index = rindex($content, "\n", $index) + 1;

	# �����˥ޥå������Ԥ�����ʸ���ΰ��֤���롣
	# ��$content �� $index ���ܤ�ʸ���������������˲���ʸ����õ����
	my $post_index = index($content, "\n", $index);

	# ���������˲���ʸ�����ʤ��ä���ǽ��ԤʤΤ� $pre_index �ʹ����Ƥ��ֵѡ�
	return substr($content, $pre_index) if ($post_index == -1);

	# ���Ĥ��ä�����ʸ���˶��ޤ줿ʸ������ֵѡ�
	return substr($content, $pre_index, $post_index - $pre_index);
}

1;
