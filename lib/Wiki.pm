###############################################################################
# <p>
# Wiki API
# </p>
###############################################################################
package Wiki;
use strict;
use CGI2;
use File::Copy;
use File::Path;
use Wiki::DefaultStorage;
use Wiki::HTMLParser;
use vars qw($VERSION $DEBUG);
$VERSION = '3.6.4';
$DEBUG   = 0;
#==============================================================================
# <p>
#   ���󥹥ȥ饯��
# </p>
#==============================================================================
sub new {
	my $class = shift;
	my $self  = {};
	
	# ������ɤ߹���
	my $setupfile = shift || 'setup.dat';
	$self->{"config"} = &Util::load_config_hash(undef,$setupfile);
	die "setup file ${setupfile} not found" if (keys %{$self->{"config"}} == 0);
	$self->{"config"}->{"plugin_dir"} = "."         unless exists($self->{"config"}->{"plugin_dir"});
	$self->{"config"}->{"frontpage"}  = "FrontPage" unless exists($self->{"config"}->{"frontpage"});
	unshift(@INC, $self->{"config"}->{"plugin_dir"});
	$ENV{'TZ'} = $self->{"config"}->{"time_zone"};
	$CGI::POST_MAX = $self->{"config"}->{"post_max"} if $self->{"config"}->{"post_max"} ne '';
	
	# ���󥹥����ѿ�������
	$self->{"handler"}            = {};
	$self->{"handler_permission"} = {};
	$self->{"plugin"}             = {};
	$self->{"title"}              = "";
	$self->{"menu"}               = [];
	$self->{"CGI"}                = CGI2->new();
	$self->{"hook"}               = {};
	$self->{"user"}               = ();
	$self->{"admin_menu"}         = ();
	$self->{"editform"}           = ();
	$self->{"edit"}               = 0;
	$self->{"parse_times"}        = 0;
	$self->{"format"}             = {};
	$self->{"installed_plugin"}   = ();
	$self->{"head_info"}          = ();
	
	# ���ȥ졼���Υ��󥹥��󥹤�����
	if($self->{config}->{"storage"} eq ""){
		$self->{"storage"} = Wiki::DefaultStorage->new($self);
	} else {
		eval ("use ".$self->{config}->{"storage"}.";");
		$self->{"storage"} = $self->{config}->{"storage"}->new($self);
	}
	
	return bless $self,$class;
}

###############################################################################
#
# �桼���ط��Υ᥽�åɷ�
#
###############################################################################
#==============================================================================
# <p>
#   �桼�����ɲä��ޤ�
# </p>
# <pre>
# $wiki-&gt;add_user(ID,�ѥ����,�桼��������);
# </pre>
# <p>
# �桼�������פˤϴ����ԥ桼���ξ��0�����̥桼���ξ��1����ꤷ�ޤ���
# �ʤ������Υ᥽�åɤϼ¹Ի���Wiki.pm�˥桼�����ɲä��뤿��Τ�Τǡ�
# ���Υ᥽�åɤ��Ф��ƥ桼�����ɲä��Ƥ��³���ϹԤ��ޤ���
# </p>
#==============================================================================
sub add_user {
	my $self = shift;
	my $id   = shift;
	my $pass = shift;
	my $type = shift;

	push(@{$self->{"user"}},{id=>$id,pass=>$pass,type=>$type});
}

#==============================================================================
# <p>
#   �桼����¸�ߤ��뤫�ɤ������ǧ���ޤ�
# </p>
#==============================================================================
sub user_exists {
	my $self = shift;
	my $id   = shift;
	foreach my $user (@{$self->{"user"}}){
		if($user->{id} eq $id){
			return 1;
		}
	}
	return 0;
}

#==============================================================================
# <p>
#   ����������������ޤ���
#   �����󤷤Ƥ�����ϥ���������ޤ���ϥå����ե���󥹤�
#   �����󤷤Ƥ��ʤ�����undef���֤��ޤ���
# </p>
# <pre>
# my $info = $wiki-&gt;get_login_info();
# if(defined($info)){          # �����󤷤Ƥ��ʤ�����undef
#   my $id   = $info-&gt;{id};    # ������桼����ID
#   my $type = $info-&gt;{type};  # ������桼���μ���(0:������ 1:����)
# }
# </pre>
#==============================================================================
sub get_login_info {
	my $self = shift;
	if (exists($self->{'login_info'})){
		return $self->{'login_info'};
	}

	my $cgi = $self->get_CGI();
	return undef unless(defined($cgi));
	
	my $session = $cgi->get_session($self);
	unless(defined($session)){
		$self->{'login_info'} = undef;
		return undef;
	}
	my $id   = $session->param("wiki_id");
	my $type = $session->param("wiki_type");
	my $path = $session->param("wiki_path");

	# PATH_INFO��Ĵ�٤�
	my $path_info = $cgi->path_info();
	if(!defined($path_info)){ $path_info  = ""; }
	if(!defined($path     )){ $path       = ""; }
	if(!defined($id       )){ $id         = ""; }
	if(!defined($type     )){ $type       = ""; }
	
	if($path_info eq "" && $path ne ""){
		$self->{'login_info'} = undef;
		return undef;
	} elsif($path ne "" && !($path_info =~ /^$path($|\/)/)){
		$self->{'login_info'} = undef;
		return undef;
	}
	
	# ���å��������åȤ���Ƥ��ʤ�
	if($id eq "" ||  $type eq ""){
		$self->{'login_info'} = undef;
		return undef;
	}
	
	# �桼��������ֵ�
	$self->{'login_info'} = {id=>$id,type=>$type,path=>$path};
	return $self->{'login_info'};
}

#==============================================================================
# <p>
#   ����������å���Ԥ��ޤ���
# </p>
#==============================================================================
sub login_check {
	my $self = shift;
	my $id   = shift;
	my $pass = shift;
	my $path = $self->get_CGI()->path_info();
	foreach(@{$self->{"user"}}){
		if($_->{id} eq $id && $_->{pass} eq $pass){
			return {id=>$id,pass=>$pass,type=>$_->{type},path=>$path};
		}
	}
	return undef;
}

###############################################################################
#
# �ץ饰����ط��Υ᥽�åɷ�
#
###############################################################################
#==============================================================================
# <p>
#   ���ǥ��åȥե�����ץ饰������ɲä��ޤ�
# </p>
# <pre>
# $wiki-&gt;add_editform_plugin(���ǥ��åȥե�����ץ饰����Υ��饹̾,ͥ����);
# </pre>
# <p>
# ͥ���٤��礭���ۤɾ�̤�ɽ������ޤ���
# </p>
#==============================================================================
sub add_editform_plugin {
	my $self   = shift;
	my $plugin = shift;
	my $weight = shift;
	push(@{$self->{"editform"}},{class=>$plugin,weight=>$weight});
}

#==============================================================================
# <p>
#   �Խ��ե������ѤΥץ饰����ν��Ϥ�������ޤ�
# </p>
#==============================================================================
sub get_editform_plugin {
	my $self = shift;
	my $buf = "";
	foreach my $plugin (sort { $b->{weight}<=>$a->{weight} } @{$self->{"editform"}}){
		my $obj = $self->get_plugin_instance($plugin->{class});
		$buf .= $obj->editform($self)."\n";
	}
	return $buf;
}

#==============================================================================
# <p>
# �������ѤΥ�˥塼���ɲä��ޤ��������ԥ桼���������󤷤�����ɽ������ޤ���
# ͥ���٤��⤤�ۤɾ�Τۤ���ɽ������ޤ���
# </p>
# <pre>
# $wiki-&gt;add_admin_menu(��˥塼����̾,���ܤ���URL,ͥ����,�ܺ�����);
# </pre>
#==============================================================================
sub add_admin_menu {
	my $self   = shift;
	my $label  = shift;
	my $url    = shift;
	my $weight = shift;
	my $desc   = shift;
	
	push(@{$self->{"admin_menu"}},{label=>$label,url=>$url,weight=>$weight,desc=>$desc,type=>0});
}

