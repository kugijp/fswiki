# $Id: Tutorial.pm,v 1.1.1.1 2003/08/02 23:39:35 takezoe Exp $

package CGI::Session::Tutorial;

use vars ('$VERSION');

($VERSION) = '$Revision: 1.1.1.1 $' =~ m/Revision:\s*(\S+)/

1;

__END__;

=pod

=head1 NAME

Tutorial - extended CGI::Session manual

=head1 STATE MAINTANANCE OVERVIEW

Since HTTP is a stateless protocol, each subsequent click to a web site is treated as new by the web server. The server does not relate the visits with previous one, thus all the state information from the previous requests are lost. This makes creating such applications as shopping carts, login/authentication routines, secure restricted services in the web impossible. So people had to do something against this despair situation HTTP was putting us in.

For our rescue come such technologies as HTTP Cookies and QUERY_STRINGs that help us save the users' session for a certain period. Since cookies and query_strings alone cannot take us too far B<RFC 2965, Section 5, "Implementation Limitations">, several other libraries/technologies have been developed to extend their capabilities and promise a more reliable and a more persistent system. CGI::Session is one of them.

Before we discuss this library, let's look at some alternative solutions.

=head2 COOOKIE

Cookie is a piece of text-information that a web server is entitled to place in the user's hard disk, assuming a user agent (i.e.. Web Browser) is compatible with the specification. After the cookie being placed, user agents are required to send these cookies back to the server as part of the HTTP request. This way the server application ( CGI ) will have a way of relating previous requests by the same user agent, thus overcoming statelessness of HTTP.

Although cookies seem to be promising solutions for the statelessness of HTTP, they do carry certain limitations, such as limited number of cookies per domain and per user agent and limited size on each cookie. User Agents are required to store at least 300 cookies at a time, 20 cookies per domain and allow 4096 bytes of storage for each cookie. They also rise several Privacy and Security concerns, the lists of which can be found on the sections 6-B<"Privacy"  and 7-"Security Considerations"> of B<RFC 2965> respectively.

=head2 QUERY STRING

Query string is a string appended to URL following a question mark (?) such as:

    http://my.dot.com/login.cgi?user=sherzodr&password=topSecret

As you probably guessed already, it can also help you to pass state information from a click to another, but how secure is it do you think? Considering these URLs tend to get cached by most of the user agents and also logged in the servers access log, to which everyone can have access to, it is not secure.

=head2 HIDDEN FIELDS

Hidden field is another alternative to using query strings and they come in two flavors: hidden fields used in POST methods and the ones in GET. The ones used in GET methods will turn into a true query string once submitted, so all the disadvantages of QUERY_STRINGs do apply. Although POST requests do not have limitations of its sister-GET, the pages that hold them do the cached by web browser, and are available within the source code of the page (obviously). They also become unwieldily to manage when one has oodles of state information to keep track of ( for instance, a shopping cart or an advanced search engine).

Query strings and hidden fields are also lost easily by closing the browser, or by clicking the browser's "Back" button.

=head2 SERVER SIDE SESSION MANAGEMENT

This technique is built upon the aforementioned technologies plus a server-side storage device, which saves the state data for a particular session. Each session has a unique id associated with the data in the server. This id is also associated with the user agent in either the form of a cookie, a query_string parameter, a hidden field or all at the same time.

Advantages:

=over 4

=item *

We no longer need to depend on the User Agent constraints in cookie amounts and sizes

=item *

Sensitive data like user's username, email address, preferences and such no longer need to be traveling across the network at each request (which is the case with query strings, cookies and hidden_fields). Only thing that travels across the network is the unique id generated for the session ("ID-1234", for instance), which should make no sense to bad guys whatsoever.

=item *

User will not have sensitive data stored in his computer in an unsecured plain text format (which is a cookie file).

=item *

It's possible to handle very big and even complex (in-memory) data structures transparently.

=back

That's what CGI::Session is all about - implementing server side session management. Now is a very good time to get the feet wet.

=head1 PROGRAMMING STYLE

