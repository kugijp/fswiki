##############################################################
#
# <p>ToDo�ꥹ�Ȥ�ɽ�����ޤ���</p>
# <p>
#   �ޤ�Ŭ���ʥڡ�����ToDo�򵭽Ҥ��ޤ���ToDo�ε��Ҥϰʲ��Τ褦�ʴ����Ǥ���
# </p>
# <pre>
# * 22(ͥ����) �ȥ���åȥڡ��ѡ����㤦(��ư)
# </pre>
# <p>
#   ͥ���٤ȹ�ư�δ֤϶�����İʾ�����Ƥ���������
#   �ץ饰����λȤ����ϰʲ��Τ褦�ˤʤ�ޤ���
# </p>
# <pre>
# {{todolist ToDo(ToDo�򵭽Ҥ����ڡ���),5(ɽ������������ά��)}}
# </pre>
# <p>
#   ͥ���٤ι⤤��˾夫��ɽ������ޤ���
#   always���ץ�����Ĥ���ȥ����å��ܥå����ȴ�λ�ܥ���ɽ�����졢
#   ToDo����λ����������å��ܥå����˥����å�������ơִ�λ�פ򲡤���
#   ToDo�򵭽Ҥ����ڡ����Ǥ�
# </p>
# <pre>
# * �� 22 �ȥ���åȥڡ��ѡ����㤦
# </pre>
# <p>
#   �Τ褦���ѹ�����todolist���鳰����ޤ���
#   �ʤ���always���ץ�����Ĥ��Ƥ��ʤ����Ǥ⡢
#   �����ԤȤ��ƥ����󤹤��Ʊ�ͤΥե����बɽ������ޤ���
# </p>
#
##############################################################
package plugin::todo::ToDoList;
use strict;
#=============================================================
# ���󥹥ȥ饯��
#=============================================================
sub new{
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#=============================================================
# �ѥ饰��ե᥽�å�
#=============================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my $source = shift;
	my $count  = shift;
	my $option = shift;
	if($count eq "always"){
		$option = "always";
	}
	my $cgi = $wiki->get_CGI;
	my $page = $cgi->param("page");
	my $buf = "";
	my @todolist=();
	
	if($source eq ""){
		return &Util::paragraph_error("�ڡ�������ꤷ�Ƥ���������");
	}
	unless($wiki->page_exists($source)){
		return &Util::paragraph_error("$source��¸�ߤ��ޤ���");
	}
	unless($wiki->can_show($source)){
		return &Util::paragraph_error("�ڡ����λ��ȸ�������ޤ���");
	}
	
	my $content = $wiki->get_page($source);
	my @lines = split(/\n/,$content);
	
	# �񼰤���todo�����
	foreach(@lines){
		if($_ =~ /^\*\s*(\d+)\s+(.*)/){
			my $priority = $1;
			my $dothing  = $2;
			my $todo = {priority => $priority,dothing => $dothing};
			push(@todolist,$todo);
		}
	}
	
	# ͥ���̤ǥ�����
	@todolist = sort {
		return $b->{priority} <=> $a->{priority};
	} @todolist;
	
	# �ꥹ��ɽ�� + ��λ�ե�����
	my $login = $wiki->get_login_info();
	if($option eq "always" || defined($login)){
		$buf .= "<div class=\"todo\">"
		    ."<form action=\"".$wiki->create_url()."\" method=\"POST\">\n"
		    ."<input type=\"hidden\" name=\"source\" value=\"".Util::escapeHTML($source)."\">\n"
		    ."<input type=\"hidden\" name=\"page\" value=\"".Util::escapeHTML($page)."\">\n"
		    ."<input type=\"hidden\" name=\"action\" value=\"FINISH_TODO\">";
	}
	$buf .= "<ol>\n";
	my $i=0;
	foreach (@todolist){
		my $priority = $_->{priority};
		my $dothing  = $_->{dothing};
		my $value    = Util::escapeHTML($dothing);
		my $content  = $wiki->process_wiki($dothing);
		$content =~ s/<\/?p>//g;
		$buf .= "<li value=\"$priority\">";
		if($option eq "always" || defined($login)){
			$buf .= "<input name=\"todo.$i\" type=\"checkbox\" value=\"$value\">"
			        .$content."</input></li>\n";
		} else {
			$buf .= $content."</li>\n";
		}
		$i++;
		last if($i==$count);
	}
	
	$buf .= "</ol>";
	if($option eq "always" || defined($login)){
		$buf .= "<input type=\"submit\" value=\"��λ\"></form></div>";
	}
	return $buf;
}

1;