#==============================================================================
# <p>
# ������桼���ѤΥ�˥塼���ɲä��ޤ���
# �桼���������󤷤�����ɽ������ޤ��������ԥ桼���ξ���ɽ������ޤ���
# ͥ���٤��⤤�ۤɾ�Τۤ���ɽ������ޤ���
# </p>
# <pre>
# $wiki-&gt;add_admin_menu(��˥塼����̾,���ܤ���URL,ͥ����,�ܺ�����);
# </pre>
#==============================================================================
sub add_user_menu {
	my $self   = shift;
	my $label  = shift;
	my $url    = shift;
	my $weight = shift;
	my $desc   = shift;
	
	push(@{$self->{"admin_menu"}},{label=>$label,url=>$url,weight=>$weight,desc=>$desc,type=>1});
}

#==============================================================================
# <p>
# �������ѤΥ�˥塼��������ޤ���
# </p>
#==============================================================================
sub get_admin_menu {
	my $self = shift;
	return sort { $b->{weight}<=>$a->{weight} } @{$self->{"admin_menu"}};
}

#==============================================================================
# <p>
# �ץ饰����򥤥󥹥ȡ��뤷�ޤ������Υ᥽�åɤ�wiki.cgi�ˤ�ä�call����ޤ���
# �ץ饰����ȯ�ˤ������̾���Υ᥽�åɤ���Ѥ��뤳�ȤϤ���ޤ���
# </p>
#==============================================================================
sub install_plugin {
	my $self   = shift;
	my $plugin = shift;
	
	if ($plugin =~ /\W/) {
		return "<div class=\"error\">".Util::escapeHTML("${plugin}�ץ饰����������ʥץ饰����Ǥ���")."</div>";
	}
		
	my $module = "plugin::${plugin}::Install";
	eval 'require &Util::get_module_file($module);'.$module.'::install($self);';
	
	if($@){
		return "<div class=\"error\">".Util::escapeHTML("${plugin}�ץ饰���󤬥��󥹥ȡ���Ǥ��ޤ���$@")."</div>";
	} else {
		push(@{$self->{"installed_plugin"}},$plugin);
		return "";
	}
}

#==============================================================================
# <p>
# �ץ饰���󤬥��󥹥ȡ��뤵��Ƥ��뤫�ɤ�����Ĵ�٤ޤ���
# </p>
#==============================================================================
sub is_installed {
	my $self   = shift;
	my $plugin = shift;
	
	foreach (@{$self->{"installed_plugin"}}){
		if($_ eq $plugin){
			return 1;
		}
	}
	return 0;
}

#==============================================================================
# <p>
# ��˥塼���ܤ��ɲä��ޤ�������Ʊ��̾���ι��ܤ���Ͽ����Ƥ�����Ͼ�񤭤��ޤ���
# ͥ���٤��⤤�ۤɺ�¦��ɽ������ޤ���
# </p>
# <pre>
# $wiki-&gt;add_menu(����̾,URL,ͥ����,���������ݤ��뤫�ɤ���);
# </pre>
# <p>
# �������󥸥�˥����뤵�������ʤ�������4������1�����Ĥ������0����ꤷ�ޤ���
# ��ά�������ϥ��������Ĥ��ޤ���
# </p>
#==============================================================================
sub add_menu {
	my $self     = shift;
	my $name     = shift;
	my $href     = shift;
	my $weight   = shift;
	my $nofollow = shift;
	
	my $flag = 0;
	foreach(@{$self->{"menu"}}){
		if($_->{name} eq $name){
			$_->{href} = $href;
			$flag = 1;
			last;
		}
	}
	if($flag==0){
		push(@{$self->{"menu"}},{name=>$name,href=>$href,weight=>$weight,nofollow=>$nofollow});
	}
}

#===============================================================================
# <p>
# �եå��ץ饰�������Ͽ���ޤ�����Ͽ�����ץ饰�����do_hook�᥽�åɤǸƤӽФ��ޤ���
# </p>
# <pre>
# $wiki-&gt;add_hook(�եå�̾,�եå��ץ饰����Υ��饹̾);
# </pre>
#===============================================================================
sub add_hook {
	my $self = shift;
	my $name = shift;
	my $obj  = shift;
	
	push(@{$self->{"hook"}->{$name}},$obj);
}

#===============================================================================
# <p>
# add_hook�᥽�åɤ���Ͽ���줿�եå��ץ饰�����¹Ԥ��ޤ���
# �����ˤϥեå���̾���˲ä���Ǥ�դΥѥ�᡼�����Ϥ����Ȥ��Ǥ��ޤ���
# �����Υѥ�᡼���ϸƤӽФ���륯�饹��hook�᥽�åɤΰ����Ȥ����Ϥ���ޤ���
# </p>
# <pre>
# $wiki-&gt;do_hook(�եå�̾[,����1[,����2...]]);
# </pre>
#===============================================================================
sub do_hook {
	my $self = shift;
	my $name = shift;
	
	foreach my $class (@{$self->{"hook"}->{$name}}){
		my $obj = $self->get_plugin_instance($class);
		$obj->hook($self,$name,@_);
	}
}

#==============================================================================
# <p>
# ���������ϥ�ɥ�ץ饰������ɲä��ޤ���
# �ꥯ�����Ȼ���action�Ȥ����ѥ�᡼�������פ��륢������󤬸ƤӽФ���ޤ���
# </p>
# <pre>
# $wiki-&gt;add_handler(action�ѥ�᡼��,���������ϥ�ɥ�Υ��饹̾);
# </pre>
#==============================================================================
sub add_handler {
	my $self   = shift;
	my $action = shift;
	my $class  = shift;
	
	$self->{"handler"}->{$action}=$class;
	$self->{"handler_permission"}->{$action} = 1;
}

#==============================================================================
# <p>
# ������桼���ѤΥ��������ϥ�ɥ���ɲä��ޤ���
# ���Υ᥽�åɤˤ�ä��ɲä��줿���������ϥ�ɥ�ϥ����󤷤Ƥ�����Τ߼¹Բ�ǽ�Ǥ���
# ����ʳ��ξ��ϥ��顼��å�������ɽ�����ޤ���
# </p>
# <pre>
# $wiki-&gt;add_user_handler(action�ѥ�᡼��,���������ϥ�ɥ�Υ��饹̾);
# </pre>
#==============================================================================
sub add_user_handler {
	my $self   = shift;
	my $action = shift;
	my $class  = shift;
	
	$self->{"handler"}->{$action}=$class;
	$self->{"handler_permission"}->{$action} = 2;
}

