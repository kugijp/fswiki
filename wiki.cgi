#!/usr/bin/perl
###############################################################################
#
# FreeStyleWiki �ե��ȥ����CGI������ץ�
#
###############################################################################
BEGIN {
	if(exists $ENV{MOD_PERL}){
		# �����ȥǥ��쥯�ȥ���ѹ�
		chdir($ENV{FSWIKI_HOME});
	}
}
# ModPerl::Registry(Prefork)�Ǥϼ¹Ի����ѹ�����Ƥ����ǽ��������
if(exists $ENV{MOD_PERL}){
	chdir($ENV{FSWIKI_HOME});
}

#==============================================================================
# �⥸�塼��Υ��󥯥롼��
#==============================================================================
use Cwd;
use lib './lib';
# ModPerl::Registry(Prefork)�Ǥ�@INC�����������Ƥ����礬����
unshift @INC, './lib' if(exists $ENV{MOD_PERL});
use strict;
#use CGI::Carp qw(fatalsToBrowser);
#use CGI2;
use Wiki;
use Util;
use Jcode;
use HTML::Template;

# �������ʤ���Apache::Registory��ư���ʤ�
if(exists $ENV{MOD_PERL}){
	eval("use Digest::Perl::MD5;");
	eval("use plugin::core::Diff;");
	eval("use plugin::pdf::PDFMaker;");
	&Jcode::load_module("Jcode::Unicode") unless $Jcode::USE_ENCODE;
}

#==============================================================================
# CGI��Wiki�Υ��󥹥��󥹲�
#==============================================================================
my $wiki = Wiki->new('setup.dat');
my $cgi = $wiki->get_CGI();

