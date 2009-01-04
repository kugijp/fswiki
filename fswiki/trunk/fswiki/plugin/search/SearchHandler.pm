############################################################
# 
# �����ե������ɽ�����ޤ���
# <pre>
# {{search}}
# </pre>
# �����ɥС���ɽ���������v���ץ�����Ĥ��Ƥ���������
# <pre>
# {{search v}}
# </pre>
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
	
	my $buf = "";
	
	$wiki->set_title("����");
	$buf .= "<form method=\"GET\" action=\"".$wiki->create_url()."\">\n".
	        "������� <input type=\"text\" name=\"word\" size=\"20\" value=\"".&Util::escapeHTML($word)."\"> ";
	
	$buf .= "<input type=\"radio\" name=\"t\" id=\"and\" value=\"and\"";
	$buf .= " checked" if($cgi->param("t") ne "or");
	$buf .= "><label for=\"and\">AND</label>\n";
	$buf .= "<input type=\"radio\" name=\"t\" id=\"or\" value=\"or\"";
	$buf .= " checked" if($cgi->param("t") eq "or");
	$buf .= "><label for=\"or\">OR</label>\n";
	$buf .= "<input type=\"checkbox\" id=\"contents\" name=\"c\" value=\"true\"";
	$buf .= " checked" if($cgi->param("c") eq "true");
	$buf .= "><label for=\"contents\">�ڡ������Ƥ�ޤ��</label>\n";
	
	$buf .=  "<input type=\"submit\" value=\" �� �� \">".
	         "<input type=\"hidden\" name=\"action\" value=\"SEARCH\">".
	         "</form>\n";
	
	#---------------------------------------------------------------------------
	# �����¹�
	if($word ne ""){
		my @list = $wiki->get_page_list({-permit=>'show'});
		my @words = split(/ +|��+/,$word);
		my $name;
		$buf = $buf."<ul>\n";
		foreach $name (@list){
			# �ڡ���̾�⸡���оݤˤ���
			my $page  = $name;
			if($cgi->param("c") eq "true"){
				$page .= "\n".$wiki->get_page($name);
			}
			my $page2 = ($word =~ /[A-Za-z]/) ? Jcode->new($page)->tr('a-z','A-Z') : undef;
			
			if($cgi->param("t") eq "or"){
				# OR���� -------------------------------------------------------
				foreach(@words){
					if($_ eq ""){ next; }
					my $index = (defined($page2)) ? index($page2, Jcode->new($_)->tr('a-z','A-Z')) : index($page,$_);
					if($index!=-1){
						$buf .= "<li>".
						        "<a href=\"".$wiki->create_page_url($name)."\">".Util::escapeHTML($name)."</a>".
						        " - ".
						        Util::escapeHTML(&get_match_content($wiki,$name,$page,$index)).
						        "</li>\n";
						last;
					}
				}
			} else {
				# AND���� ------------------------------------------------------
				my $flag = 1;
				my $index;
				foreach(@words){
					if($_ eq ""){ next; }
					$index = (defined($page2)) ? index($page2, Jcode->new($_)->tr('a-z','A-Z')) : index($page,$_);
					if($index==-1){
						$flag = 0;
						last;
					}
				}
				if($flag == 1){
					$buf .= "<li>".
					        "<a href=\"".$wiki->create_page_url($name)."\">".Util::escapeHTML($name)."</a>".
					        " - ".
					        Util::escapeHTML(&get_match_content($wiki,$name,$page,$index)).
					        "</li>\n";
				}
			}
		}
		$buf = $buf."</ul>\n";
	}
	return $buf;
}

#===========================================================
# �����˥ޥå������Ԥ���Ф��ؿ�
#===========================================================
sub get_match_content {
	my $wiki    = shift;
	my $name    = shift;
	my $content = shift;
	my $index   = shift;
	
	unless($wiki->can_show($name)){
		return "���ȸ��¤�����ޤ���";
	}
	my $pre  = substr($content,0,$index);
	my $post = substr($content,$index,length($content)-$index);
	
	my $pre_index  = rindex($pre,"\n");
	if($pre_index==-1){ $pre_index = 0; }
	
	my $post_index = index($post,"\n");
	if($post_index==-1){ $post_index = length($post); }
	$post_index += $index;
	
	return substr($content,$pre_index,$post_index-$pre_index);
}

1;
