###############################################################################
#
# �ץ饰����������Ԥ����������ϥ�ɥ�
#
###############################################################################
package plugin::admin::AdminPluginHandler;
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
	my $cgi   = $wiki->get_CGI;
	
	$wiki->set_title("�ץ饰��������");
	
	if($cgi->param("SAVE") ne ""){
		return $self->save_plugin_config($wiki);
	} else {
		return $self->plugin_config_form($wiki);
	}
}

sub plugin_config_form {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my @plugins = split(/\n/,&Util::load_config_text($wiki,$wiki->config('plugin_file')));
	
	my $buf = "<h2>�ץ饰���������</h2>\n".
	          "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
	          "<table>\n".
	          "<tr><th><br></th><th>�ץ饰����</th><th>����</th></tr>\n";
	          
	foreach(sort($self->list_plugins($wiki))){
		$buf .= "<tr>";
		$buf .= "<td><input type=\"checkbox\" name=\"plugin\" value=\"".Util::escapeHTML($_)."\"";
		foreach my $plugin (@plugins){
			if($_ eq $plugin){ $buf .= " checked"; }
		}
		$buf .= "></td>";
		
		$buf .= "<td>".Util::escapeHTML($_)."</td>";
		$buf .= "<td>".$self->get_decription($wiki,$_)."</td>";
		$buf .= "</tr>";
	}
	
	$buf .= "</table>\n".
	        "<input type=\"submit\" name=\"SAVE\" value=\" �� ¸ \">\n".
	        "<input type=\"reset\" value=\"�ꥻ�å�\">\n".
	        "<input type=\"hidden\" name=\"action\" value=\"ADMINPLUGIN\">\n".
	        "</form>\n";
	
	return $buf;
}

#==============================================================================
# �������¸
#==============================================================================
sub save_plugin_config {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my @plugins = $cgi->param("plugin");
	
	&Util::save_config_text($wiki,$wiki->config('plugin_file'),join("\n",@plugins));

	return $wiki->redirectURL( $wiki->create_url({action=>"ADMINPLUGIN"}) );
	#return "�������¸���ޤ�����";
}

#==============================================================================
# �ץ饰����ΰ������������ؿ�
#==============================================================================
sub list_plugins {
	my $self = shift;
	my $wiki = shift;
	my @list;
	opendir(DIR,$wiki->config('plugin_dir')."/plugin") or die $!;
	while(my $entry = readdir(DIR)){
		my $path = $wiki->config('plugin_dir')."/plugin/$entry";
		if(-d $path && $entry ne "." && $entry ne ".."){
			if(-e "$path/Install.pm"){
				push(@list,$entry);
			}
		}
	}
	closedir(DIR);
	
	@list = sort(@list);
	return @list;
}

#==============================================================================
# Install.pm�Υ����Ȥ����
#==============================================================================
sub get_decription {
	my $self = shift;
	my $wiki = shift;
	my $plugin = shift;
	open(DATA,$wiki->config('plugin_dir')."/plugin/$plugin/Install.pm") or return "<br>";
	my $flag    = 0;
	my $comment = "";
	while(<DATA>){
		if(!/^#/ || /^##/){
			if($flag==0){ next; } else { last; }
		}
		$flag = 1;
		s/\#+//;
		s/\={2,}//;
		s/^\s+//; s/\s+$//;
		if($_ ne ""){
			$comment .= $_."\n";
		}
	}
	close(DATA);
	return $comment;
}

1;