#==============================================================================
# <p>
# �������ѤΥ��������ϥ�ɥ���ɲä��ޤ���
# ���Υ᥽�åɤˤ�ä��ɲä��줿���������ϥ�ɥ�ϴ����ԤȤ��ƥ����󤷤Ƥ�����Τ߼¹Բ�ǽ�Ǥ���
# ����ʳ��ξ��ϥ��顼��å�������ɽ�����ޤ���
# </p>
# <pre>
# $wiki-&gt;add_admin_handler(action�ѥ�᡼��,���������ϥ�ɥ�Υ��饹̾);
# </pre>
#==============================================================================
sub add_admin_handler {
	my $self   = shift;
	my $action = shift;
	my $class  = shift;
	
	$self->{"handler"}->{$action}=$class;
	$self->{"handler_permission"}->{$action} = 0;
}
#==============================================================================
# <p>
# ����饤��ץ饰������ɲä��ޤ���
# </p>
# <p>
# ���Υ᥽�åɤ�3.4�ϤȤθߴ�����ݻ����뤿��˻Ĥ��ޤ�����3.6���ѻߤ����ΤȤ��ޤ���
# </p>
#==============================================================================
sub add_plugin {
	my $self   = shift;
	my $name   = shift;
	my $class  = shift;
	
	$self->add_inline_plugin($name,$class,"HTML");
}
#==============================================================================
# <p>
# ����饤��ץ饰�������Ͽ���ޤ����ץ饰����ν��ϥ����פˤ�"WIKI"�ޤ���"HTML"����ꤷ�ޤ���
# ��ά��������"HTML"����ꤷ����ΤȤߤʤ���ޤ���
# </p>
# <pre>
# $wiki-&gt;add_inline_plugin(�ץ饰����̾,�ץ饰����Υ��饹̾,�ץ饰����ν��ϥ�����);
# </pre>
#==============================================================================
sub add_inline_plugin {
	my ($self, $name, $class, $format) = @_;
	
	if($format eq ""){
		$format = "HTML";
	} else {
		$format = uc($format);
	}
	
	$self->{"plugin"}->{$name} = {CLASS=>$class,TYPE=>'inline',FORMAT=>$format};
}

#==============================================================================
# <p>
# �ѥ饰��եץ饰�������Ͽ���ޤ����ץ饰����ν��ϥ����פˤ�"WIKI"�ޤ���"HTML"����ꤷ�ޤ���
# ��ά��������"HTML"����ꤷ����ΤȤߤʤ���ޤ���
# </p>
# <pre>
# $wiki-&gt;add_inline_plugin(�ץ饰����̾,�ץ饰����Υ��饹̾,�ץ饰����ν��ϥ�����);
# </pre>
#==============================================================================
sub add_paragraph_plugin {
	my ($self, $name, $class, $format) = @_;
	
	if($format eq ""){
		$format = "HTML";
	} else {
		$format = uc($format);
	}
	
	$self->{"plugin"}->{$name} = {CLASS=>$class,TYPE=>'paragraph',FORMAT=>$format};
}

#==============================================================================
# <p>
# �֥�å��ץ饰�������Ͽ���ޤ����ץ饰����ν��ϥ����פˤ�"WIKI"�ޤ���"HTML"����ꤷ�ޤ���
# ��ά��������"HTML"����ꤷ����ΤȤߤʤ���ޤ���
# </p>
# <pre>
# $wiki-&gt;add_block_plugin(�ץ饰����̾,�ץ饰����Υ��饹̾,�ץ饰����ν��ϥ�����);
# </pre>
#==============================================================================
sub add_block_plugin {
	my ($self, $name, $class, $format) = @_;
	
	if($format eq ""){
		$format = "HTML";
	} else {
		$format = uc($format);
	}
	
	$self->{"plugin"}->{$name} = {CLASS=>$class,TYPE=>'block',FORMAT=>$format};
}

#==============================================================================
# <p>
# �ץ饰����ξ����������ޤ�
# </p>
# <pre>
# my $info = $wiki-&gt;get_plugin_info(&quot;include&quot;);
# my $class  = $info-&gt;{CLASS};  # �ץ饰����Υ��饹̾
# my $type   = $info-&gt;{TYPE};   # inline��paragraph��block�Τ����줫
# my $format = $info-&gt;{FORMAT}; # HTML�ޤ���WIKI
# </pre>
#==============================================================================
sub get_plugin_info {
	my $self = shift;
	my $name = shift;
	
	return $self->{plugin}->{$name};
}

#==============================================================================
# <p>
# add_handler�᥽�åɤ���Ͽ���줿���������ϥ�ɥ��¹Ԥ��ޤ���
# ���������ϥ�ɥ��do_action�᥽�åɤ�����ͤ��֤��ޤ���
# </p>
# <pre>
# my $content = $wiki-&gt;call_handler(action�ѥ�᡼��);
# </pre>
#==============================================================================
sub call_handler {
	my $self   = shift;
	my $action = shift;
	
	if(!defined($action)){
		$action = "";
	}
	
	my $obj = $self->get_plugin_instance($self->{"handler"}->{$action});
	
	unless(defined($obj)){
		return $self->error("�����ʥ��������Ǥ���");
	}
	
	# �������ѤΥ��������
	if($self->{"handler_permission"}->{$action}==0){
		my $login = $self->get_login_info();
		if(!defined($login)){
			return $self->error("�����󤷤Ƥ��ޤ���");
			
		} elsif($login->{type}!=0){
			return $self->error("�����Ը��¤�ɬ�פǤ���");
		}
		return $obj->do_action($self).
		       "<div class=\"comment\"><a href=\"".$self->create_url({action=>"LOGIN"})."\">��˥塼�����</a></div>";
	
	# ������桼���ѤΥ��������
	} elsif($self->{"handler_permission"}->{$action}==2){
		my $login = $self->get_login_info();
		if(!defined($login)){
			return $self->error("�����󤷤Ƥ��ޤ���");
		}
		return $obj->do_action($self).
		       "<div class=\"comment\"><a href=\"".$self->create_url({action=>"LOGIN"})."\">��˥塼�����</a></div>";
		
	# ���̤Υ��������
	} else {
		return $obj->do_action($self);
	}
}

#===============================================================================
# <p>
# �������Ϥ���Wiki�ե����ޥåȤ�ʸ�����HTML���Ѵ������֤��ޤ���
# </p>
# <pre>
# my $html = $wiki-&gt;process_wiki(ʸ����);
# </pre>
#===============================================================================
sub process_wiki {
	my $self    = shift;
	my $source  = shift;
	my $mainflg = shift;
	
	if($self->{parse_times} >= 50){
		return $self->error("Wiki::process_wiki�θƤӽФ��������¤�ۤ��ޤ�����");
	}
	
	$self->{parse_times}++;
	my $parser = Wiki::HTMLParser->new($self,$mainflg);
	$parser->parse($source);
	$self->{parse_times}--;
	
	return $parser->{html};
}

#===============================================================================
# <p>
# ����饤��ץ饰���󡢥ѥ饰��եץ饰����θƤӽФ������������Ѥδؿ��ˡ�
# ����Υ᥽�åɤΤ���̿̾��§��private�᥽�åɤΥ᥽�å�̾��_����Ϥ���
# �˽��äƤ��ޤ���
# </p>
#===============================================================================
sub process_plugin {
	my $self   = shift;
	my $plugin = shift;
	my $parser = shift;
	
	if(defined($plugin->{error}) && $plugin->{error} ne ""){
		return "<font class=\"error\">".$plugin->{error}."</font>";
	}

	my $name = $plugin->{command};
	my @args = @{$plugin->{args}};
	my $info = $self->get_plugin_info($name);
	my $obj  = $self->get_plugin_instance($info->{CLASS});

	if(!defined($obj)){
		return "<font class=\"error\">".&Util::escapeHTML($name)."�ץ饰�����¸�ߤ��ޤ���</font>";
		
	} else {
		if($info->{FORMAT} eq "WIKI"){
			# ΢����(�ץ饰������������ѡ�����Ȥ����)
			push(@{$self->{'current_parser'}}, $parser);
			if($info->{TYPE} eq "inline"){
				my @result = $parser->parse_line($obj->inline($self,@args));
				pop(@{$self->{'current_parser'}});
				return @result;
			} elsif($info->{TYPE} eq "paragraph"){
				$parser->parse($obj->paragraph($self,@args));
			} else {
				$parser->parse($obj->block($self,@args));
			}
			# �ѡ����λ��Ȥ����
			pop(@{$self->{'current_parser'}});
			return undef;
		} else {
			if($info->{TYPE} eq "inline"){
				return $obj->inline($self,@args);
			} elsif($info->{TYPE} eq "paragraph"){
				return $obj->paragraph($self,@args);
			} else {
				return $obj->block($self,@args);
			}
		}
	}
}

