###############################################################################
#
# ���ѥ��к��������Ԥ����������ϥ�ɥ�
#
###############################################################################
package plugin::admin::AdminSpamHandler;
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
# ���������ϥ�ɥ�᥽�å�
#==============================================================================
sub do_action {
	my $self  = shift;
	my $wiki  = shift;
	my $cgi   = $wiki->get_CGI();
	
	$wiki->set_title("���ѥ��к�������");
	
	if($cgi->param("SAVE") ne ""){
		return $self->save_config($wiki);
	} else {
		return $self->config_form($wiki);
	}
}

#==============================================================================
# ����ե�����
#==============================================================================
sub config_form {
	my $self = shift;
	my $wiki = shift;
	my $spam = &Util::load_config_text($wiki,'spam.dat');
	my $spam_ip = &Util::load_config_text($wiki,'spam_ip.dat');
	my $rule = &Util::load_config_text($wiki,'spam_rules.dat');
	
	# �ƥ�ץ졼�Ȥ˥ѥ�᡼���򥻥å�
	my $tmpl = HTML::Template->new(filename=>$wiki->config('tmpl_dir')."/admin_spam.tmpl",
	                               die_on_bad_params => 0);
	$tmpl->param(
		SPAM_CONTENT => $spam,
		SPAM_IP      => $spam_ip
	);
	
	foreach my $line (split(/\n/, $rule)){
		chomp($line);
		$tmpl->param(
			$line => 1,
		);
	}
	
	return "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
	       $tmpl->output().
	       "<input type=\"hidden\" name=\"action\" value=\"ADMINSPAM\">\n".
	       "</form>\n";
}

#==============================================================================
# �������¸
#==============================================================================
sub save_config {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	my $spam = $cgi->param('spam');
	my $spam_ip = $cgi->param('spam_ip');
	my $rule = join("\n", $cgi->param('rules'));
	
	
	&Util::save_config_text($wiki,'spam.dat',$spam);
	&Util::save_config_text($wiki,'spam_ip.dat',$spam_ip);
	&Util::save_config_text($wiki,'spam_rules.dat',$rule);
	
	$wiki->redirectURL( $wiki->create_url({ action=>"ADMINSPAM"}) );
}

1;
