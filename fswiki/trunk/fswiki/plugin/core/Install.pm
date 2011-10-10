############################################################
#
# FreeStyleWiki�δ���Ū�ʵ�ǽ���󶡤��ޤ���
#
############################################################
package plugin::core::Install;
use strict;

sub install {
	my $wiki  = shift;
	my $login = $wiki->get_login_info();
	
	$wiki->add_menu("�ȥå�",$wiki->create_page_url($wiki->config("frontpage")),999);
	
	if(&accept_edit($wiki)){
		$wiki->add_menu("����",$wiki->create_url({ action=>"NEW" }),998,1);
	}
	
	$wiki->add_menu("�Խ�"  ,"",997,1);
	if($wiki->{storage}->backup_type eq 'all'){
		$wiki->add_menu("����"  ,"",996,1);
	} else {
		$wiki->add_menu("��ʬ"  ,"",996,1);
	}
	$wiki->add_menu("����"  ,$wiki->create_url({ action=>"LIST" }),995);
	$wiki->add_menu("�إ��",$wiki->create_page_url("Help"),100);
	
	$wiki->add_handler("","plugin::core::ShowPage");
	$wiki->add_handler("NEW","plugin::core::NewPage");
	$wiki->add_handler("LIST","plugin::core::ListPage");
	
	$wiki->add_handler("EDIT","plugin::core::EditPage");
	$wiki->add_hook("show","plugin::core::EditPage");
	
	$wiki->add_handler("DIFF","plugin::core::Diff");
	$wiki->add_hook("show","plugin::core::Diff");
	
	$wiki->add_paragraph_plugin("include" ,"plugin::core::Include" ,"WIKI");
	$wiki->add_inline_plugin("edit","plugin::core::Edit","HTML");

	$wiki->add_hook("save_before","plugin::core::SpamFilter");
	$wiki->add_hook("save_after" ,"plugin::core::SendMail");
	$wiki->add_hook("delete"     ,"plugin::core::SendMail");
	
	$wiki->add_editform_plugin("plugin::core::Template",100);
	$wiki->add_editform_plugin("plugin::core::EditHelper",0);

	$wiki->add_menu("������","",700,1);
	$wiki->add_handler("SOURCE","plugin::core::Source");
	$wiki->add_hook("show","plugin::core::Source");
	
	$wiki->add_hook("save_after","plugin::core::KeywordCache");
	$wiki->add_hook("delete"    ,"plugin::core::KeywordCache");

	$wiki->add_paragraph_plugin("format_help","plugin::core::FormatHelp","WIKI");
	$wiki->add_paragraph_plugin("paragraph","plugin::core::Paragraph","WIKI");
	
	# Farm�ط��Υץ饰����򥤥󥹥ȡ���
	$wiki->add_admin_menu("WikiFarm������",$wiki->create_url({ action=>"ADMINFARM" }),950,
						  "WikiFarm��ư��˴ؤ��������Ԥ��ޤ���");
	$wiki->add_admin_handler("ADMINFARM","plugin::core::AdminFarmHandler");
	
	if($wiki->farm_is_enable()){
		$wiki->add_paragraph_plugin("wiki_list","plugin::core::WikiList","HTML");
		$wiki->add_handler("CREATE_WIKI","plugin::core::CreateWikiHandler");
		$wiki->add_handler("REMOVE_WIKI","plugin::core::RemoveWikiHandler");
		$wiki->add_menu("Farm",$wiki->create_url({ action=>"CREATE_WIKI" }),993);
	}
	
	$wiki->add_block_plugin("pre" ,"plugin::core::Pre" ,"HTML");
	$wiki->add_block_plugin("bq" ,"plugin::core::Blockquote" ,"HTML");
	$wiki->add_inline_plugin("raw" ,"plugin::core::Raw" ,"HTML");
}

sub accept_edit {
	my $wiki = shift;
	my $login = $wiki->get_login_info();
	
	if($wiki->config('accept_edit')==1){
		return 1;
	} elsif(defined($login)){
		if($wiki->config('accept_edit')==0){
			return 1;
		} elsif($wiki->config('accept_edit')==2 && $login->{'type'}==0){
			return 1;
		}
	}
	return 0;
}

1;