#==============================================================================
# <p>
# �ѡ�����ξ�硢����ͭ����Wiki::Parser�Υ��󥹥��󥹤��ֵѤ��ޤ���
# �ѡ���������Ƥ�ץ饰���󤫤��ѹ����������˻��Ѥ��ޤ���
# </p>
#==============================================================================
sub get_current_parser {
	my $self = shift;
	my @parsers = @{$self->{'current_parser'}};
	return $parsers[$#parsers];
}

#==============================================================================
# <p>
# ���顼�ξ�硢�ƤӽФ��ޤ���
# ���������ϥ�ɥ餫�饨�顼����𤹤�ݤ˻��Ѥ��Ƥ���������
# </p>
# <pre>
# sub do_action {
#   my $self = shift;
#   my $wiki = shift;
#   ...
#   return $wiki-&gt;error(���顼��å�����);
# }
# </pre>
#==============================================================================
sub error {
	my $self    = shift;
	my $message = shift;
	
	$self->set_title("���顼");
	$self->get_CGI->param("action","ERROR");
	
	return "<div class=\"error\">".Util::escapeHTML($message)."</div>";
}

#===============================================================================
# <p>
# �ץ饰����Υ��󥹥��󥹤�������ޤ���Wiki.pm������Ū�˻��Ѥ����᥽�åɤǤ���
# �ץ饰����ȯ�ˤ������̾���Υ᥽�åɤ���Ѥ���ɬ�פϤ���ޤ���
# </p>
#===============================================================================
sub get_plugin_instance {
	my $self  = shift;
	my $class = shift;
	
	if($class eq ""){
		return undef;
	}
	
	if(!defined($self->{instance}->{$class})){
		eval {
			require &Util::get_module_file($class);
		};
		return undef if $@;
		my $obj = $class->new();
		$self->{instance}->{$class} = $obj;
		
		return $obj;
	} else {
		return $self->{instance}->{$class};
	}
}

#===============================================================================
# <p>
# ����饤��ץ饰�����ѡ������ƥ��ޥ�ɤȰ�����ʬ�䤷�ޤ���
# </p>
#===============================================================================
sub parse_inline_plugin {
	my $self = shift;
	my $text = shift;
	my ($cmd, @args_tmp) = split(/ /,$text);
	my $args_txt = &Util::trim(join(" ",@args_tmp));
	if($cmd =~ s/}}(.*?)$//){
		return { command=>$cmd, args=>[], post=>"$1 $args_txt"};
	}
	
	my @ret_args;
	my $tmp    = "";
	my $escape = 0;
	my $quote  = 0;
	my $i      = 0;
	
	for($i = 0; $i<length($args_txt); $i++){
		my $c = substr($args_txt,$i,1);
		if($quote!=1 && $c eq ","){
			if($quote==3){
				$tmp .= '}';
			}
			push(@ret_args,$tmp);
			$tmp = "";
			$quote = 0;
		} elsif($quote==1 && $c eq "\\"){
			if($escape==0){
				$escape = 1;
			} else {
				$tmp .= $c;
				$escape = 0;
			}
		} elsif($quote==0 && $c eq '"'){
			if($tmp eq ""){
				$quote = 1;
			} else {
				$tmp .= $c;
			}
		} elsif($quote==1 && $c eq '"'){
			if($escape==1){
				$tmp .= $c;
				$escape = 0;
			} else {
				$quote = 2;
			}
		} elsif(($quote==0 || $quote==2) && $c eq '}'){
			$quote = 3;
		} elsif($quote==3){
			if($c eq '}'){
				last;
			} else {
				$tmp .= '}'.$c;
				$quote = 0;
			}
		} elsif($quote==2){
			return {error=>"����饤��ץ饰����ι�ʸ�������Ǥ���"};
		} else {
			$tmp .= $c;
			$escape = 0;
		}
	}
	
	if($quote!=3){
		my $info = $self->get_plugin_info($cmd);
		return undef if (defined($info->{TYPE}) && $info->{TYPE} ne 'block');
	}
	
	if($tmp ne ""){
		push(@ret_args,$tmp);
	}
	
	return { command=>$cmd, args=>\@ret_args, 
		post=>substr($args_txt, $i + 1, length($args_txt) - $i)};
}

#==============================================================================
# <p>
# �ե����ޥåȥץ饰������ɲä��ޤ���
# �ե����ޥåȥץ饰�����convert_to_fswiki�᥽�åɤ�convert_from_fswiki�᥽�åɤ�
# �����������饹�Ǥʤ��ƤϤʤ�ޤ���
# </p>
# <pre>
# $wiki-&gt;add_format_plugin(ʸˡ̾,���饹̾);
# </pre>
#==============================================================================
sub add_format_plugin {
	my $self  = shift;
	my $name  = shift;
	my $class = shift;
	
	$self->{'format'}->{$name} = $class;
}

#==============================================================================
# <p>
# ���󥹥ȡ��뤵��Ƥ���ե����ޥåȥץ饰����ΰ�����������ޤ���
# </p>
# <pre>
# my @formats = $wiki-&gt;get_format_names();
# </pre>
#==============================================================================
sub get_format_names {
	my $self = shift;
	my @list = keys(%{$self->{'format'}});
	if(!scalar(@list)){
		push(@list, "FSWiki");
	}
	return sort(@list);
}

#==============================================================================
# <p>
# ��Wiki�񼰤ǵ��Ҥ�����������FSWiki�ν񼰤��Ѵ����ޤ���
# </p>
# <pre>
# $source = $wiki-&gt;convert_to_fswiki($source,&quot;YukiWiki&quot;);
# </pre>
# <p>
# ����饤��񼰤Τ��Ѵ���Ԥ������軰������1���Ϥ��ޤ���
# </p>
# <pre>
# $source = $wiki-&gt;convert_to_fswiki($source,&quot;YukiWiki&quot;,1);
# </pre>
#==============================================================================
sub convert_to_fswiki {
	my $self   = shift;
	my $source = shift;
	my $type   = shift;
	my $inline = shift;
	
	my $obj = $self->get_plugin_instance($self->{'format'}->{$type});
	unless(defined($obj)){
		return $source;
	} else {
		$source =~ s/\r\n/\n/g;
		$source =~ s/\r/\n/g;
		if($inline){
			return $obj->convert_to_fswiki_line($source);
		} else {
			return $obj->convert_to_fswiki($source);
		}
	}
}

#==============================================================================
# <p>
# FSWiki�ν񼰤ǵ��Ҥ������������Wiki�ν񼰤��Ѵ����ޤ���
# </p>
# <pre>
# $source = $wiki-&gt;convert_from_fswiki($source,&quot;YukiWiki&quot;);
# </pre>
# <p>
# ����饤��񼰤Τ��Ѵ���Ԥ������軰������1���Ϥ��ޤ���
# </p>
# <pre>
# $source = $wiki-&gt;convert_from_fswiki($source,&quot;YukiWiki&quot;,1);
# </pre>
#==============================================================================
sub convert_from_fswiki {
	my $self   = shift;
	my $source = shift;
	my $type   = shift;
	my $inline = shift;
	
	my $obj = $self->get_plugin_instance($self->{'format'}->{$type});
	unless(defined($obj)){
		return $source;
	} else {
		$source =~ s/\r\n/\n/g;
		$source =~ s/\r/\n/g;
		if($inline){
			return $obj->convert_from_fswiki_line($source);
		} else {
			return $obj->convert_from_fswiki($source);
		}
	}
}

