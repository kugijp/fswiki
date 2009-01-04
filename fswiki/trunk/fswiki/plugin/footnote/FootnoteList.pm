#########################################################################
#
# <p>����ꥹ�ȥץ饰����Ǥ���</p>
# <pre>
# {{footnote_list}}
# </pre>
# <p>����ץ饰������ߤ���줿����ʸ���ꥹ��ɽ�����ޤ���</p>
#
#########################################################################
package plugin::footnote::FootnoteList;
use strict;
#========================================================================
# ���󥹥ȥ饯��
#========================================================================
sub new {
	my $class = shift;
	my $self = {};
	$self->{notes} = [];

	return bless $self,$class;
}

#========================================================================
# �ѥ饰��ե᥽�å�
#========================================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $buf  = "";

    if(@{$self->{notes}} > 0 ){
		$buf .= "<ul class=\"fnlist\">";
		while(my $note = shift(@{$self->{notes}})){
			my $index = $note->{id};
			my $text = $note->{text};
			$buf .= "<li>[<a id=\"FN_$index\" name=\"FN_$index\" href=\"#FNR_$index\">$index</a>]".
			        &Util::escapeHTML($text)."</li>";
		}
		$buf .= "</ul>";
	}
	return $buf;
}
#========================================================================
# �եå� "footnote"����ƤФ�ޤ���
#========================================================================
sub hook{
	my $self = shift;
	my $wiki = shift;
	my $name = shift;
	my $note = shift;
	push(@{$self->{notes}},$note);
}
1;
