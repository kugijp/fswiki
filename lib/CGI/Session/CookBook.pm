# $Id: CookBook.pm,v 1.1.1.1 2003/08/02 23:39:33 takezoe Exp $

package CGI::Session::CookBook;

use vars ('$VERSION');

($VERSION) = '$Revision: 1.1.1.1 $' =~ m/Revision:\s*(\S+)/;

1;

__END__;

=pod

=head1 NAME

CookBook - tutorial on session management in cgi applications

=head1 NOTE

This document is under construction. 

=head1 DESCRIPTION

C<CGI::Session::CookBook> is a tutorial that accompanies B<CGI::Session> 
distribution. It shows the usage of the library in web applications and 
demonstrates practical solutions for certain problems. We do not recommend you 
to read this tutorial unless you're familiar with L<CGI::Session|CGI::Session> 
and it's syntax.

=head1 CONVENTIONS

To avoid unnecessary redundancy, in all the examples that follow we assume
the following session and cgi objects:

	use CGI::Session;
	use CGI;

	my $cgi = new CGI;	
	my $session = new CGI::Session(undef, $cgi, {Directory=>'/tmp'});	

Although we are using default B<DSN> in our examples, you feel free to 
use any configuration you please.

After initializing the session, we should "mark" the user with that ID.
We use HTTP Cookies to do it:

    $cookie = $cgi->cookie(CGISESSID => $session->id );
    print $cgi->header(-cookie=>$cookie);

The first line is creating a cookie using B<CGI.pm>'s C<cookie()> 
method. The second line is sending the cookie to the user's browser 
using B<CGI.pm>'s C<header()> method.

After the above confessions, we can move to some examples with a less 
guilty conscious.

=head1 STORING THE USER'S NAME

=head2 PROBLEM

We have a form in our site that asks for user's name and email address. 
We want to store the data so that we can greet the user when he/she 
visits the site next time ( possibly after several days or even weeks ).

=head2 SOLUTION

Although quite simple and straight forward it seems, variations of this 
example are used in more robust session managing tricks.

Assuming the name of the form input fields are called "first_name" and 
"email" respectively, we can first retrieve this information from the 
cgi parameter. Using B<CGI.pm> this can be achieved in the following 
way:

    $first_name = $cgi->param("first_name");
    $email  = $cgi->param("email");

After having the above two values from the form handy, we can now save 
them in the session like:

    $session->param(first_name, $first_name);
    $session->param(email, $email);

If the above 4-line solution seems long for you (it does to me), you can 
achieve it with a single line of code:

    $session->save_param($cgi, ["first_name", "email"]);

The above syntax will get "first_name" and "email" parameters from the 
B<CGI.pm> and saves them to the B<CGI::Session> object.Now some other 
time or even in some other place we can simply say

    $name = $session->param("first_name");
    print "$name, I know it's you. Confess!";

and it does surprise him ( if not scare :) )

=head1 REMEMBER THE REFERER

=head2 PROBLEM

You run an outrourcing service, and people get refered to your program 
from other sites. After finishing the process, which might take several 
click-throughs, you need to provide them with a link which takes them to 
a site where they came from. In other words, after 10 clicks through 
your pages you need to recall the referered link, which takes the user 
to your site.

=head2 SOLUTION

This solution is similar to the previous one, but instead of getting the 
data from the submitted form, you get it from HTTP_REFERER environmental 
variable, which holds the link to the refered page. But you should be 
cautious, because the click on your own page to the same application 
generates a referal as well, in this case with your own link. So you 
need to watchout for that by saving the link only if it doesn't already 
exist. This approach is suitable for the application which ALWAYS get 
accessed by clicking links and posting forms, but NOT by typing in the 
url. Good examples would be voting polls, shopping carts among many 
others.

    $ENV{HTTP_REFERER} or die "Illegal use";

    unless ( $session->param("referer") ) {
        $session->param("referer", $ENV{HTTP_REFERER});
    }

