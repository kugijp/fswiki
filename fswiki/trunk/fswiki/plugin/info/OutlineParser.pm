###############################################################################
#
# �����ȥ饤��ѡ���
#
###############################################################################
package plugin::info::OutlineParser;
use strict;
use vars qw(@ISA);
use Wiki::HTMLParser;

@ISA = qw(Wiki::HTMLParser);

#==============================================================================
# ���󥹥ȥ饯��
#==============================================================================
sub new {
	my $class = shift;
	my $self  = Wiki::HTMLParser->new(shift);
	$self->{outline_html}  = "";
	$self->{outline_level} =  0;
	$self->{outline_cnt}   =  0;
	return bless $self,$class;
}

#==============================================================================
# �إåɥ饤��Τ����
#==============================================================================
sub l_headline {
	my $self  = shift;
	my $level = shift;
	my $obj   = shift;
	my $text  = &Util::delete_tag(join("",@$obj));
	
	if($level > $self->{outline_level}){
		while($level!=$self->{outline_level}){
			if($self->{'outline_close_'.($self->{outline_level})} == 1){
				$self->{outline_html} .= "</li>\n";
				$self->{'outline_close_'.($self->{outline_level})} = 0;
			}
			$self->{outline_html} .= "<ul class=\"outline\">\n";
			$self->{outline_level}++;
		}
	} elsif($level <= $self->{outline_level}){
		while($level-1  != $self->{outline_level}){
			if($self->{'outline_close_'.($self->{outline_level})} == 1){
				$self->{outline_html} .= "</li>\n";
				$self->{'outline_close_'.($self->{outline_level})} = 0;
			}
			if($level == $self->{outline_level}){
				last;
			}
			$self->{outline_html} .= "</ul>\n";
			$self->{outline_level}--;
		}
	} else {
		$self->{outline_html} .= "</li>\n";
	}
	
	$self->{'outline_close_'.$level} = 1;
	$self->{outline_html} .= "<li><a href=\"#p".$self->{outline_cnt}."\">$text</a>";
	$self->{outline_cnt}++;
}

#==============================================================================
# �����ȥ饤��ɽ����HTML�μ���
#==============================================================================
sub outline {
	my $self   = shift;
	my $source = shift;
	$self->parse($source);
	
	while($self->{outline_level} != 0){
		if($self->{'outline_close_'.($self->{outline_level})} == 1){
			$self->{outline_html} .= "</li>\n";
		}
		$self->{outline_html} .= "</ul>\n";
		$self->{outline_level}--;
	}
	
	return $self->{outline_html};
}

#==============================================================================
# �ץ饰����β��Ϥ�Ԥ���̵�¥롼�פ��Ƥ��ޤ�����
#==============================================================================
sub plugin{}

#==============================================================================
# �ץ饰����β��Ϥ�Ԥ���̵�¥롼�פ��Ƥ��ޤ�����
#==============================================================================
sub l_plugin{
	my $self   = shift;
	my $plugin = shift;
	
	# outline�ʳ��ξ��Τ߽�����Ԥ�
	if($plugin->{command} ne "outline"){
		my $info = $self->{wiki}->get_plugin_info($plugin->{command});
		if($info->{FORMAT} eq "WIKI"){
			return $self->SUPER::l_plugin($plugin);
		}
		
	} else {
		return undef;
	}
}

1;
