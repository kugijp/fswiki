package CGI::Session::ID::MD5;

# $Id: MD5.pm,v 1.1.1.1 2003/08/02 23:39:35 takezoe Exp $

use strict;
use Digest::Perl::MD5;
use vars qw($VERSION);

($VERSION) = '$Revision: 1.1.1.1 $' =~ m/Revision:\s*(\S+)/;

sub generate_id {
    my $self = shift;

    my $md5 = new Digest::Perl::MD5();
    $md5->add($$ , time() , rand(9999) );

    return $md5->hexdigest();
}


1;

=pod

=head1 NAME

CGI::Session::ID::MD5 - default CGI::Session ID driver

=head1 SYNOPSIS

    use CGI::Session qw/-api3/;

    $session = new CGI::Session("id:MD5", undef,
                            {   Directory   => '/tmp',
                                IDFile      => '/tmp/cgisession.id',
                                IDInit      => 1000,
                                IDIncr      => 2 });

=head1 DESCRIPTION

CGI::Session::ID::MD5 is to generate MD5 encoded hexidecimal random ids.
The library does not require any arguments. 

=head1 COPYRIGHT

Copyright (C) 2002 Sherzod Ruzmetov. All rights reserved.

This library is free software. You can modify and distribute it under the same terms as Perl itself.

=head1 AUTHOR

Sherzod Ruzmetov <sherzodr@cpan.org>

Feedbacks, suggestions and patches are welcome.

=head1 SEE ALSO

=over 4

=item *

L<Incr|CGI::Session::ID::Incr> - Auto Incremental ID generator

=item *

L<CGI::Session|CGI::Session> - CGI::Session manual

=item *

L<CGI::Session::Tutorial|CGI::Session::Tutorial> - extended CGI::Session manual

=item *

L<CGI::Session::CookBook|CGI::Session::CookBook> - practical solutions for real life problems

=item *

B<RFC 2965> - "HTTP State Management Mechanism" found at ftp://ftp.isi.edu/in-notes/rfc2965.txt

=item *

L<CGI|CGI> - standard CGI library

=item *

L<Apache::Session|Apache::Session> - another fine alternative to CGI::Session

=back

=cut