Util::override_die();
eval {
	# Session�ѥǥ��쥯�ȥ��Farm�Ǥⶦ�̤˻��Ѥ���
	$wiki->config('session_dir',$wiki->config('log_dir'));
	
	#==============================================================================
	# Farm�Ȥ���ư�����
	#==============================================================================
	my $path_info  = $cgi->path_info();
	my $path_count = 0;
	if(length($path_info) > 0){
		# Farm�����뤫��ǧ����
		unless($path_info =~ m<^(/[A-Za-z0-9]+)*/?$> and -d $wiki->config('data_dir').$path_info){
			CORE::die("Wiki��¸�ߤ��ޤ���");
		}
		
		# PATH_INFO�κǸ夬/���ä���/�ʤ���URL��ž������
		if($path_info =~ m|/$|) {
			$path_info =~ s|/$||;
			$wiki->redirectURL($cgi->url().$path_info);
		}
		$path_info =~ m</([^/]+)$>;
		$wiki->config('script_name', $1);
		$wiki->config('data_dir'   , $wiki->config('data_dir'  ).$path_info);
		$wiki->config('config_dir' , $wiki->config('config_dir').$path_info);
		$wiki->config('backup_dir' , $wiki->config('backup_dir').$path_info);
		$wiki->config('log_dir'    , $wiki->config('log_dir'   ).$path_info);

		if(!($wiki->config('theme_uri') =~ /^(\/|http:|https:|ftp:)/)){
			my @paths = split(/\//,$path_info);
			$path_count = $#paths;
			for(my $i=0;$i<$path_count;$i++){
				$wiki->config('theme_uri','../'.$wiki->config('theme_uri'));
			}
		}
	}

	#==============================================================================
	# �����ȿ�ǡʤ⤦����äȥ��ޡ��Ȥˤ�ꤿ���͡�
	#==============================================================================
	my $config = &Util::load_config_hash($wiki,$wiki->config('config_file'));
	foreach my $key (keys(%$config)){
		$wiki->config($key,$config->{$key});
	}
	# ���̤����꤬ɬ�פʤ�Τ������
	$wiki->config('css',
		$wiki->config('theme_uri')."/".$config->{theme}."/".$config->{theme}.".css");
	$wiki->config('site_tmpl',
		$wiki->config('tmpl_dir')."/site/".$config->{site_tmpl_theme}."/".$config->{site_tmpl_theme}.".tmpl");
	$wiki->config('site_handyphone_tmpl',
		$wiki->config('tmpl_dir')."/site/".$config->{site_tmpl_theme}."/".$config->{site_tmpl_theme}."_handyphone.tmpl");

	#==============================================================================
	# �����ॢ���Ȥ��Ƥ��륻�å������˴�
	#==============================================================================
	$cgi->remove_session($wiki);

	#==============================================================================
	# �桼��������ɤ߹���
	#==============================================================================
	my $users = &Util::load_config_hash($wiki,$wiki->config('userdat_file'));
	foreach my $id (keys(%$users)){
		my ($pass,$type) = split(/\t/,$users->{$id});
		$wiki->add_user($id,$pass,$type);
	}

	#==============================================================================
	# �ץ饰����Υ��󥹥ȡ���Ƚ����
	#==============================================================================
	my @plugins = split(/\n/,&Util::load_config_text($wiki,$wiki->config('plugin_file')));
	my $plugin_error = '';
	foreach(sort(@plugins)){
		$plugin_error .= $wiki->install_plugin($_);
	}
	# �ץ饰���󤴤Ȥν����������ư
	$wiki->do_hook("initialize");

	#==============================================================================
	# ���������ϥ�ɥ�θƤӽФ�
	#==============================================================================
	my $action  = $cgi->param("action");
	my $content = $wiki->call_handler($action);

	# �ץ饰����Υ��󥹥ȡ���˼��Ԥ������
	$content = $plugin_error . $content if $plugin_error ne '';

	#==============================================================================
	# �쥹�ݥ�
	#==============================================================================
	my $output        = "";
	my $is_handyphone = &Util::handyphone();
	my $is_smartphone = &Util::smartphone();
	my $template_name = "";

	if ($is_handyphone || $is_smartphone) {
		$template_name = 'site_handyphone_tmpl';
	} else {
		$template_name = 'site_tmpl';
	}

	# �ȥåץڡ������ɤ�����Ƚ��
	my $top  = 0;
	if($cgi->param("page") eq $wiki->config("frontpage")){
		$top = 1;
	}

	# �ڡ����Υ����ȥ�����
	my $title = "";
	if($cgi->param('action') eq "" && $wiki->page_exists($cgi->param('page')) && $wiki->is_installed('search')){
		$title = "<a href=\"".$wiki->create_url({action=>"SEARCH",word=>$wiki->get_title()})."\">".
		       &Util::escapeHTML($wiki->get_title())."</a>";
	} else {
		$title = &Util::escapeHTML($wiki->get_title());
	}

	#------------------------------------------------------------------------------
	# �إå�������
	#------------------------------------------------------------------------------
	my $header_tmpl = HTML::Template->new(filename => $wiki->config('tmpl_dir')."/header.tmpl",
	                                      die_on_bad_params => 0,
	                                      case_sensitive    => 1);
	# ��˥塼�����
	my @menu = ();
	foreach(sort {$b->{weight}<=>$a->{weight}} @{$wiki->{menu}}){
		if($_->{href} ne ""){
			push(@menu,$_);
		}
	}
	$header_tmpl->param(MENU       => \@menu,
	                    FRONT_PAGE => $top);
	my $header = $header_tmpl->output();

	#------------------------------------------------------------------------------
	# �եå�������
	#------------------------------------------------------------------------------
	my $footer_tmpl = HTML::Template->new(filename => $wiki->config('tmpl_dir')."/footer.tmpl",
	                                      die_on_bad_params => 0,
	                                      case_sensitive    => 1);

	# ���ԡ��饤�Ȥ�ɽ�����뤫�ɤ���
	my $admin_name = $wiki->config('admin_name');
	my $admin_mail = $wiki->config('admin_mail_pub');
	my $out_copyright  = 1;
	if($admin_name eq ""){ $admin_name = $admin_mail; }
	if($admin_name eq "" && $admin_mail eq ""){ $out_copyright = 0; }

	$footer_tmpl->param(ADMIN_NAME    => $admin_name,
	                    ADMIN_MAIL    => $admin_mail,
	                    OUT_COPYRIGHT => $out_copyright,
	                    FRONT_PAGE    => $top,
	                    VERSION       => Wiki->VERSION,
	                    PERL_VERSION  => $]);

	if(exists $ENV{MOD_PERL}){
		$footer_tmpl->param(MOD_PERL=>$ENV{MOD_PERL});
	}

	my $footer = $footer_tmpl->output();

	#------------------------------------------------------------------------------
	# �����ȥƥ�ץ졼�Ȥν���
	#------------------------------------------------------------------------------
	# �ƥ�ץ졼�Ȥ��ɤ߹���
	my $template = HTML::Template->new(filename => $wiki->config($template_name),
	                                   die_on_bad_params => 0,
	                                   case_sensitive    => 1);

	# ���ȸ��¤����뤫�ɤ���
	my $can_show = 0;
	if($action ne '' || ($action eq '' && $wiki->can_show($cgi->param('page')))){
		$can_show = 1;
	}

	# head�������ɽ�������������
	my $head_info = "";
	foreach (@{$wiki->{'head_info'}}){
		$head_info .= $_."\n";
	}

	# �ƥ�ץ졼�Ȥ˥ѥ�᡼���򥻥å�
	$template->param(SITE_TITLE  => &Util::escapeHTML($wiki->get_title()." - ".$wiki->config('site_title')),
	                 MENU        => $header,
	                 TITLE       => $title,
	                 CONTENT     => $content,
	                 FRONT_PAGE  => $top,
	                 FOOTER      => $footer,
	                 EDIT_MODE   => $action,
	                 CAN_SHOW    => $can_show,
	                 HEAD_INFO   => $head_info,
	                 SITE_NAME   => $wiki->config('site_title'));

	my $login = $wiki->get_login_info();
	$template->param(
		IS_ADMIN => defined($login) && $login->{type}==0,
		IS_LOGIN => defined($login)
	);

	if ($is_handyphone || $is_smartphone) {
		# ���������ѽ���
		$output = $template->output;
		&Jcode::convert(\$output,"sjis");
	} else {
		# �ѥ������ѽ���
		my $usercss = &Util::load_config_text($wiki,$wiki->config('usercss_file'));
		
		if($config->{'theme'} eq ''){
			# �ơ��ޤ����Ѥ���Ƥ��餺������CSS�����ꤵ��Ƥ�����Ϥ�������
			if($config->{'outer_css'} ne ''){
				$wiki->config('css',$config->{'outer_css'});
			# �ơ��ޤ⳰��CSS����ꤵ��Ƥ��ʤ����ϥ������륷���Ȥ���Ѥ��ʤ�
			} else {
				$wiki->config('css','');
			}
		}
		# �ѥ�᡼���򥻥å�
		$template->param(HAVE_USER_CSS => $usercss ne "",
		                 THEME_CSS     => $wiki->config('css'),
		                 USER_CSS      => &Util::escapeHTML($usercss),
		                 THEME_URI     => $wiki->config('theme_uri'));
		
		# �ڡ���̾��EXIST_PAGE_�ڡ���̾�Ȥ����ѥ�᡼���˥��å�
		# ������������å����ޤ�ڡ���̾�ϥ��åȤ��ʤ�
		my @pagelist = $wiki->get_page_list();
		foreach my $page (@pagelist){
			if(index($page,"/")==-1 && $wiki->can_show($page)){
				$template->param("EXIST_PAGE_".$page=>1);
			}
		}
		
		$output = $template->output;
		
		# ���󥯥롼��̿��
		# <!--FSWIKI_INCLUDE PAGE="�ڡ���̾"-->
		# �ڡ���̾��WikiName����ꤹ�롣
		my $fswiki_include_tag = '<!--\s*FSWIKI_INCLUDE\s+PAGE\s*=\s*"([^"]*)"\s*-->';
		while($output =~ /$fswiki_include_tag/o){
			if($wiki->page_exists($1) && $wiki->can_show($1)){
				$output =~ s/$fswiki_include_tag/$wiki->process_wiki($wiki->get_page($1))/oe;
			} else {
				$output =~ s/$fswiki_include_tag//o;
			}
		}
	}
	
	#------------------------------------------------------------------------------
	# ���Ͻ���
	#------------------------------------------------------------------------------
	# �إå��ν���
	if($is_handyphone){
		print "Content-Type: text/html;charset=Shift_JIS\n";
	} else {
		print "Content-Type: text/html;charset=EUC-JP\n";
	}
	print "Pragma: no-cache\n";
	print "Cache-Control: no-cache\n\n";
	 
	# HTML�ν���
	print $output;
};

my $msg = $@;
$ENV{'PATH_INFO'} = undef;
$wiki->_process_before_exit();

if($msg && index($msg, 'safe_die')<0){
	$msg = Util::escapeHTML($msg);
	print "Content-Type: text/html\n\n";
	print "<html><head><title>Software Error</title></head>";
	print "<body><h1>Software Error:</h1><p>$msg</p></body></html>";
}
Util::restore_die();