Server side session management system might be seeming awfully convoluted if you have never dealt with it.  Fortunately, with CGI::Session this cumbersome task can be achieved in much elegent way, all the complexity being handled by the library transparently. This section of the manual can be treated as an introductory tutorial to  both logic behind session management, and to CGI::Session programming style.

=head1 WHAT YOU NEED TO KNOW FIRST

Before you start using the library, you will need to decide where and how you want the session data to be stored in disk. In other words, you will need to tell what driver to use. You can choose either of "File", "DB_File" and "MySQL" drivers, which are shipped with the distribution by default. Examples in this document will be using "File" driver exclusively to make sure the examples are accessible in all machines with the least requirements. To do this, we create the session object like so:

    use CGI::Session;
    $session = new CGI::Session("driver:File", $cgi, {Directory=>'/tmp'});

The first argument is called Data Source Name (DSN in short). If it's undef, the library will use the default driver, which is "File". So instead of being explicit about the driver as in the above example, we could simply say:

    $session = new CGI::Session(undef, $cgi, {Directory=>'/tmp'});

and we're guaranteed it will fall back to default settings.

The second argument is session id to be initialized. If it's undef, it will force CGI::Session to create a new session. Instead of passing a session id, you can also pass a CGI.pm object, or any other object that can implement either of cookie() or param() methods. In this case, the library will try to retrieve the session id from either B<CGISESSID> cookie or B<CGISESSID> CGI parameter (query string)

The third argument should be in the form of hashref. This will be used by specific CGI::Session driver only. For the list of all the available attributes, consult respective CGI::Session driver. If you want to write a code
which is expected to run in various operating systems, and want to reference that particular system's
temporary folder, use tmpdir() method documented in File::Spec:

	$session = new CGI::Session(undef, $cgi, {Directory=>File::Spec->tmpdir});

Following drivers are available:

=over 4

=item *

L<File|CGI::Session::File> - default driver for storing session data in plain files. Full name: B<CGI::Session::File>

=item *

L<DB_File|CGI::Session::DB_File> - for storing session data in BerkelyDB. Requires: L<DB_File>. Full name: B<CGI::Session::DB_File>

=item *

L<MySQL|CGI::Session::MySQL> - for storing session data in MySQL tables. Requires L<DBI|DBI> and L<DBD::mysql|DBD::mysql>. Full name: B<CGI::Session::MySQL>

=back

Note: You can also write your own driver for the library. Consult respective
section of this manual for details.

=head1 CREATING NEW SESSION

To generate a brand new session for a user, just pass an undefined value as the second argument to the constructor - new():

    $session = new CGI::Session("driver:File", undef, {Directory=>"/tmp"});

Directory refers to a place where the session files and their locks will be stored in the form of separate files. When you generate the session object, as we did above, you will have:

=over 4

=item 1

Session ID generated for you and

=item 2

Storage file associated with the id in the directory you specified.

=back

From now on, in case you want to access the newly generated session id just do:

    $sid = $session->id();

It returns a string something similar to B<a983c8302e7a678a2e53c65e8bd3316> which you can now send as a cookie or use as a query string or in your forms' hidden fields. Using standard L<CGI> library we can send the session id as a cookie to the user's browser like so:

    $cookie = $cgi->cookie(CGISESSID => $session->id);
    print $cgi->header( -cookie=>$cookie );

If anything in the above example doesn't make sense, please consult L<CGI> for the details.

=head2 INITIALIZING EXISTING SESSIONS

When a user clicks another link or re-visits the site after a short while should we be creating a new session again? Absolutely not. This would defeat the whole purpose of state maintenance. Since we already send the id as a cookie, all we need is to pass that id as the seconds argument while creating a session object:

    $sid = $cgi->cookie("CGISESSID") || undef;
    $session    = new CGI::Session(undef, $sid, {Directory=>'/tmp'});

