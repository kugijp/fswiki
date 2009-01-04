###############################################################################
#
# YukiWiki�ν񼰤򥵥ݡ��Ȥ���ե����ޥåȥץ饰����
#
###############################################################################
package plugin::format::YukiWikiFormat;
use base qw(plugin::format::FormatBase); 
use strict;
#==============================================================================
# FSWiki�ν񼰤��Ѵ����ޤ���
#==============================================================================
sub convert_to_fswiki_paragraph {
	my $self = shift;
	my $line = shift;
	
	if($line =~ /^\*\*\*/){
		return "!".$self->_convert_line(substr($line,3))."\n";
	} elsif($line =~ /^\*\*/){
		return "!!".$self->_convert_line(substr($line,2))."\n";
	} elsif($line =~ /^\*/){
		return "!!!".$self->_convert_line(substr($line,1))."\n";
	} elsif($line =~ /^----/){
		return "----\n";
	} elsif($line =~ /^---/){
		return "***".$self->_convert_line(substr($line,3))."\n";
	} elsif($line =~ /^--/){
		return "**".$self->_convert_line(substr($line,2))."\n";
	} elsif($line =~ /^-/){
		return "*".$self->_convert_line(substr($line,1))."\n";
	} elsif($line =~ /^>/){
		return "\"\"".$self->_convert_line(substr($line,1))."\n";
	} elsif($line =~ /^[ \t]/){
		return $line."\n";
	} else {
		return $self->_convert_line($line)."\n";
	}
}

#==============================================================================
# ����饤��񼰤�FSWiki�ν񼰤��Ѵ����ޤ���
#==============================================================================
sub convert_to_fswiki_line {
	my $self = shift;
	return $self->_convert_line(@_);
}

#==============================================================================
# ����饤��񼰤�YukiWiki�ν񼰤��Ѵ����ޤ���
#==============================================================================
sub convert_from_fswiki_line {
	my $self = shift;
	return $self->_convert_line(@_);
}

#==============================================================================
# ����ʬ�Υ���饤��񼰤��Ѵ����ޤ���'''��''�ˡ�''��'''���Ѵ��ˤ��ޤ���
#==============================================================================
sub _convert_line {
	my $self = shift;
	my $line = shift;
	my $buf  = "";
	
	if($line =~ /(''')(.+?)(''')/){
		my $pre   = $`;
		my $post  = $';
		my $label = $2;
		if($pre ne ""){ $buf .= $self->_convert_line($pre); }
		$buf .= "''$label''";
		if($post ne ""){ $buf .= $self->_convert_line($post); }
		
	} elsif($line =~ /('')(.+?)('')/){
		my $pre   = $`;
		my $post  = $';
		my $label = $2;
		if($pre ne ""){ $buf .= $self->_convert_line($pre); }
		$buf .= "'''$label'''";
		if($post ne ""){ $buf .= $self->_convert_line($post); }
	} else {
		$buf .= $line;
	}
	return $buf;
}

#==============================================================================
# FSWiki�ν񼰤����Ѵ����ޤ���
#==============================================================================
sub convert_from_fswiki_paragraph {
	my $self = shift;
	my $line = shift;
	
	if($line =~ /^!!!/){
		return "*".$self->_convert_line(substr($line,3))."\n";
	} elsif($line =~ /^!!/){
		return "**".$self->_convert_line(substr($line,2))."\n";
	} elsif($line =~ /^!/){
		return "***".$self->_convert_line(substr($line,1))."\n";
	} elsif($line eq "----"){
		return "----\n";
	} elsif($line =~ /^\*\*\*/){
		return "---".$self->_convert_line(substr($line,3))."\n";
	} elsif($line =~ /^\*\*/){
		return "--".$self->_convert_line(substr($line,2))."\n";
	} elsif($line =~ /^\*/){
		return "-".$self->_convert_line(substr($line,1))."\n";
	} elsif($line =~ /^""/){
		return ">".$self->_convert_line(substr($line,2))."\n";
	} elsif($line =~ /^[ \t]/){
		return $line."\n";
	} else {
		return $self->_convert_line($line)."\n";
	}
}

1;
