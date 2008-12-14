############################################################
#
# ������ǽ���������̤��󶡤��ޤ���
#
############################################################
package plugin::admin::Install;
use strict;

sub install {
	my $wiki = shift;
	
	$wiki->add_menu("������",$wiki->create_url({action=>"LOGIN"}),0);
	$wiki->add_handler("LOGIN","plugin::admin::Login");
	
	$wiki->add_admin_menu("�Ķ�����"         ,$wiki->create_url({action=>"ADMINCONFIG"}),999,
						  "FSWiki���Τ�ư��˴ؤ��������Ԥ��ޤ���");
	
	$wiki->add_admin_menu("������������"     ,$wiki->create_url({action=>"ADMINSTYLE"}) ,998,
						  "���ɤ��˴ؤ��������Ԥ��ޤ���");
	
	$wiki->add_admin_menu("�桼������"       ,$wiki->create_url({action=>"ADMINUSER"})  ,997,
						  "�桼�����ɲá��ѹ��������Ԥ��ޤ���");

	$wiki->add_admin_menu("�ڡ�������"       ,$wiki->create_url({action=>"ADMINPAGE"})  ,996,
						  "�ڡ�������롢�����������¡��������Ԥ��ޤ���");
	
	$wiki->add_admin_menu("������줿�ڡ���" ,$wiki->create_url({action=>"ADMINDELETED"})  ,995,
						  "������줿�ڡ����γ�ǧ��������Ԥ��ޤ���");
	
	$wiki->add_admin_menu("�ץ饰��������"   ,$wiki->create_url({action=>"ADMINPLUGIN"}),994,
						  "�ץ饰�����ͭ������̵������Ԥ��ޤ���");

	$wiki->add_admin_menu("��������å���" ,$wiki->create_url({ action=>"ADMINLOG"})   ,992,
						  "���ե����롢����å���ե�����Υ�������ɤ�����Ԥ��ޤ���");

	$wiki->add_admin_menu("���ѥ��к�" ,$wiki->create_url({ action=>"ADMINSPAM" })   ,991,
						  "���ѥ��к��Ѥ������Ԥ��ޤ���");

	$wiki->add_user_menu("�ѥ���ɤ��ѹ�",$wiki->create_url({ action=>"ACCOUNT" }),500,
						 "��ʬ�Υѥ���ɤ��ѹ����ޤ���");
	
	$wiki->add_admin_handler("ADMINPAGE"   ,"plugin::admin::AdminPageHandler");
	$wiki->add_admin_handler("ADMINDELETED","plugin::admin::AdminDeletedPageHandler");
	$wiki->add_admin_handler("ADMINLOG"    ,"plugin::admin::AdminLogHandler");
	$wiki->add_admin_handler("ADMINCONFIG" ,"plugin::admin::AdminConfigHandler");
	$wiki->add_admin_handler("ADMINUSER"   ,"plugin::admin::AdminUserHandler");
	$wiki->add_admin_handler("ADMINPLUGIN" ,"plugin::admin::AdminPluginHandler");
	$wiki->add_admin_handler("ADMINSTYLE"  ,"plugin::admin::AdminStyleHandler");
	$wiki->add_admin_handler("ADMINSPAM"   ,"plugin::admin::AdminSpamHandler");
	
	$wiki->add_user_handler("ACCOUNT","plugin::admin::AccountHandler");
	
	$wiki->add_editform_plugin("plugin::admin::PermissionForm",101);
	$wiki->add_admin_handler("CHANGE_PAGE_PERMISSION","plugin::admin::PermissionForm");
	
	if($wiki->config("accept_user_register")){
		$wiki->add_handler("USERREGISTER","plugin::admin::UserRegisterHandler");
	}
	
	$wiki->add_hook("delete","plugin::admin::AdminDeletedPageHandler");
}

1;