#==============================================================================
# <p>
# ���ߤΥ桼�����Խ��˻��Ѥ���ե����ޥåȤ�������ޤ���
# format�ץ饰���󤬥����ƥ��١��Ȥ���Ƥ��ʤ����Ͼ��"FSWiki"���֤��ޤ���
# </p>
# <pre>
# my $format = $wiki-&gt;get_edit_format();
# </pre>
#==============================================================================
sub get_edit_format {
	my $self = shift;
	my $from = shift;
	
	# format�ץ饰���󤬥����ƥ��١��Ȥ���Ƥ��ʤ����FSWiki�ե����ޥåȤ��֤�
	unless($self->is_installed("format")){
		return "FSWiki";
	}

	#�̾�ϴĶ�������̤����ꤷ��Wiki�ե����ޥåȤ����
	my $config = &Util::load_config_hash($self, $self->config('config_file'));
	my $format = $config->{site_wiki_format};

	# Cookie�˥ե����ޥåȤ����ꤵ��Ƥ�����Ϥ���������
	#(â����config.dat�ե����뤫��μ����������Cookie��̵��)
	if($from ne "config"){
		my $cgi = $self->get_CGI();
		if($cgi->cookie(-name=>'edit_format') ne ""){
			$format = $cgi->cookie(-name=>'edit_format');
		}
	}

	if($format eq ""){
		return "FSWiki";
	} else {
		return $format;
	}
}

#==============================================================================
# <p>
# head������˽��Ϥ��������ɲä��ޤ���
# �����������ȥƥ�ץ졼�Ȥ��б����Ƥ���ɬ�פ�����ޤ���
# </p>
# <pre>
# $wiki-&gt;add_head_info(&quot;<link rel=\&quot;alternate\&quot; type=\&quot;application/rss+xml\&quot; title=\&quot;RSS\&quot; href=\&quot;?action=RSS\&quot;>&quot;);
# </pre>
#==============================================================================
sub add_head_info {
	my $self = shift;
	my $info = shift;
	
	push(@{$self->{'head_info'}},$info);
}

###############################################################################
#
# ���˴ؤ���᥽�åɷ�
#
###############################################################################
#==============================================================================
# <p>
# �ڡ�������뤷�ޤ�
# </p>
# <pre>
# $wiki-&gt;freeze_page(�ڡ���̾);
# </pre>
#==============================================================================
sub freeze_page {
	my $self = shift;
	$self->{"storage"}->freeze_page(@_);
}

#==============================================================================
# <p>
# �ڡ��������������ޤ�
# </p>
# <pre>
# $wiki-&gt;un_freeze_page(�ڡ���̾);
# </pre>
#==============================================================================
sub un_freeze_page {
	my $self = shift;
	$self->{"storage"}->un_freeze_page(@_);
}

#==============================================================================
# <p>
# ��뤵��Ƥ���ڡ����Υꥹ�Ȥ�������ޤ���
# </p>
#==============================================================================
sub get_freeze_list {
	my $self = shift;
	return $self->{"storage"}->get_freeze_list();
}

#==============================================================================
# <p>
# �������Ϥ����ڡ���������椫�ɤ�������٤ޤ�
# </p>
# <pre>
# if($wiki-&gt;is_freeze(�ڡ���̾)){
#   ...
# }
# </pre>
#==============================================================================
sub is_freeze {
	my $self = shift;
	my $page = shift;
	my $path = undef;
	
	if($page =~ /(^.*?[^:]):([^:].*?$)/){
		$path = $1;
		$page = $2;
	}
	
	return $self->{storage}->is_freeze($page,$path);
}

#==============================================================================
# <p>
# �������Ϥ����ڡ������Խ���ǽ���ɤ�����Ĵ�٤ޤ���
# �Խ��Բĥ⡼�ɡ�setup.pl��$accept_edit��0�����ꤵ��Ƥ�����ˤϥ����󤷤Ƥ�����Խ���ǽ��
# �ڡ�������뤵��Ƥ�����ϴ����ԥ桼���ǥ����󤷤Ƥ�������Խ���ǽ�Ȥʤ�ޤ���
# </p>
# <pre>
# if($wiki-&gt;can_modify_page(�ڡ���̾)){
#   ...
# }
# </pre>
#==============================================================================
sub can_modify_page {
	my $self = shift;
	my $page = shift;
	my $login = $self->get_login_info();
	if($self->config('accept_edit')==0 && !defined($login)){
		return 0;
	}
	if($self->config('accept_edit')==2 && (!defined($login) || $login->{type}!=0)){
		return 0;
	}
	if($self->is_freeze($page) && (!defined($login) || $login->{type}!=0)){
		return 0;
	}
	unless($self->can_show($page)){
		return 0;
	}
	return 1;
}

###############################################################################
#
# ���ȸ��¤˴ؤ���᥽�åɷ�
#
###############################################################################
#==============================================================================
# <p>
# �ڡ����λ��ȥ�٥�����ꤷ�ޤ���
# <p>
# <ul>
#   <li>0 - �����˸���</li>
#   <li>1 - �桼���˸���</li>
#   <li>2 - �����Ԥ˸���</li>
# </ul>
# <pre>
# $wiki-&gt;set_page_level(�ڡ���̾,������٥�);
# </pre>
#==============================================================================
sub set_page_level {
	my $self  = shift;
	my $page  = shift;
	my $level = shift;

	$self->{"storage"}->set_page_level($page,$level);

	# $level ��̤����ʤ�ڡ����ǡ�������ʤΤǡ��եå���Ϣ�������ס�
	return if (not defined $level);

	# ���������ݤ򸡺���
	my $new_level = $self->get_page_level($page);
	if ($new_level != $level) {
		die "�ڡ��� '$page' �λ��ȸ��¥�٥�� '$level' ���ѹ����褦�Ȥ��ޤ��������Ԥ��ޤ�����";
	}

	# �ڡ�����٥���ѹ������������Τǡ��եå���ȯ�ԡ�
	$self->do_hook('change_page_level', $page, $new_level);
}

#==============================================================================
# <p>
# �ڡ����λ��ȥ�٥��������ޤ���
# �ڡ���̾�����ꤵ��Ƥ��ʤ���硢���ƤΥڡ����λ��ȥ�٥��
# �ϥå����ե���󥹤��֤��ޤ���
# </p>
# <ul>
#   <li>0 - �����˸���</li>
#   <li>1 - �桼���˸���</li>
#   <li>2 - �����Ԥ˸���</li>
# </ul>
# <pre>
# my $level = $get_page_level(�ڡ���̾);
# </pre>
#==============================================================================
sub get_page_level {
	my $self  = shift;
	my $page  = shift;
	my $path  = undef;
	
	if($page =~ /(^.*?[^:]):([^:].*?$)/){
		$path = $1;
		$page = $2;
	}
	
	$self->{"storage"}->get_page_level($page,$path);
}