In the above code, we simply save the referer in the session under the 
"referer" parameter. Note, that we first check if it was previously 
saved, in which case there would be no need to override it. It also 
means, if the referer was not saved previously, it's most likely the 
first visit to the page, and the HTTP_REFERER holds the link to the link 
we're interested in, not our own.

When we need to present the link back to the refered site, we just do:

    $href = $session->param("referer");
    print qq~<a href="$href">go back</a>~;

=head1 BROWSING HISTORY

=head2 PROBLEM

You have an online store with about a dozen categories and thousands of 
items in each category. When a visitor is surfing the site, you want to 
display the last 10-20 visited pages/items on the left menu of the site 
( for examples of this refer to Amazon.com ). This will make the site 
more usable and a lot friendlier

=head2 SOLUTION

The solution might vary on the way you implement the application. Here 
we'll show an example of the user's browsing history, where it shows 
just visited links and the pages' titles. For obvious reasons we build 
the array of the link=>title relationship. If you have a dynamicly 
generated content, you might have a slicker way of doing it. Despite the 
fact your implementation might be different, this example shows how to 
store a complex data structure in the session parameter. It's a blast!

    %pages = (
        "Home"      => "http://www.ultracgis.com",
        "About us"  => "http://www.ultracgis.com/about",
        "Contact"   => "http://www.ultracgis.com/contact",
        "Products"  => "http://www.ultracgis.com/products",
        "Services"  => "http://www.ultracgis.com/services",
        "Portfolio" => "http://www.ultracgis.com/pfolio",
        # ...
    );

    # Get a url of the page loaded
    $link = $ENV{REQUEST_URI} or die "Errr. What the hack?!";

    # get the previously saved arrayref from the session parameter
    # named "HISTORY"
    $history = $session->param("HISTORY") || [];

    # push()ing a hashref to the arrayref
    push (@{$history}, {title => $pages{ $link  },
                        link  => $link          });

    # storing the modified history back in the session
    $session->param( "HISTORY", $history );


What we want you to notice is the $history, which is a reference to an 
array, elements of which consist of references to anonymous hashes. This 
example illustrates that one can safely store complex data structures, 
including objects, in the session and they can be re-created for you the 
way they were once stored.

Displaying the browsing history should be even more straight-forward:

    # we first get the history information from the session
    $history = $session->param("HISTORY") || [];

    print qq~<div>Your recently viewed pages</div>~;

    for $page ( @{ $history } ) {
        print qq~<a href="$page->{link}">$page->{title}</a><br>~;
    }

If you use B<HTML::Template>, to access the above history in your 
templates simply C<associate> the $session object with that of 
B<HTML::Template>:

    $template = new HTML::Template(filename=>"some.tmpl", 
associate=>$session );

Now in your "some.tmpl" template you can access the above history like 
so:

    <!-- left menu starts -->
    <table width="170">
        <tr>
            <th> last visited pages </th>
        </tr>
        <TMPL_LOOP NAME=HISTORY>
        <tr>
            <td>
            <a href="<TMPL_VAR NAME=LINK>"> <TMPL_VAR NAME=TITLE> </a>
            </td>
        </tr>
        </TMPL_LOOP>
    </table>
    <!-- left menu ends -->

and this will print the list in nicely formated table. For more 
information on associating an object with the B<HTML::Template> refer to 
L<HTML::Template manual|HTML::Template>

=head1 SHOPPING CART

=head2 PROBLEM

You have a site that lists the available products off the database. You 
need an application that would enable users' to "collect" items for 
checkout, in other words, to put into a virtual shopping cart. When they 
are done, they can proceed to checkout.

=head2 SOLUTION

Again, the exact implementation of the site will depend on the 
implementation of this solution. This example is pretty much similar to 
the way we implemented the browing history in the previous example. But 
instead of saving the links of the pages, we simply save the ProductID 
as the arrayref in the session parameter called, say, "CART". In the 
folloiwng example we tried to represent the imaginary database in the 
form of a hash.

