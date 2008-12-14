################################################################################
#
# �ե����ޥåȥץ饰����δ��쥯�饹��
#
################################################################################
package plugin::format::FormatBase;
#===============================================================================
# ���󥹥ȥ饯��
#===============================================================================
sub new {
	my $class = shift;
	my $self  = {};
	return bless $self,$class;	
}

#===============================================================================
# FSWiki�ν񼰤��Ѵ�
#===============================================================================
sub convert_to_fswiki {
	my $self   = shift;
	my $source = shift;
	
	my @lines  = split(/\n/,$source);
	my $buf    = "";
	
	$self->{block_level} = 0;
	foreach my $line (@lines){
		if($line =~ /^{{.+}}$/){
			$buf .= $line."\n";
			next;
		} elsif($line =~ /^{{.+$/){
			$self->{block_level}++;
			$buf .= $line."\n";
			next;
		} elsif($self->{block_level} > 0){
			if($line eq "}}"){
				$self->{block_level}--;
			}
			$buf .= $line."\n";
			next;
		}
	
		$buf .= $self->convert_to_fswiki_paragraph($line);
	}
	return $buf;
}

#===============================================================================
# FSWiki�ν񼰤����Ѵ�
#===============================================================================
sub convert_from_fswiki {
	my $self   = shift;
	my $source = shift;
	
	my @lines  = split(/\n/,$source);
	my $buf    = "";
	
	$self->{block_level} = 0;
	foreach my $line (@lines){
		if($line =~ /^{{.+}}$/){
			$buf .= $line."\n";
			next;
		} elsif($line =~ /^{{.+$/){
			$self->{block_level}++;
			$buf .= $line."\n";
			next;
		} elsif($self->{block_level} > 0){
			if($line eq "}}"){
				$self->{block_level}--;
			}
			$buf .= $line."\n";
			next;
		}
	
		$buf .= $self->convert_from_fswiki_paragraph($line);
	}
	return $buf;
}

1;
