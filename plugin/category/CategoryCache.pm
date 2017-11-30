################################################################################
#
# ���ƥ���Υ���å����Ԥ��եå���
# save_after�եå��ǵ�ư����ޤ���
#
################################################################################
package plugin::category::CategoryCache;
use strict;
use plugin::category::CategoryHandler;
#===============================================================================
# ���󥹥ȥ饯��
#===============================================================================
sub new {
	my $class = shift;
	my $self  = {};
	return bless $self,$class;
}
#===============================================================================
# ����å���򹹿����⤷���Ϻ���
#===============================================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $name = shift;
	my $cgi  = $wiki->get_CGI();
	
	my $pagename = $cgi->param('page');
	my $cachefile = $wiki->config('log_dir')."/category.cache";
	
	if(-e $cachefile){
		my $hash = &Util::load_config_hash(undef,$cachefile);
		&update_cache($wiki,$hash,$pagename);
		&Util::save_config_hash(undef,$cachefile,$hash);
	} else {
		&create_cache($wiki);
	}
}

#==============================================================================
# ���ƥ��ꥭ��å�����������ؿ�
#==============================================================================
sub create_cache {
	my $wiki = shift;
	my $hash = {};
	my @pages = $wiki->get_page_list();
	foreach my $page (@pages){
		&update_cache($wiki,$hash,$page);
	}
	&Util::save_config_hash(undef,$wiki->config('log_dir')."/category.cache",$hash);
}

#==============================================================================
# ���ƥ��ꥭ��å���򥢥åץǡ��Ȥ���ؿ�
#==============================================================================
sub update_cache {
	my $wiki     = shift;
	my $hash     = shift;
	my $pagename = shift;
	
	if($pagename =~ /^Template\//){
		return;
	}
	
	my $pageptn  = quotemeta($pagename);
	
	# ����å��夫��ڡ������ö���
	foreach my $category (keys(%$hash)){
		$hash->{$category} =~ s/(^|\t)$pageptn(\t|$)/$2/g;
		# ���ڡ�����¸�ߤ��ʤ����ƥ������
		if($hash->{$category} eq ""){
			delete($hash->{$category});
		}
	}
	
	# �ڡ����˵��Ҥ���Ƥ��륫�ƥ�������
	my $content  = $wiki->get_page($pagename);
	my @categories = &get_page_category($wiki,$content);
	
	# �ڡ����򥭥�å�����ɲ�
	foreach my $category (@categories){
		my @pages = split(/\t/,$hash->{$category});
		my $flag = 0;
		foreach my $page (@pages){
			if($page eq $pagename){
				$flag = 1;
				last;
			}
		}
		if($flag==0){
			$hash->{$category} = $hash->{$category}."\t$pagename";
		}
	}
	return $hash;
}

#==============================================================================
# �ڡ�����Υ��ƥ������Ф���ؿ�
#==============================================================================
sub get_page_category {
	my $wiki   = shift;
	my $source = shift;
	my @category;
	foreach my $line (split(/\n/,$source)){
		if(index($line," ")!=0 && index($line,"\t")!=0 && index($line,"//")!=0){
			while($line =~ /\{\{(category\s+(.+?)\s*\}\})/g){
				my $inline = $wiki->parse_inline_plugin($1);
				if(@{$inline->{args}} > 1 and $inline->{args}->[-1] eq 'nolink'){
					pop @{$inline->{args}};
				}
				foreach my $arg (@{$inline->{args}}) {
					push(@category,$arg);
				}
			}
		}
	}
	return @category;
}

1;
