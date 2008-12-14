###############################################################################
#
# WalWiki�ν񼰤򥵥ݡ��Ȥ���ե����ޥåȥץ饰����
#
###############################################################################
package plugin::format::WalWikiFormat;
use base qw(plugin::format::FormatBase); 
use strict;
#==============================================================================
# FSWiki�ν񼰤��Ѵ����ޤ���
#==============================================================================
sub convert_to_fswiki_paragraph {
	my $self = shift;
	my $line = shift;
	
	if($line =~ /^\*\*\*/){
		return "!".$self->convert_to_fswiki_line(substr($line,3))."\n";
	} elsif($line =~ /^\*\*/){
		return "!!".$self->convert_to_fswiki_line(substr($line,2))."\n";
	} elsif($line =~ /^\*/){
		return "!!!".$self->convert_to_fswiki_line(substr($line,1))."\n";
	} elsif($line =~ /^----/){
		return "----\n";
	} elsif($line =~ /^---/){
		return "***".$self->convert_to_fswiki_line(substr($line,3))."\n";
	} elsif($line =~ /^--/){
		return "**".$self->convert_to_fswiki_line(substr($line,2))."\n";
	} elsif($line =~ /^-/){
		return "*".$self->convert_to_fswiki_line(substr($line,1))."\n";
	} elsif($line =~ /^>/){
		return "\"\"".$self->convert_to_fswiki_line(substr($line,1))."\n";
	} elsif($line =~ /^[ \t]/){
		return $line."\n";
	} else {
		return $self->convert_to_fswiki_line($line)."\n";
	}
}

#==============================================================================
# ����饤��񼰤�FSWiki�ν񼰤��Ѵ����ޤ���
#==============================================================================
sub convert_to_fswiki_line {
	my $self = shift;
	my $line = shift;
	my $buf  = "";
	
	if($line =~ /(''')(.+?)(''')/){
		my $pre   = $`;
		my $post  = $';
		my $label = $2;
		if($pre ne ""){ $buf .= $self->convert_to_fswiki_line($pre); }
		$buf .= "''$label''";
		if($post ne ""){ $buf .= $self->convert_to_fswiki_line($post); }
		
	} elsif($line =~ /('')(.+?)('')/){
		my $pre   = $`;
		my $post  = $';
		my $label = $2;
		if($pre ne ""){ $buf .= $self->convert_to_fswiki_line($pre); }
		$buf .= "'''$label'''";
		if($post ne ""){ $buf .= $self->convert_to_fswiki_line($post); }
		
	} elsif($line =~ /(\[\[)([^ ]+?)(\]\])/){
		my $pre   = $`;
		my $post  = $';
		my $label = $2;
		if($pre ne ""){ $buf .= $self->convert_to_fswiki_line($pre); }
		$buf .= "[[$label]]";
		if($post ne ""){ $buf .= $self->convert_to_fswiki_line($post); }
		
	} elsif($line =~ /(\[\[)([^\[]+?) ((?:\w+:\/\/|mailto:)[^ ]+?)(\]\])/){
		my $pre   = $`;
		my $post  = $';
		my $label1 = $2;
		my $label2 = $3;
		if($pre ne ""){ $buf .= $self->convert_to_fswiki_line($pre); }
		$buf .= "[$label1|$label2]";
		if($post ne ""){ $buf .= $self->convert_to_fswiki_line($post); }
		
	} elsif($line =~ /(\[\[)(.+?) ([^ ]+?)(\]\])/){
		my $pre   = $`;
		my $post  = $';
		my $label1 = $2;
		my $label2 = $3;
		if($pre ne ""){ $buf .= $self->convert_to_fswiki_line($pre); }
		$buf .= "[[$label1|$label2]]";
		if($post ne ""){ $buf .= $self->convert_to_fswiki_line($post); }
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
		return "*".$self->convert_from_fswiki_line(substr($line,3))."\n";
	} elsif($line =~ /^!!/){
		return "**".$self->convert_from_fswiki_line(substr($line,2))."\n";
	} elsif($line =~ /^!/){
		return "***".$self->convert_from_fswiki_line(substr($line,1))."\n";
	} elsif($line eq "----"){
		return "----\n";
	} elsif($line =~ /^\*\*\*/){
		return "---".$self->convert_from_fswiki_line(substr($line,3))."\n";
	} elsif($line =~ /^\*\*/){
		return "--".$self->convert_from_fswiki_line(substr($line,2))."\n";
	} elsif($line =~ /^\*/){
		return "-".$self->convert_from_fswiki_line(substr($line,1))."\n";
	} elsif($line =~ /^""/){
		return ">".$self->convert_from_fswiki_line(substr($line,2))."\n";
	} elsif($line =~ /^[ \t]/){
		return $line."\n";
	} else {
		return $self->convert_from_fswiki_line($line)."\n";
	}
}

#==============================================================================
# ����饤��񼰤�WalWiki�ν񼰤��Ѵ����ޤ���
#==============================================================================
sub convert_from_fswiki_line {
	my $self = shift;
	my $line = shift;
	my $buf  = "";
	
	if($line =~ /(''')(.+?)(''')/){
		my $pre   = $`;
		my $post  = $';
		my $label = $2;
		if($pre ne ""){ $buf .= $self->convert_from_fswiki_line($pre); }
		$buf .= "''$label''";
		if($post ne ""){ $buf .= $self->convert_from_fswiki_line($post); }
		
	} elsif($line =~ /('')(.+?)('')/){
		my $pre   = $`;
		my $post  = $';
		my $label = $2;
		if($pre ne ""){ $buf .= $self->convert_from_fswiki_line($pre); }
		$buf .= "'''$label'''";
		if($post ne ""){ $buf .= $self->convert_from_fswiki_line($post); }
		
	} elsif($line =~ /(\[)([^\[]+?)\|((?:\w+:\/\/|mailto:)[^\]]+?)(\])/){
		my $pre   = $`;
		my $post  = $';
		my $label1 = $2;
		my $label2 = $3;
		if($pre ne ""){ $buf .= $self->convert_from_fswiki_line($pre); }
		$buf .= "[[$label1 $label2]]";
		if($post ne ""){ $buf .= $self->convert_from_fswiki_line($post); }
		
	} elsif($line =~ /(\[\[)([^\|]+?)\|([^\|]+?)(\]\])/){
		my $pre   = $`;
		my $post  = $';
		my $label1 = $2;
		my $label2 = $3;
		if($pre ne ""){ $buf .= $self->convert_from_fswiki_line($pre); }
		$buf .= "[[$label1 $label2]]";
		if($post ne ""){ $buf .= $self->convert_from_fswiki_line($post); }
		
	} else {
		$buf .= $line;
	}
	return $buf;
}

1;