#==============================================================================
# <p>
# ���ߤΥ桼�����¤Ǳ�����ǽ�ʥڡ�����٥�ξ���ͤ���ޤ���
# </p>
# <pre>
# my $can_show_max = $wiki-&gt;_get_can_show_max();
# </pre>
#==============================================================================
sub _get_can_show_max {
	my $self = shift;

	# �ֱ�����ǽ�� page level �ξ���͡פ����Τʤ�С�������ֵѡ�
	if (exists $self->{'can_show_max'}) {
		return $self->{'can_show_max'};
	}

	# Wiki ���Τα������¤������ͤȡ������ԤΥ桼�����¥�٥����롣
	my $accept_show = $self->config('accept_show'); # Wiki ���Τα�������
	my $login_user  = $self->get_login_info();      # ���ߤ� login ����
	my $user_level                                  # �桼�����¥�٥�
		= (not defined $login_user)  ? 0            #   �������桼��
		: ($login_user->{type} != 0) ? 1            #   ������桼��
		:                              2;           #   ������

	# Wiki ���Τα������¤�ã���Ƥ���桼���ʤ顢
	if ($user_level >= $accept_show) {
		# �ֱ�����ǽ�� page level ����͡פϡ��桼�����¥�٥����������
		return $self->{'can_show_max'} = $user_level;
	}

	# Wiki ���Τα������¤�ã���Ƥ��ʤ��桼���ʤΤǡ�
	# �ֱ�����ǽ�� page level ����͡פ� -1�����ʤ�������ڡ��������Բġ�
	return $self->{'can_show_max'} = -1;
}

#==============================================================================
# <p>
# �ڡ��������Ȳ�ǽ���ɤ�����������ޤ���
# </p>
# <pre>
# if($wiki-&gt;can_show(�ڡ���̾)){
#   # ���Ȳ�ǽ
# } else {
#   # �����Բ�ǽ
# }
# </pre>
#==============================================================================
sub can_show {
	my ($self, $page) = @_;

	#�ֱ�����ǽ page level ��¡פ�̤�Τʤ�С����롣
	if (not exists $self->{'can_show_max'}) {
		$self->_get_can_show_max();
	}

	# page level ����������ǽ page level ��°ʲ��ʤ鿿���֤���
	return ($self->get_page_level($page) <= $self->{'can_show_max'});
}

###############################################################################
#
# ����¾�Υ᥽�åɷ�
#
###############################################################################
#==============================================================================
# <p>
# �ڡ����˥����פ��뤿���URL����������桼�ƥ���ƥ��᥽�åɤǤ���
# �����Ȥ��ƥڡ���̾���Ϥ��ޤ���
# </p>
# <pre>
# $wiki-&gt;create_page_url(&quot;FrontPage&quot;);
# </pre>
# <p>
# �嵭�Υ����ɤ��̾�ʲ���URL���������ޤ���
# </p>
# <pre>
# wiki.cgi?page=FrontPage
# </pre>
#==============================================================================
sub create_page_url {
	my $self = shift;
	my $page = shift;
	return $self->create_url({page=>$page});
}

#==============================================================================
# <p>
# Ǥ�դ�URL���������뤿��Υ桼�ƥ���ƥ��᥽�åɤǤ���
# �����Ȥ��ƥѥ�᡼���Υϥå����ե���󥹤��Ϥ��ޤ���
# </p>
# <pre>
# $wiki-&gt;create_url({action=>HOGE,type=>1});
# </pre>
# <p>
# �嵭�Υ����ɤ��̾�ʲ���URL���������ޤ���
# </p>
# <pre>
# wiki.cgi?action=HOGE&amp;type=1
# </pre>
#==============================================================================
sub create_url {
	my $self   = shift;
	my $params = shift;
	my $url    = $self->config('script_name');
	my $query  = '';
	foreach my $key (keys(%$params)){
		if($query ne ''){
			$query .= '&amp;';
		}
		$query .= Util::url_encode($key)."=".Util::url_encode($params->{$key});
	}
	if($query ne ''){
		$url .= '?'.$query; 
	}
	return $url;
}

#==============================================================================
# <p>
# ���������ϥ�ɥ���ǥ����ȥ�����ꤹ����˻��Ѥ��ޤ���
# </p>
# <pre>
# $wiki-&gt;set_title(�����ȥ�[,�Խ��ϤΥڡ������ɤ���]);
# </pre>
# <p>
# �Խ��Ϥβ��̤ξ�硢���������1����ꤷ�Ƥ���������
# ��ܥå��к��Ѥ˰ʲ���META���������Ϥ���ޤ���
# </p>
# <pre>
# &lt;meta name=&quot;ROBOTS&quot; content=&quot;NOINDEX, NOFOLLOW&quot;&gt;
# </pre>
#==============================================================================
sub set_title {
	my $self  = shift;
	my $title = shift;
	my $edit  = shift;
	$self->{"title"} = $title;
	$self->{"edit"}  = 1 if $edit;
}

#==============================================================================
# <p>
# �����ȥ��������ޤ���
# </p>
#==============================================================================
sub get_title {
	my $self = shift;
	return $self->{"title"};
}

#==============================================================================
# <p>
# �ڡ����ΰ�����������ޤ���
# �����Ȥ��ƥϥå����ե���󥹤��Ϥ����ȤǼ������Ƥ���ꤹ�뤳�Ȥ���ǽ��
# �ǥե���ȤǤ����ƤΥڡ�����̾���ǥ����Ȥ����ꥹ�Ȥ��ֵѤ��롣
# </p>
# <p>
# �ʲ�����ϻ��ȸ��Τ���ڡ����Τ߼����������������ǥ����Ȥ��롣
# </p>
# <pre>
# my @list = $wiki-&gt;get_page_list({-sort   => 'last_modified',
#                                  -permit => 'show'});
# </pre>
# <p>
# �ʲ���������ƤΥڡ������������̾���ǥ����Ȥ��롣
# </p>
# <pre>
# my @list = $wiki-&gt;get_page_list({-sort => 'name'});
# </pre>
# <p>
# �ʲ�����Ϻǿ���10���������롣
# </p>
# <pre>
# my @list = $wiki-&gt;get_page_list({-sort=>'last_modified',-max=>10});
# </pre>
#==============================================================================
sub get_page_list {
	my $self = shift;
	my $args = shift;
	
	return $self->{"storage"}->get_page_list($args);

}

#==============================================================================
# <p>
# �ڡ�����ʪ��Ū�ʡʥǡ����ե�����ι��������˺ǽ����������������ޤ���
# </p>
# <pre>
# my $modified = $wiki-&gt;get_last_modified(�ڡ���̾);
# </pre>
#==============================================================================
sub get_last_modified {
	my $self = shift;
	return $self->{"storage"}->get_last_modified(@_);
}

#==============================================================================
# <p>
# �ڡ�������Ū�ʺǽ����������������ޤ���
# �֥����ॹ����פ򹹿����ʤ��פ˥����å�������ƥڡ�������¸��������
# ���Υ᥽�åɤ��֤������������¸���Τ�Τˤʤ�ޤ���
# </p>
# <pre>
# my $modified = $wiki-&gt;get_last_modified2(�ڡ���̾);
# </pre>
#==============================================================================
sub get_last_modified2 {
	my $self = shift;
	return $self->{"storage"}->get_last_modified2(@_);
}

#==============================================================================
# <p>
# �ڡ����Υ�������������ޤ���
# </p>
# <p>
# �軰�����˥ե����ޥå�̾���Ϥ������Τߡ��ե����ޥåȥץ饰����ˤ��
# ���������Ѵ���Ԥ��ޤ�������ʳ��ξ���ɬ�פ˱����ƥץ饰����¦��
# Wiki::convert_from_fswiki�᥽�åɤ�Ƥ���Ѵ���Ԥ��ޤ���
# </p>
#==============================================================================
sub get_page {
	my $self   = shift;
	my $page   = shift;
	my $format = shift;
	my $path   = undef;
	
	if($page =~ /(^.*?[^:]):([^:].*?$)/){
		$path = $1;
		$page = $2;
	}
	
	my $content = $self->{"storage"}->get_page($page,$path);
	
	if($format eq "" || $format eq "FSWiki"){
		return $content;
	} else {
		return $self->convert_from_fswiki($content,$format);
	}
}

