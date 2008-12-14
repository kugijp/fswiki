###############################################################################
#
# <p>bbs2�ץ饰���󤫤���Ƥ��줿�����ΰ�����ɽ�����ޤ���</p>
# <pre>
# {{bbs2list �Ǽ��Ĥ�̾��,ɽ�����}}
# </pre>
# <p>
#  ɽ��������ά�����10�鷺��ɽ������ޤ���
#  �ޤ������ץ����ǳƵ����Υ����ȥ�Τ�ɽ�����뤳�Ȥ䡢
#  �������ɽ�����뤳�Ȥ�Ǥ��ޤ���
# </p>
# <pre>
# {{bbs2list �Ǽ��Ĥ�̾��,ɽ�����,title}}
# </pre>
# <p>
#  ���ξ���ɽ��������ά���뤳�Ȥ��Ǥ��ޤ�����ά�����10�鷺��ɽ�����ޤ���
# </p>
# <pre>
# {{bbs2list �Ǽ��Ĥ�̾��,title}}
# </pre>
# <p>
#  recent�ϡ������򹹿����ɽ�����ޤ����ʥ���åɡ��ե��ȷ�����
#  title��recent�Ϥɤ������˻��ꤷ�Ƥ��ɤ��Ǥ���
#  ����2�ĤΥ��ץ����Ϥ��줾����Ω�˺��Ѥ��ޤ���
# </p>
# <pre>
# {{bbs2list �Ǽ��Ĥ�̾��,ɽ�����,recent,title}}
# {{bbs2list �Ǽ��Ĥ�̾��,title,recent}}
# </pre>
#
###############################################################################
package plugin::bbs::BBS2List;
use strict;
#==============================================================================
# ���󥹥ȥ饯��
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# �����ΰ��������
#==============================================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my $cgi    = $wiki->get_CGI();
	my $name   = shift;
	
	# �����Υ����å�
	if($name eq ""){
		return &Util::paragraph_error("�Ǽ��Ĥ�̾�������ꤵ��Ƥ��ޤ���");
	}
	
	# 2���ܤΰ������������ä����Ϥ����ɽ������ˤ��롣
	my $once = &Util::trim($_[0]);
	$once = &Util::check_numeric($once) ? $once : 10;
	
	# �Ĥ�Υ��ץ��������
	my %option;
	undef %option;
	$option{lc &Util::trim($_)} = 1 foreach @_;
	my $title  = exists $option{'title'}  ? 1 : 0;
	my $recent = exists $option{'recent'} ? 1 : 0;

	
	# �������������Wiki������ʸ������Ȥ�Ω�Ƥ�
	my $i    = 0;
	my $buf  = "";
	my $page = $cgi->param("page");
	my $cnt  = $cgi->param("cnt");
	if($cnt eq ""){ $cnt = 0; };
	
	my $ref_list = $self->_get_content_list($wiki,$name,$title,$recent);
	foreach my $item (@$ref_list){
		if($i >= $cnt*$once){
			if($title){
				$buf .= "*".$item->{name}."\n";
			} else {
				$buf .= "{{include ".$item->{name}."}}\n";
			}
		}
		$i++;
		last if($i/$once == $cnt+1);
	}
	
	# �ڡ��������ѤΥ�󥯤����
	$buf .= "\n[ ";
	my $pagecnt = 1;
	for($i=0;$i<=$#$ref_list;$i=$i+$once){
		if($cnt==$pagecnt-1){
			$buf .= $pagecnt." ";
		} else {
			$buf .= "[$pagecnt|".$wiki->create_url({page=>$page,cnt=>($pagecnt-1) })."] ";
		}
		$pagecnt++;
	}
	$buf .= "]\n";
	
	return $buf;
}

#==============================================================================
# �����ΰ��������
#==============================================================================
sub _get_content_list {
	my $self   = shift;
	my $wiki   = shift;
	my $name   = shift;
	my $title  = shift;
	my $recent = shift;
	my @list  = ();
	my $qname = quotemeta($name);
	
	foreach my $pagename ($wiki->get_page_list({-permit=>'show'})){
		if($pagename =~ /^BBS-$qname\/([0-9]+)$/){
			my $id = $1;
			if($title){
				my $content = $wiki->get_page($pagename);
				if($content =~ /^!!(.*)$/m){
					push(@list,{name=>$1,id=>$id});
				}
			} else {
				push(@list,{name=>$pagename,id=>$id});
			}
		}
	}
	
	if($recent){
		# �ƥ���åɤι������������
		foreach (@list) {
			$_->{last_modified} = $wiki->get_last_modified2("BBS-$name/$_->{id}");
		}
		# ���������ʿ����ˤ˥�����
		@list = sort { $b->{last_modified} <=> $a->{last_modified} } @list;
	} else {
		# recent�λ��꤬�ʤ��Ȥ���id�ʥ���å�Ω�Ƥ����֡ˤι߽�
		@list = sort { $b->{id} <=> $a->{id} } @list;
	}
	
	return \@list;
}

1;