Each item in the listing will have a url to the shopping cart. The url 
will be in the following format:

    http://ultracgis.com/cart.cgi?cmd=add;itemID=1001

C<cmd> CGI parameter is a run mode for the application, in this 
particular example it's "add", which tells the application that an item 
is about to be added. C<itemID> tells the application which item should 
be added. You might as well go with the item title, instead of numbers, 
but most of the time in dynamicly generated sites you prefer itemIDs 
over their titles, since titles tend to be not consistent (it's from 
experience):

    # Imaginary database in the form of a hash
    %products = (
        1001 =>    [ "usr/bin/perl t-shirt",    14.99],
        1002 =>    [ "just perl t-shirt",       14.99],
        1003 =>    [ "shebang hat",             15.99],
        1004 =>    [ "linux mug",               19.99],
        # on and on it goes....
    );

    # getting the run mode for the state. If doesn't exist,
    # defaults to "display", which shows the cart's content
    $cmd = $cgi->param("cmd") || "display";

    if ( $cmd eq "display" ) {
        print display_cart($cgi, $session);

    } elsif ( $cmd eq "add" ) {
        print add_item($cgi, $session, \%products,);

    } elsif ( $cmd eq "remove") {
        print remove_item($cgi, $session);

    } elsif ( $cmd eq "clear" ) {
        print clear_cart($cgi, $session);

    } else {
        print display_cart($cgi, $session);

    }


The above is the skeleton of the application. Now we start writing the 
functions (subroutines) associated with each run-mode. We'll start with 
C<add_item()>:

    sub add_item {
        my ($cgi, $session, $products) = @_;

        # getting the itemID to be put into the cart
        my $itemID = $cgi->param("itemID") or die "No item specified";

        # getting the current cart's contents:
        my $cart = $session->param("CART") || [];

        # adding the selected item
        push @{ $cart }, {
            itemID => $itemID,
            name   => $products->{$itemID}->[0],
            price  => $products->{$itemID}->[1],
        };

        # now store the updated cart back into the session
        $session->param( "CART", $cart );

        # show the contents of the cart
        return display_cart($cgi, $session);
    }


As you see, things are quite straight-forward this time as well. We're 
accepting three arguments, getting the itemID from the C<itemID> CGI 
parameter, retrieving contents of the current cart from the "CART" 
session parameter, updating the contents with the information we know 
about the item with the C<itemID>, and storing the modifed $cart back to 
"CART" session parameter. When done, we simply display the cart. If 
anything doesn't make sence to you, STOP! Read it over!

Here are the contents for C<display_cart()>, which simply gets the 
shoping cart's contents from the session parameter and generates a list:

    sub display_cart {
        my ($cgi, $session) = @_;

        # getting the cart's contents
        my $cart = $session->param("CART") || [];
        my $total_price = 0;
        my $RV = q~<table><tr><th>Title</th><th>Price</th></tr>~;

        if ( $cart ) {
            for my $product ( @{$cart} ) {
                $total_price += $product->{price};
                $RV = qq~
                    <tr>
                        <td>$product->{name}</td>
                        <td>$product->{price}</td>
                    </tr>~;
            }

        } else {
            $RV = qq~
                <tr>
                    <td colspan="2">There are no items in your cart 
yet</td>
                </tr>~;
        }

        $RV = qq~
            <tr>
                <td><b>Total Price:</b></td>
                <td><b>$total_price></b></td>
            </tr></table>~;

        return $RV;
    }


A more professional approach would be to take the HTML outside the 
program code by using B<HTML::Template>, in which case the above 
C<display_cart()> will look like:

    sub display_cart {
        my ($cgi, $session) = @_;

        my $template = new HTML::Template(filename=>"cart.tmpl",
                                          associate=>$session,
                                          die_on_bad_params=>0);
        return $template->output();

    }

