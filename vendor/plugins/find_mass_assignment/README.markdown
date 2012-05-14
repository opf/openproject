# Find Mass Assignment

## A Rails plugin to find likely mass assignment vulnerabilities

The <tt>find\_mass\_assignment</tt> Rake task defined by the plugin finds likely mass assignment problems in Rails projects.

The method is to scan the controllers for likely mass assignment, and then find the corresponding models that *don't* have <tt>attr\_accessible</tt> defined.  Any time that happens, it's a potential problem.

Install this plugin as follows:

    $ script/plugin install git://github.com/mhartl/find_mass_assignment.git

For more information, see my [brief review of mass assignment](http://blog.mhartl.com/2008/09/21/mass-assignment-in-rails-applications/) and my discussion of [how to fix mass assignment vulnerabilities in Rails](http://blog.mhartl.com/2008/09/21/finding-and-fixing-mass-assignment-problems-in-rails-applications/).

**Warning:** For convenience, the plugin defines some "unsafe" attribute updates (see below), including a method called <tt>unsafe\_attributes=</tt> to bypass the <tt>attr\_accessible</tt> restrictions. This means that any attribute protected with <tt>attr\_protected</tt> can also be bypassed simply by hitting the application at a URL like

<pre>http://127.0.0.1:3000/.../?user[unsafe_attributes][admin]=1</pre>

As a result, if you use this plugin, **always use <tt>attr\_accessible</tt> in every model that is exposed to mass assignment via a web interface**.

(I tried working around this in <tt>unsafe\_attributes=</tt> by testing each attribute to make sure it wasn't protected, but merely testing whether <tt>attr\_protected</tt> included a given attribute, using <tt>self.class.attr\_protected.include?</tt>, somehow violated the restriction that no model can define both <tt>attr\_accessible</tt> and <tt>attr\_protected</tt>. The result was massive breakage in my test suites for any model that defined <tt>attr\_accessible</tt>, which is usually all of them.)

## Example

Suppose line 17 of the Users controller is

    @user = User.new(params[:user])

but the User model *doesn't* define <tt>attr_accessible</tt>.  Then we get the output

    $ rake find_mass_assignment

    /path/to/app/controllers/users_controller.rb
      17  @user = User.new(params[:user])

This indicates that the User model has a likely mass assignment vulnerability. In the case of no apparent vulnerabilities, the rake task simply returns nothing.

The Unix exit status code of the rake task is 0 on success, 1 on failure, which means it can be used in a pre-commit hook. For example, if you use Git for version control, you can check for mass assignment vulnerabilities before each commit by putting

<pre>rake find_mass_assignment</pre>

at the end of the <tt>.git/hooks/pre-commit</tt> file.* Any commits that introduce potential mass assignment vulnerabilities (as determined by the plugin) will then fail automatically.

*Be sure to make the pre-commit hook file executable if it isn't already:

<pre>$ chmod +x .git/hooks/pre-commit</pre>

(You might also want to comment out the weird Perl script that's the default pre-commit hook on some systems; it gives you warnings like "You have some suspicious patch lines" that you probably don't want.)

# Unsafe attribute updates

It is often useful to override <tt>attr\_accessible</tt>, especially at the console and in tests, so the plugin also adds an assortment of helper methods to Active Record:

* unsafe\_new
* unsafe\_build
* unsafe\_create/unsafe\_create!
* unsafe\_update\_attributes/unsafe\_update\_attributes!

These work just like their safe counterparts, except they bypass attr\_accessible. For example, 

<pre>Person.unsafe_new(:admin => true)</pre>

works even if <tt>admin</tt> isn't attr\_accessible.

# Copyright

Copyright (c) 2008 Michael Hartl, released under the MIT license