The above syntax will first try to initialize an existing session data, if it fails ( if the session doesn't exist ) creates a new session: just what we want. But what if the user doesn't support cookies? In that case we would need to append the session id to all the urls as a query string, and look for them in addition to cookie:

    $sid = $cgi->cookie('CGISESSID') || $cgi->param('CGISESSID') || undef;
    $session = new CGI::Session(undef, $sid, {Directory=>'/tmp'});

Assuming you have CGI object handy, you can minimize the above two lines into one:

    $session = new CGI::Session(undef, $cgi, {Directory=>"/tmp"});

If you pass an object, instead of a string as the second argument, as we did above, CGI::Session will try to retrieve the session id from either the cookie or query string and initialize the session accordingly. Name of the cookie and query string parameters are assumed to be B<CGISESSID> by default. To change this setting, you will need to invoke C<name()> class method on either CGI::Session or its object:

    CGI::Session->name("MY_SID");
    # or
    $session->name("MY_SID");

    $session = new CGI::Session(undef, $cgi, {Directory=>'/tmp'});

=head2 STORING DATA IN THE SESSION

To store a single variable in the object use C<param()> method:

    $session->param("my_name", $name);

You can use C<param()> method to store complex data such as arrays, hashes, objects and so forth. While storing arrays and hashes, make sure to pass them as a reference:

    @my_array = ("apple", "grapes", "melon", "casaba");
    $session->param("fruits", \@my_array);

You can store objects as well:

    $session->param("cgi", $cgi);   # stores CGI.pm object

Sometimes you wish there was a way of storing all the CGI parameters in the session object. You would start dreaming of this feature after having to save dozens of query parameters from each form element to your session object. Consider the following syntax:

    $session->save_param($cgi, ["keyword", "category", "author", "orderby"]);

save_param() makes sure that all the above CGI parameters get saved in the session object. It's the same as saying:

    $session->param("keyword",  $cgi->param("keyword"));
    $session->param("category", $cgi->param("category"));
    # etc... for all the form elements

In case you want to save all the CGI parameters. Just omit the second argument to C<save_param()>:

    $session->save_param($cgi);

The above syntax saves all the available/accessible CGI parameters

=head2 ACCESSING STORED DATA

There's no point of storing data if you cannot access it. You can access stored session data by using the same C<param()> method you once used to store them:

    $name = $session->param("my_name");

Above form of param() retrieves session parameter previously stored as "my_name". To retrieve previously stored @my_array:

    $my_array = $session->param("fruits");

It will return a reference to the array, and can be dereferenced as @{$my_array}.

Very frequently, you may find yourself having to create a pre-filled and pre-selected forms, like radio buttons, checkboxes and drop down menus according to the user's preferences or previous action. With text and textareas it's not a big deal: you can simply retrieve a single parameter from the session and hardcode the value into the text field. But how would you do it when you have a group of radio buttons, checkboxes and scrolling lists? For this purpose, CGI::Session provides load_param() method, which loads given session parameters to a CGI object (assuming they have been previously saved with save_param() method or alternative):

    $session->load_param($cgi, ["fruits"]);

Now you can use CGI.pm to generate those preselected checkboxes:

    print $cgi->checkbox_group(fruits=>['apple', 'banana', 'appricot']);

If you're making use of HTML::Template to separate the code from the skins, you can as well associate CGI::Session object with HTML::Template and access all the parameters from within HTML files. We love this trick!

    $template = new HTML::Template(filename=>"some.tmpl", associate=>$session);
    print $template->output();

Assuming the session object stored "first_name" and "email" parameters while being associated with HTML::Template, you can access those values from within your "some.tmpl" file now:

    Hello <a href="mailto:<TMPL_VAR email>"> <TMPL_VAR first_name> </a>!

For more tricks with HTML::Template, please refer to the library's manual (L<HTML::Template>) and L<CGI Session CookBook|CGI::Session::CookBook>.

=head2 CLOSING THE SESSION

Normally you don't have to close the session explicitly. It gets closed when your program terminates or session object goes out of scope. However in some few instances you might want to close the session explicitly by calling CGI::Session's C<close()> method or undefining the object. What is closing all about - you'd ask. While session is active, updates to session object doesn't get stored in the disk right away. It stores them in the memory until you either choose to flush the buffer by calling C<flush()> method or destroy the session object by either terminating the program or calling close() method explicitly.

In some circumstances you might want to close the session but at the same time don't want to terminate the process for a while. Might be the case with GUI and in daemon applications. In this case close() is what you want. Note: we prefer simpl undefing the session rather than calling close() method. close() is less efficient):

    undef($session);

If you want to keep the session object but for any reason want to synchronize the data in the buffer with the one in the disk, C<flush()> method is what you need.

Note: close() calls flush() as well. So there's no need to call flush() before calling close()

=head2 CLEARING SESSION DATA

You store session data, you access session data and at some point you will want to clear certain session data, if not all. For this purpose CGI::Session provides C<clear()> method which optionally takes one argument as an arrayref indicating which session parameters should be deleted from the session object:

    $session->clear(["~logged-in", "email"]);

Above line deletes "~logged-in" and "email" session parameters from the session. And next time you say:

    $email = $session->param("email");

it returns undef. If you omit the argument to C<clear()>, be warned that all the session parameters you ever stored in the session object will get deleted. Note that it does not delete the session itself. Session stays open and accessible. It's just the parameters you stored in it gets deleted

=head2 DELETING A SESSION

If there's a start there's an end. If session could be created, it should be possible to delete it from the disk for good:

    $session->delete();

The above call to C<delete()> deletes the session from the disk for good. Do not confuse it with C<clear()>, which only clears certain session parameters but keeps the session open.

=head2 EXPIRATION

CGI::Session also provides limited means to expire session data. Expiring session is the same as deleting it via delete(), but deletion takes place automaticly. To expire a session, you need to tell the library how long the session would be valid after the last access time. When that time is met, CGI::Session refuses to retrieve the session. It deletes the session and returns a brand new one. To assign expiration ticker for a session, use the expire() method:

    $session->expire(3600);     # expire after 3600 seconds
    $session->expire('+1h');    # expire after 1 hour
    $session->expire('+15m');   # expire after 15 minutes
    $session->expire('+1M');    # expire after a month and so on.

But sometimes, it makes perfect sense to expire a certain session parameter, instead of the whole session. The author usually does this in his login/authentication enabled sites, where after the user logs in successfully, sets a "_logged_in" flag to true, and assigns an expiration ticker on that flag to something like 30 minutes. It means, after 30 idle minutes CGI::Session will clear() "_logged_in" flag, indicating the user should log in over again. I aggree, the same effect can be achieved by simply expiring() the session itself, but in thise we would loose other session parameters, such as user's shopping cart, session-preferences and the like.

This feature can also be used to simulate layered security/authentication, such as, you can keep the user's access to his/her personal profile information for as long as 10 idle hours after successful login, but expire his/her access to his credit card information after 10 idle minutes. To achieve this effect, we will use expire() method again, but with a slightly different syntax:

    $session->expire(_profile_access, '+10h');
    $session->expire(_cc_access, '+10m');

With the above syntax, the person will still have access to his personal information even after 5 idle hours. But when he tries to access or update his/her credit card information, he may be displayed a "login again, please" screen.

This concludes our discussion of CGI::Session programming style for now (at least till the new releases of the library ). The rest of the manual covers some L<"SECUIRITY"> issues and L<"DRIVER SPECIFICATIONS"> for those want to implement their own drivers or understand the library architecture.

=head1 SECURITY

"How secure is using CGI::Session?", "Can others hack down people's sessions using another browser if they can get the session id of the user?", "Are the session ids guessable?" are the questions I find myself answering over and over again.

=head2 STORAGE

Security of the library does in many aspects depend on the implementation. After making use of this library, you no longer have to send all the information to the user's cookie except for the session id. But, you still have to store the data in the server side. So another set of questions arise, can an evil person have access to session data in your server, even if they do, can they make sense out of the data in the session file, and even if they can, can they reuse the information against a person who created that session. As you see, the answer depends on yourself who is implementing it.

First rule of thumb, do not save the users' passwords or other sensitive data in the session. If you can persuade yourself that this is necessary, make sure that evil eyes don't have access to session files in your server. If you're using RDBMS driver such as MySQL, the database will be protected with a username/password pair. But if it will be storing in the file system in the form of plain files, make sure no one except you can have access to those files.

Default configuration of the driver makes use of Data::Dumper class to serialize data to make it possible to save it in the disk. Data::Dumper's result is a human readable data structure, which if opened, can be interpreted against you. If you configure your session object to use either Storable or FreezeThaw as a serializer, this would make more difficult for bad guys to make sense out of session data. But don't use this as the only precaution for security. Since evil fingers can type a quick program using Storable or FreezeThaw which deciphers that session file very easily.

Also, do not allow sick minds to update the contents of session files. Of course CGI::Session makes sure it doesn't happen, but your cautiousness does no harm either.

Do not keep sessions open with sensitive information for very long period. This will increase the possibility that some bad guy may have someone's valid session id at a given time (acquired somehow).

ALWAYS USE "-ip-match" SWITCH!!!

Read on for the details of "-ip-match".

=head2 SESSION IDs

Session ids are not easily guessable (unless you're using Incr Id generator)! Default configuration of CGI::Session uses Digest::MD5 which takes process id, time in seconds since epoch and a random number, generates a 32 character long digest out of it. Although this string cannot be guessable by others, if they find it out somehow, can they use this identifier against the other person?

Consider the scenario, where you just give someone either via email or an instant messaging a link to your online-account profile, where you're currently logged in. The URL you give to that person contains a session id as part of a query string. If the site was initializing the session solely using query string parameter, after clicking on that link that person now appears to that site as you, and might have access to all of your private data instantly. How scary and how unwise implementation. And what a poor kid who didn't know that pasting URLs with session ids could be an accident waiting to happen.

Even if you're solely using cookies as the session id transporters, it's not that difficult to plant a cookie in the cookie file with the same id and trick the web browser to send that particular session id to the server. So key for security is to check if the person who's asking us to retrieve a session data is indeed the person who initially created the session data. CGI::Session helps you to watch out for such cases by enabling "-ip_match" switch while "use"ing the library:

    use CGI::Session qw/-ip-match/;

or alternatively, setting $CGI::Session::IP_MATCH to a true value, say to 1. This makes sure that before initializing a previously stored session, it checks if the ip address stored in the session matches the ip address of the user asking for that session. In which case the library returns the session, otherwise it dies with a proper error message.

=head1 DRIVER SPECIFICATIONS

This section is for driver authors who want to implement their own storing mechanism for the library. Those who enjoy sub-classing stuff should find this section useful as well. Here we discuss the architecture of CGI::Session and its drivers.

=head2 LIBRARY OVERVIEW

Library provides all the base methods listed in the L<METHODS> section. The only methods CGI::Session doesn't bother providing are the ones that need to deal with writing the session data in the disk, retrieving the data from the disk, and deleting the data. These are the methods specific to the driver, so that's where they should belong.

In other words, driver is just another Perl library which uses CGI::Session as a base class, and provides several additional methods that deal with disk access.

=head2 SERIALIZATION

Before getting to driver specs, let's talk about how the data should be stored. When flush() is called, or the program terminates, CGI::Session asks a driver to store the data somewhere in the disk, and passes the data in the form of a hash reference. Then it's the driver's obligation to serialize the data so that it can be stored in the disk.

Although you are free to implement your own serializing engine for your driver, CGI::Session distribution comes with several libraries you can inherit from and call freeze() method on the object to serialize the data and store it. Those libraries are:

=over 4

=item L<CGI::Session::Serialize::Default|CGI::Session::Serialize::Default>

=item L<CGI::Session::Serialize::Storable|CGI::Session::Serialize::Storable>

=item L<CGI::Session::Serialize::FreezeThaw|CGI::Session::Serialize::FreezeThaw>

=back

Example:

    # $data is a hashref that needs to be stored
    my $storable_data = $self->freeze($data)

$storable_data can now be saved in the disk safely.

When the driver is asked to retrieve the data from the disk, that serialized data should be accordingly de-serialized. The aforementioned serializers also provides thaw() method, which takes serialized data as the first argument and returns Perl data structure, as it was before saved. Example:

    my $hashref =  $self->thaw($stored_data);

=head2 DRIVER METHODS

Driver is just another Perl library, which uses CGI::Session as a base class and is required to provide the following methods:

=over 4

=item C<retrieve($self, $sid, $options)>

retrieve() is called by CGI::Session with the above 3 arguments when it's asked to retrieve the session data from the disk. $self is the session object, $sid is the session id, and $options is the list of the arguments passed to new() in the form of a hashref. Method should return un-serialized session data, or undef indicating the failure. If an error occurs, instead of calling die() or croak(), we suggest setting the error message to error() and returning undef:

    unless ( sysopen(FH, $options->{FileName}, O_RDONLY) ) {
        $self->error("Couldn't read from $options->{FileName}: $!");
        return undef;
    }

If the driver detects that it's been asked for a non-existing session, it should not generate any error message, but simply return undef. This will signal CGI::Session to create a new session id.

=item C<store($self, $sid, $options, $data)>

store() is called by CGI::Session when session data needs to be stored. Data to be stored is passed as the third argument to the method, and is a reference to a hash. Should return any true value indicating success, undef otherwise. Error message should be passed to error().

=item C<remove($self, $sid, $options)>

remove() called when CGI::Session is asked to remove the session data from the disk via delete() method. Should return true indicating success, undef otherwise, setting the error message to error()

=item C<teardown($self, $sid, $options)>

called when session object is about to get destroyed, either explicitly via close() or implicitly when the program terminates

=back

=head2 GENERATING ID

CGI::Session also requires the driver to provide a generate_id() method, which returns an id for a new session. Again, you are welcome to re-invent your own wheel, but note, that CGI::Session distribution comes with couple of id generating libraries that provide you with generate_id(). You should simply inherit from them. Following ID generators are available:

=over 4

=item L<CGI::Session::ID::MD5|CGI::Session::ID::MD5>

=item L<CGI::Session::ID::Incr|CGI::Session::ID::Incr>

=back

Refer to their respective manuals for more details.

In case you want to have your own style of ids, you can define a generate_id() method explicitly without inheriting from the above libraries. Or write your own B<CGI::Session::ID::YourID> library, that simply defines "generate_id()" method, which returns a session id, then give the name to the constructor as part of the DSN:

    $session = new CGI::Session("id:YourID", undef, {Neccessary=>Attributes});

=head2 BLUEPRINT

Your CGI::Session distribution comes with a Session/Blueprint.pm file
which can be used as a starting point for your driver:

    package CGI::Session::BluePrint;

    use strict;
    use base qw(
        CGI::Session
        CGI::Session::ID::MD5
        CGI::Session::Serialize::Default
    );

    # Load neccessary libraries below

    use vars qw($VERSION);

    $VERSION = '0.1';

    sub store {
        my ($self, $sid, $options, $data) = @_;

        my $storable_data = $self->freeze($data);

        #now you need to store the $storable_data into the disk
    }

    sub retrieve {
        my ($self, $sid, $options) = @_;

        # you will need to retrieve the stored data, and
        # deserialize it using $self->thaw() method
    }

    sub remove {
        my ($self, $sid, $options) = @_;

        # you simply need to remove the data associated
        # with the id
    }



    sub teardown {
        my ($self, $sid, $options) = @_;

        # this is called just before session object is destroyed
    }

    1;

    __END__;


After filling in the above blanks, you can do:

    $session = new CGI::Session("driver:MyDriver", $sid, {Option=>"Value"});

and follow CGI::Session manual.


=head1 COPYRIGHT

Copyright (C) 2002 Sherzod Ruzmetov. All rights reserved.

This library is free software. You can modify and distribute it under the same terms as Perl itself.

=head1 AUTHOR

Sherzod Ruzmetov <sherzodr@cpan.org>. Suggestions, feedbacks and patches are welcome.

=head1 SEE ALSO

=over 4

=item *

L<CGI::Session|CGI::Session> - CGI::Session manual

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