#==============================================================================
# <p>
# �Хå����åפ��줿��������������ޤ����Хå����åפ�¸�ߤ��ʤ����϶�ʸ������֤��ޤ���
# ����Хå����åפ��б��������ȥ졼������Ѥ��Ƥ��������������˼��������������ꤹ�뤳�Ȥ��Ǥ��ޤ���
# </p>
# <pre>
# # ����Хå����åפ���Ѥ��Ƥ��ʤ����
# my $backup = $wiki-&gt;get_backup(�ڡ���̾);
#
# # ����Хå����åפ���Ѥ��Ƥ�����
# my $backup = $wiki-&gt;get_backup(�ڡ���̾,����);
# </pre>
# <p>
# ����ϸŤ���Τ�����0���ο��ͤǻ��ꤷ�ޤ���
# </p>
#==============================================================================
sub get_backup {
	my $self = shift;
	return $self->{"storage"}->get_backup(@_);
}

#==============================================================================
# <p>
# �ڡ�������¸���ޤ���
# ����å���⡼��ON�����Ѥ��Ƥ����硢�ڡ����Υ���å����������ޤ���
# </p>
# <pre>
# $wiki-&gt;save_page(�ڡ���̾,�ڡ�������);
# </pre>
# <p>
# �ե����ޥåȥץ饰����ˤ��ե����ޥåȤ��Ѵ��ϹԤ��ޤ���
# �Ĥޤꡢ�ե����ޥåȥץ饰�������Ѥ��Ƥ����硢���Υ᥽�åɤ��Ϥ�
# Wiki�������ϻ�����FSWiki�������Ѵ����줿�������Ǥʤ���Фʤ�ޤ���
# </p>
# <p>
# ��¸���˥����ॹ����פ򹹿����ʤ���硢�軰������1���Ϥ��ޤ���
# </p>
# <pre>
# $wiki-&gt;save_page(�ڡ���̾,�ڡ�������,1);
# </pre>
#
#==============================================================================
sub save_page {
	my $self     = shift;
	my $pagename = shift;
	my $content  = shift;
	my $sage     = shift;
	
	# �ڡ���̾������å�
	if($pagename =~ /([\|\[\]])|^:|([^:]:[^:])/){
		die "�ڡ���̾�˻��ѤǤ��ʤ�ʸ�����ޤޤ�Ƥ��ޤ���";
	}
	# ���ä���ѥ�᡼������
	$self->get_CGI->param("page"   ,$pagename);
	$self->get_CGI->param("content",$content);
	$self->do_hook("save_before");
	# �ѥ�᡼�����ɤ߹���ľ��
	$content = $self->get_CGI()->param("content");
	
	if($self->{"storage"}->save_page($pagename,$content,$sage)){
		if($content ne ""){
			$self->do_hook("save_after");
		} else {
			$self->do_hook("delete");
		}
	}
}

#===============================================================================
# <p>
# �ڡ�����¸�ߤ��뤫�ɤ���Ĵ�٤ޤ���
# </p>
# <pre>
# if($wiki-&gt;page_exists(�ڡ���̾)){
#   # �ڡ�����¸�ߤ�����ν���
# } else {
#   # �ڡ�����¸�ߤ��ʤ����ν���
# }
# </pre>
#===============================================================================
sub page_exists {
	my $self = shift;
	my $page = shift;
	my $path = undef;
	
	if($page =~ /(^.*?[^:]):([^:].*?$)/){
		$path = $1;
		$page = $2;
	}
	
	# InterWiki�����λ���ǥɥåȤ�ޤळ�ȤϤǤ��ʤ�
	if(defined($path) && index($path,".")!=-1){
		return 0;
	}
	
	return $self->{"storage"}->page_exists($page,$path);
}

#===============================================================================
# <p>
# CGI���֥������Ȥ����
# </p>
# <pre>
# my $cgi = $wiki-&gt;get_CGI;
# </pre>
#===============================================================================
sub get_CGI {
	my $self = shift;
	return $self->{"CGI"};
}

#==============================================================================
# <p>
# �������Ϥ����ڡ����˥�����쥯�Ȥ��ޤ���
# �ڡ�������¸��˥ڡ������ɽ��������Ϥ��Υ᥽�åɤ���Ѥ��Ʋ�������
# �ʤ������Υ᥽�åɤ�ƤӽФ��Ȥ����ǥ�����ץȤμ¹ԤϽ�λ�����ƤӽФ�������������ޤ���
# </p>
# <pre>
# $wiki-&gt;redirect(&quot;FrontPage&quot;);
# </pre>
# <p>
# ��������˥ѡ����ֹ���Ϥ��Ȥ��Υѡ��Ȥ˥�����쥯�Ȥ��ޤ���
# </p>
# <pre>
# $wiki-&gt;redirect(&quot;FrontPage&quot;, 1);
# </pre>
#
#==============================================================================
sub redirect {
	my $self = shift;
	my $page = shift;
	my $part = shift;
	my $url = $self->create_page_url($page);
	if($part ne ""){
		$url .= "#p".Util::url_encode($part);
	}
	$self->redirectURL($url);
}

#==============================================================================
# <p>
# �����URL�˥�����쥯�Ȥ��ޤ���
# ���Υ᥽�åɤ�ƤӽФ��Ȥ����ǥ�����ץȤμ¹ԤϽ�λ�����ƤӽФ�������������ޤ���
# </p>
# <pre>
# $wiki-&gt;redirectURL(������쥯�Ȥ���URL);
# </pre>
#==============================================================================
sub redirectURL {
	my $self = shift;
	my $url  = shift;
	
	# Location�����ǥ�����쥯��
	if($self->config('redirect')==1){
		my ($hoge,$param) = split(/\?/,$url);
		$url = $self->get_CGI->url().$self->get_CGI()->path_info();
		if($param ne ''){
			$url = "$url?$param";
		}
		print "Location: $url\n\n";
		
	# META�����ǥ�����쥯��
	} else {
		my $tmpl = HTML::Template->new(filename=>$self->config('tmpl_dir')."/redirect.tmpl",
		                               die_on_bad_params => 0);
		
		$tmpl->param(URL=>$url);
		
		print "Content-Type: text/html\n\n";
		print $tmpl->output();
	}
	exit();
}

#==============================================================================
# <p>
# �����Х����������⤷�����ѹ����ޤ�
# </p>
# <pre>
# # �ǡ����ե�������Ǽ����ǥ��쥯�ȥ�
# my $data_dir = $wiki-&gt;config('data_dir');
#
# # �����$data_dir�Ǿ��
# $wiki-&gt;config('data_dir',$data_dir);
# </pre>
#==============================================================================
sub config {
	my $self  = shift;
	my $name  = shift;
	my $value = shift;
	if(defined($value)){
		$self->{config}->{$name} = $value;
	} else {
		return $self->{config}->{$name};
	}
}
###############################################################################
#
# Farm�ط��Υ᥽�åɷ�
#
###############################################################################
#==============================================================================
# <p>
# Farm��ǽ��ͭ���ˤʤäƤ��뤫�ɤ�����������ޤ�
# </p>
# <pre>
# if($wiki-&gt;farm_is_enable()){
#   # Farm��ͭ���ˤʤäƤ���Ȥ��ν���
# } else {
#   # Farm��̵���ˤʤäƤ���Ȥ��ν���
# }
# </pre>
#==============================================================================
sub farm_is_enable {
	my $self = shift;
	my $farm_config = &Util::load_config_hash($self,$self->config('farmconf_file'));
	if(defined $farm_config->{usefarm} and $farm_config->{usefarm}==1){
		return 1;
	} else {
		return 0;
	}
}