And respective portion of the html template would be something like:

    <!-- shopping cart starts -->
    <table>
        <tr>
            <th>Title</th><th>Price</th>
        </tr>
        <TMPL_LOOP NAME=CART>
        <tr>
            <td> <TMPL_VAR NAME=NAME> </td>
            <td> <TMPL_VAR NAME=PRICE> </td>
        </tr>
        </TMPL_LOOP>
        <tr>
            <td><b>Total Price:</b></td>
            <td><b> <TMPL_VAR NAME=TOTAL_PRICE> </td></td>
        </tr>
    </table>
    <!-- shopping cart ends -->

A slight problem in the above template: TOTAL_PRICE doesn't exist. To 
fix this problem we need to introduce a slight modification to our 
C<add_item()>, where we also save the precalculated total price in the 
"total_price" session parameter. Try it yourself.

If you've been following the examples, you shouldn't discover anything 
in the above code either. Let's move to C<remove_item()>. That's what 
the link for removing an item from the shopping cart will look like:

    http://ultracgis.com/cart.cgi?cmd=remove;itemID=1001

    sub remove_item {
        my ($cgi, $session) = @_;

        # getting the itemID from the CGI parameter
        my $itemID = $cgi->param("itemID") or return undef;

        # getting the cart data from the session
        my $cart = $session->param("CART") or return undef;

        my $idx = 0;
        for my $product ( @{$cart} ) {
            $product->{itemID} == $itemID or next;
            splice( @{$cart}, $idx++, 1);
        }

        $session->param("CART", $cart);

        return display_cart($cgi, $session);
    }

C<clear_cart()> will get even shorter

    sub clear_cart {
        my ($cgi, $session) = @_;
        $session->clear(["CART"]);
    }

=head1 MEMBERS AREA

=head2 PROBLEM

You want to create an area in the part of your site/application where 
only restricted users should have access to.

=head2 SOLUTION

I have encountered literally dozens of different implementations of this 
by other programmers, none of them perfect. Key properties of such an 
application are reliability, security and no doubt, user-friendliness. 
Consider this receipt not just as a CGI::Session implementation, but 
also a receipt on handling login/authentication routines transparently. 
Your users will love you for it.

So first, let's build the logic, only then we'll start coding. Before 
going any further, we need to agree upon a username/password fields that 
we'll be using for our login form. Let's choose "lg_name" and 
"lg_password" respectively. Now, in our application, we'll always be 
watching out for those two fields at the very start of the program to 
detect if the user submitted a login form or not. Some people tend to 
setup a dedicated run-mode like "_cmd=login" which will be handled 
seperately, but later you'll see why this is not a good idea.

If those two parameters are present in our CGI object, we will go ahead 
and try to load the user's profile from the database and set a special 
session flag "~logged-in" to a true value. If those parameters are 
present, but if the login/password pairs do not match with the ones in 
the database, we leave "~logged-in" untouched, but increment another 
flag "~login-trials" to one. So here is an init() function (for 
initializer) which should be called at the top of the program:

    sub init {
        my ($session, $cgi) = @_; # receive two args

        if ( $session->param("~logged-in") ) {
            return 1;  # if logged in, don't bother going further
        }

        my $lg_name = $cgi->param("lg_name") or return;
        my $lg_psswd=$cgi->param("lg_password") or return;

        # if we came this far, user did submit the login form
        # so let's try to load his/her profile if name/psswds match
        if ( my $profile = _load_profile($lg_name, $lg_psswd) ) {
            $session->param("~profile", $profile);
            $session->param("~logged-in", 1);
            $session->clear(["~login-trials"]);
            return 1;

        }

        # if we came this far, the login/psswds do not match
        # the entries in the database
        my $trials = $session->param("~login-trials") || 0;
        return $session->param("~login-trials", ++$trials);
    }


