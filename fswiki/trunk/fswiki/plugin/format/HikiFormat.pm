###############################################################################
#
# Hiki�ν񼰤򥵥ݡ��Ȥ���ե����ޥåȥץ饰����
#
###############################################################################
package plugin::format::HikiFormat;
use base qw(plugin::format::FormatBase); 
use strict;
#==============================================================================
# FSWiki�ν񼰤��Ѵ����ޤ���
#==============================================================================
sub convert_to_fswiki_paragraph {
	my $self = shift;
	my $line = shift;
	
	if($line =~ /^!!!/){
		return "!".$self->convert_to_fswiki_line(substr($line,3))."\n";
	} elsif($line =~ /^!!/){
		return "!!".$self->convert_to_fswiki_line(substr($line,2))."\n";
	} elsif($line =~ /^!/){
		return "!!!".$self->convert_to_fswiki_line(substr($line,1))."\n";
	} elsif($line =~ /^###/){
		return "+++".$self->convert_to_fswiki_line(substr($line,3))."\n";
	} elsif($line =~ /^##/){
		return "++".$self->convert_to_fswiki_line(substr($line,2))."\n";
	} elsif($line =~ /^#/){
		return "+".$self->convert_to_fswiki_line(substr($line,1))."\n";
	} elsif($line =~ /^\|\|/){
		my @words = split(/\|\|/,$line);
		my $buf = '';
		foreach my $word (@words){
			if($word ne ""){
				$buf .= ",".$self->convert_to_fswiki_line($word);
			}
		}
		return $buf."\n";
	} elsif($line =~ /^[ \t]/){
		return $line."\n";
	} else {
		return $self->convert_to_fswiki_line($line)."\n";
	}
}

#==============================================================================
# ����饤��񼰤�Hiki��FSWiki�ե����ޥåȤ��Ѵ����ޤ���
#==============================================================================
sub convert_to_fswiki_line {
	my $self = shift;
	my $line = shift;
	my $buf  = "";
	
	# ��̾���
	if($line =~ /\[\[([^\[]+?)\|((http|https|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!\$&=:;\*#\@']*)\]\]/
	    ||  $line =~ /\[\[([^\[]+?)\|(file:[^\[\]]*)\]\]/
	    ||  $line =~ /\[\[([^\[]+?)\|((\/|\.\/|\.\.\/)+[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!\$&=:;\*#\@']*)\]\]/){
		my $pre   = $`;
		my $post  = $';
		my $label = $1;
		my $url   = $2;
		if($pre ne ""){ $buf .= $self->convert_to_fswiki_line($pre); }
		$buf .= "[$label|$url]";
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
		return "!".$self->convert_from_fswiki_line(substr($line,3))."\n";
	} elsif($line =~ /^!!/){
		return "!!".$self->convert_from_fswiki_line(substr($line,2))."\n";
	} elsif($line =~ /^!/){
		return "!!!".$self->convert_from_fswiki_line(substr($line,1))."\n";
	} elsif($line =~ /^\+\+\+/){
		return "###".$self->convert_from_fswiki_line(substr($line,3))."\n";
	} elsif($line =~ /^\+\+/){
		return "##".$self->convert_from_fswiki_line(substr($line,2))."\n";
	} elsif($line =~ /^\+/){
		return "#".$self->convert_from_fswiki_line(substr($line,1))."\n";
	} elsif($line =~ /^,/){
		my @words = map {/^"(.*)"$/ ? scalar($_ = $1, s/""/"/g, $_) : $_}
		                ($line =~ /,\s*("[^"]*(?:""[^"]*)*"|[^,]*)/g);
		my $buf = '';
		foreach my $word (@words){
			if($word ne ""){
				$buf .= "||".$self->convert_from_fswiki_line($word);
			}
		}
		return $buf."||\n";
	} elsif($line =~ /^[ \t]/){
		return $line."\n";
	} else {
		return $self->convert_from_fswiki_line($line)."\n";
	}
}

#==============================================================================
# ����饤��񼰤�FSWiki��Hiki�ե����ޥåȤ��Ѵ����ޤ���
#==============================================================================
sub convert_from_fswiki_line {
	my $self = shift;
	my $line = shift;
	my $buf  = "";
	
	# ��̾���
	if($line =~ /\[([^\[]+?)\|((http|https|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!\$&=:;\*#\@']*)\]/
	    ||  $line =~ /\[([^\[]+?)\|(file:[^\[\]]*)\]/
	    ||  $line =~ /\[([^\[]+?)\|((\/|\.\/|\.\.\/)+[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!\$&=:;\*#\@']*)\]/){
		my $pre   = $`;
		my $post  = $';
		my $label = $1;
		my $url   = $2;
		if($pre ne ""){ $buf .= $self->convert_from_fswiki_line($pre); }
		$buf .= "[[$label|$url]]";
		if($post ne ""){ $buf .= $self->convert_from_fswiki_line($post); }
		
	# �ڡ�����̾���
	} elsif($line =~ /\[\[([^\[]+?)\|(.+?)\]\]/){
		my $pre   = $`;
		my $post  = $';
		my $label = $1;
		my $page  = $2;
		if($pre ne ""){ $buf .= $self->convert_from_fswiki_line($pre); }
		$buf .= "[[$label|$page]]";
		if($post ne ""){ $buf .= $self->convert_from_fswiki_line($post); }
		
	} else {
		$buf .= $line;
	}
	return $buf;
}

1;