#==============================================================================
# <p>
# ��Wiki��������ޤ��������ˤ�Wiki��̾������������Wiki�����Ȥδ�����ID���ѥ���ɤ��Ϥ��ޤ���
# ���Υ᥽�å���Ǥ�Wiki������̾�ΥХ�ǡ��������ʣ�����å��ϹԤ��ޤ���
# �����˹Ԥ�ɬ�פ�����ޤ������Υ᥽�åɤ�farm�ץ饰�������Ѥ��Ƥ�����Τ߻��Ѳ�ǽ�Ǥ���
# </p>
# <pre>
# $wiki-&gt;create_wiki(Wiki������̾,������ID,�ѥ����);
# </pre>
#==============================================================================
sub create_wiki{
	my $self  = shift;
	my $child = shift;
	my $id    = shift;
	my $pass  = shift;
	
	# data��backup�ǥ��쥯�ȥ�򷡤������Storage��Ǥ�����ۤ����������ʡ�
	unless($self->wiki_exists($child)){
		eval {
			# �����ǥ��ݡ��Ȥ���ǥ��쥯�ȥ�򷡤�
			mkpath($self->config('data_dir'  )."/$child") or die $!;
			mkpath($self->config('backup_dir')."/$child") or die $!;
			mkpath($self->config('config_dir')."/$child") or die $!;
			mkpath($self->config('log_dir'   )."/$child") or die $!;
			
			# ����Υ��ԡ�
			copy($self->config('config_dir')."/".$self->config('config_file'),
			     $self->config('config_dir')."/$child/".$self->config('config_file')) or die $!;
			copy($self->config('config_dir')."/".$self->config('usercss_file'),
			     $self->config('config_dir')."/$child/".$self->config('usercss_file')) or die $!;
			copy($self->config('config_dir')."/".$self->config('plugin_file'),
			     $self->config('config_dir')."/$child/".$self->config('plugin_file')) or die $!;
			copy($self->config('config_dir')."/".$self->config('mime_file'),
			     $self->config('config_dir')."/$child/".$self->config('mime_file')) or die $!;
			
			# �����桼���κ����ʤ����Ǻ��ΤϤ���äȥ��줫�⡦������
			open(USERDAT,">".$self->config('config_dir')."/$child/".$self->config('userdat_file')) or die $!;
			print USERDAT "$id=".&Util::md5($pass,$id)."\t0\n";
			close(USERDAT);
			
			# �ƥ�ץ졼�Ȥ���ڡ����Υ��ԡ�
			my $farm_config = &Util::load_config_hash($self,$self->config('farmconf_file'));
			if($farm_config->{'use_template'}==1 && $child ne "template"){
				my $template = $self->config('data_dir')."/template";
				my $depth = $self->_get_wiki_depth();
				my $count = 0;
				while((!(-e $template) || !(-d $template)) && $count < $depth && $farm_config->{'search_parent'}==1){
					$template =~ s/\/template$//;
					$template = $template."/../template";
					$count++;
				}
				if(-e $template && -d $template){
					opendir(DIR,$template) or die $!;
					while(my $entry = readdir(DIR)){
						if($entry =~ /\.wiki$/){
							copy($template."/$entry",$self->config('data_dir')."/$child/$entry");
						}
					}
					closedir(DIR);
				}
			}
			# create_wiki�եå��θƤӽФ�
			$self->do_hook("create_wiki");
		};
		
		# ���顼��ȯ��������祯�꡼�󥢥å׽���
		if($@){
			my $error = $@;
			# �����ϥ��顼���ФƤ�³��
			eval {
				$self->remove_wiki("/$child");
			};
			die "$child�κ����˼��Ԥ��ޤ�����ȯ���������顼�ϰʲ��ΤȤ���Ǥ���\n\n$error";
		}
	}
}

#==============================================================================
# <p>
# ���ߤ�Wiki�γ��ؤ��ֵѤ��ޤ����롼�Ȥξ���0����Wiki�ξ���1��
# ¹Wiki�ξ���2�ĤȤ����褦�ˤʤ�ޤ���
# </p>
#==============================================================================
sub _get_wiki_depth {
	my $self = shift;
	my $path_info = $self->get_CGI()->path_info();
	$path_info =~ s/^\///;
	my $depth = split(/\//,$path_info);
	return $depth;
}

#==============================================================================
# <p>
# ��Wiki�������ޤ��������ˤϺ������Wiki�����ȤΥѥ���PATH_INFO��ʬ�ˤ��Ϥ��ޤ���
# ���Υ᥽�åɤ�farm�ץ饰�������Ѥ��Ƥ�����Τ߻��Ѳ�ǽ�Ǥ���
# </p>
# <pre>
# $wiki-&gt;remove_wiki(Wiki�����ȤΥѥ�);
# </pre>
#==============================================================================
sub remove_wiki {
	my $self = shift;
	my $path = shift;
	
	# �����ǥ��ݡ��Ȥ���ǥ��쥯�ȥ����
	rmtree($self->config('data_dir'  ).$path) or die $!;
	rmtree($self->config('backup_dir').$path) or die $!;
	rmtree($self->config('config_dir').$path) or die $!;
	rmtree($self->config('log_dir'   ).$path) or die $!;
	
	# remove_wiki�եå��θƤӽФ�
	$self->get_CGI()->param('path',$path);
	$self->do_hook("remove_wiki");
}

#==============================================================================
# <p>
# �������Ϥ���̾�Τλ�Wiki��¸�ߤ��뤫�ɤ�����Ĵ�٤ޤ���
# ���Υ᥽�åɤ�farm�ץ饰�������Ѥ��Ƥ�����Τ߻��Ѳ�ǽ�Ǥ���
# </p>
# <pre>
# $wiki-&gt;wiki_exists(Wiki������̾);
# </pre>
#==============================================================================
sub wiki_exists{
	my $self  = shift;
	my $child = shift;
	return ($child =~ /[A-Za-z0-9]+(\/[A-Za-z0-9]+)*/
			and -d $self->config('data_dir')."/$child");
}

#==============================================================================
# <p>
# ��Wiki������Ǽ������ޤ���¹Wiki����¹Wiki������Υ�ե���󥹤Ȥ��Ƴ�Ǽ����Ƥ��ޤ���
# </p>
#==============================================================================
sub get_wiki_list{
	my $self = shift;
	if($self->farm_is_enable){
		my @list = $self->search_child($self->config('config_dir'));
		return @list;
	} else {
		return ();
	}
}

#==============================================================================
# <p>
# ��Wiki�Υĥ꡼������Ǽ������ޤ���
# �ͥ��Ȥ���Wiki�������ե���󥹤ǳ�Ǽ���ޤ���
# </p>
#==============================================================================
sub search_child {
	my $self = shift;
	my $dir  = shift;
	my @dirs = ();
	my @list = ();
	
	opendir(DIR,$dir) or die $!;
	while(my $entry = readdir(DIR)){
		if(-d "$dir/$entry" && $entry ne "." && $entry ne ".."){
			push(@dirs,$entry);
		}
	}
	closedir(DIR);
	@dirs = sort @dirs;
	
	foreach my $entry (@dirs){
		push(@list,$entry);
		my @child = $self->search_child("$dir/$entry");
		if($#child>-1){
			push(@list,\@child);
		}
	}
	
	return @list;
}

#==============================================================================
# <p>
# ��λ���ν�����
# </p>
#==============================================================================
sub _process_before_exit {
	my $self = shift;
	# �ץ饰�����ѤΥեå�
	$self->do_hook('finalize');
	# finalize�᥽�åɤθƤӽФ�
	$self->get_CGI()->finalize();
	$self->{storage}->finalize();
}

1;