Syntax for _load_profile() totally depends on where your user profiles 
are stored. I normally store them in MySQL tables, but suppose you're 
storing them in flat files in the following format:

    username    password    email

Your _load_profile() would look like:

    sub _load_profile {
        my ($lg_name, $lg_psswd) = @_;

        local $/ = "\n";
        unless (sysopen(PROFILE, "profiles.txt", O_RDONLY) ) {
            die "Couldn't open profiles.txt: $!");
        }
        while ( <PROFILES> ) {
            /^(\n|#)/ and next;
            chomp;
            my ($n, $p, $e) = split "\s+";
            if ( ($n eq $lg_name) && ($p eq $lg_psswd) ) {
                my $p_mask = "x" . length($p);
                return {username=>$n, password=>$p_mask, email=>$e};

            }
        }
        close(PROFILE);

        return undef;
    }


Now regardless of what run mode user is in, you just call the above 
C<init()> method somewhere in the beginning of your program, and if the 
user is logged in properly, you're guaranteed that "~logged-in" session 
flag would be set to true and the user's profile information will be 
available to you all the time from the "~profile" session parameter:

    init($cgi, $session);

    if ( $session->param("~login-trials") >= 3 ) {
        print error("You failed 3 times in a row.\n" .
                    "Your session is blocked. Please contact us with ".
                    "the details of your action");
        exit(0);

    }

    unless ( $session->param("~logged-in") ) {
        print login_page($cgi, $session);
        exit(0);

    }

In the above example we're using exit() to stop the further processing. 
If you require mod_perl compatibility, you will want some other, more 
graceful way.

To access the user's profile data without accessing the database again, 
you simply do:

    my $profile = $session->param("~profile");
    print "Hello $profile->{username}, I know it's you. Confess!";

and the user will be terrified :-).

But here is a trick. Suppose, a user clicked on the link with the 
following query_string: "profile.cgi?_cmd=edit", but he/she is not 
logged in. If you're performing the above init() function, the user will 
see a login_page(). What happens after they submit the form with proper 
username/password? Ideally you would want the user to be taken directly 
to "?_cmd=edit" page, since that's the link they clicked before being 
prompted to login,  rather than some other say "?_cmd=view" page. To 
deal with this very important usabilit feature, you need to include a 
hiidden field in your login form similar to:

    <INPUT TYPE="hidden" NAME="_cmd" VALUE="$cmd" />

Since I prefer using HTML::Template, that's what I can find in my login 
form most of the time:

    <input type="hidden" name="_cmd" value="<tmpl_var _cmd>">

The above _cmd slot will be filled in properly by just associating $cgi 
object with HTML::Template.

Implementing a "sign out" functionality is even more straight forward. 
Since the application is only checking for "~logged-in" session flag, we 
simply clear the flag when a user click on say "?_cmd=logout" link:

    if ( $cmd eq "logout" ) {
        $session->clear(["~logged-in"]);

    }

You can choose to clear() "~profile" as well, but wouldn't you want to 
have an ability to greet the user with his/her username or fill out his 
username in the login form next time? This might be a question of 
beliefs. But we believe it's the question of usability. You may also 
choose to delete() the session... agh, let's not argue what is better 
and what is not. As long as you're happy, that's what counts :-). Enjoy!

=head1 SUGGESTIONS AND CORRECTIONS

We tried to put together some simple examples of CGI::Session usage. 
There're litterally hundreds of different exciting tricks one can 
perform with proper session management. If you have a problem, and 
believe CGI::Session is a right tool but don't know how to implement it, 
or, if you want to see some other examples of your choice in this Cook 
Book, just drop us an email, and we'll be happy to work on them as soon 
as this evil time permits us.

Send your questions, requests and corrections to CGI::Session mailing 
list, Cgi-session@ultracgis.com.

=head1 AUTHOR

    Sherzod Ruzmetov <sherzodr@cpan.org>

=head1 SEE ALSO

=over 4

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
