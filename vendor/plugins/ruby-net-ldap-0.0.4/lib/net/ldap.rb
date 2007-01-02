# $Id: ldap.rb 154 2006-08-15 09:35:43Z blackhedd $
#
# Net::LDAP for Ruby
#
#
# Copyright (C) 2006 by Francis Cianfrocca. All Rights Reserved.
#
# Written and maintained by Francis Cianfrocca, gmail: garbagecat10.
#
# This program is free software.
# You may re-distribute and/or modify this program under the same terms
# as Ruby itself: Ruby Distribution License or GNU General Public License.
#
#
# See Net::LDAP for documentation and usage samples.
#


require 'socket'
require 'ostruct'

begin
  require 'openssl'
  $net_ldap_openssl_available = true
rescue LoadError
end

require 'net/ber'
require 'net/ldap/pdu'
require 'net/ldap/filter'
require 'net/ldap/dataset'
require 'net/ldap/psw'
require 'net/ldap/entry'


module Net


  # == Net::LDAP
  #
  # This library provides a pure-Ruby implementation of the
  # LDAP client protocol, per RFC-2251.
  # It can be used to access any server which implements the
  # LDAP protocol.
  #
  # Net::LDAP is intended to provide full LDAP functionality
  # while hiding the more arcane aspects
  # the LDAP protocol itself, and thus presenting as Ruby-like
  # a programming interface as possible.
  # 
  # == Quick-start for the Impatient
  # === Quick Example of a user-authentication against an LDAP directory:
  #
  #  require 'rubygems'
  #  require 'net/ldap'
  #  
  #  ldap = Net::LDAP.new
  #  ldap.host = your_server_ip_address
  #  ldap.port = 389
  #  ldap.auth "joe_user", "opensesame"
  #  if ldap.bind
  #    # authentication succeeded
  #  else
  #    # authentication failed
  #  end
  #
  #
  # === Quick Example of a search against an LDAP directory:
  #
  #  require 'rubygems'
  #  require 'net/ldap'
  #  
  #  ldap = Net::LDAP.new :host => server_ip_address,
  #       :port => 389,
  #       :auth => {
  #             :method => :simple,
  #             :username => "cn=manager,dc=example,dc=com",
  #             :password => "opensesame"
  #       }
  #
  #  filter = Net::LDAP::Filter.eq( "cn", "George*" )
  #  treebase = "dc=example,dc=com"
  #  
  #  ldap.search( :base => treebase, :filter => filter ) do |entry|
  #    puts "DN: #{entry.dn}"
  #    entry.each do |attribute, values|
  #      puts "   #{attribute}:"
  #      values.each do |value|
  #        puts "      --->#{value}"
  #      end
  #    end
  #  end
  #  
  #  p ldap.get_operation_result
  #  
  #
  # == A Brief Introduction to LDAP
  #
  # We're going to provide a quick, informal introduction to LDAP
  # terminology and
  # typical operations. If you're comfortable with this material, skip
  # ahead to "How to use Net::LDAP." If you want a more rigorous treatment
  # of this material, we recommend you start with the various IETF and ITU
  # standards that relate to LDAP.
  #
  # === Entities
  # LDAP is an Internet-standard protocol used to access directory servers.
  # The basic search unit is the <i>entity,</i> which corresponds to
  # a person or other domain-specific object.
  # A directory service which supports the LDAP protocol typically
  # stores information about a number of entities.
  #
  # === Principals
  # LDAP servers are typically used to access information about people,
  # but also very often about such items as printers, computers, and other
  # resources. To reflect this, LDAP uses the term <i>entity,</i> or less
  # commonly, <i>principal,</i> to denote its basic data-storage unit.
  # 
  #
  # === Distinguished Names
  # In LDAP's view of the world,
  # an entity is uniquely identified by a globally-unique text string
  # called a <i>Distinguished Name,</i> originally defined in the X.400
  # standards from which LDAP is ultimately derived.
  # Much like a DNS hostname, a DN is a "flattened" text representation
  # of a string of tree nodes. Also like DNS (and unlike Java package
  # names), a DN expresses a chain of tree-nodes written from left to right
  # in order from the most-resolved node to the most-general one.
  #
  # If you know the DN of a person or other entity, then you can query
  # an LDAP-enabled directory for information (attributes) about the entity.
  # Alternatively, you can query the directory for a list of DNs matching
  # a set of criteria that you supply.
  #
  # === Attributes
  #
  # In the LDAP view of the world, a DN uniquely identifies an entity.
  # Information about the entity is stored as a set of <i>Attributes.</i>
  # An attribute is a text string which is associated with zero or more
  # values. Most LDAP-enabled directories store a well-standardized
  # range of attributes, and constrain their values according to standard
  # rules.
  #
  # A good example of an attribute is <tt>sn,</tt> which stands for "Surname."
  # This attribute is generally used to store a person's surname, or last name.
  # Most directories enforce the standard convention that
  # an entity's <tt>sn</tt> attribute have <i>exactly one</i> value. In LDAP
  # jargon, that means that <tt>sn</tt> must be <i>present</i> and
  # <i>single-valued.</i>
  #
  # Another attribute is <tt>mail,</tt> which is used to store email addresses.
  # (No, there is no attribute called "email," perhaps because X.400 terminology
  # predates the invention of the term <i>email.</i>) <tt>mail</tt> differs
  # from <tt>sn</tt> in that most directories permit any number of values for the
  # <tt>mail</tt> attribute, including zero.
  #
  #
  # === Tree-Base
  # We said above that X.400 Distinguished Names are <i>globally unique.</i>
  # In a manner reminiscent of DNS, LDAP supposes that each directory server
  # contains authoritative attribute data for a set of DNs corresponding
  # to a specific sub-tree of the (notional) global directory tree.
  # This subtree is generally configured into a directory server when it is
  # created. It matters for this discussion because most servers will not
  # allow you to query them unless you specify a correct tree-base.
  #
  # Let's say you work for the engineering department of Big Company, Inc.,
  # whose internet domain is bigcompany.com. You may find that your departmental
  # directory is stored in a server with a defined tree-base of
  #  ou=engineering,dc=bigcompany,dc=com
  # You will need to supply this string as the <i>tree-base</i> when querying this
  # directory. (Ou is a very old X.400 term meaning "organizational unit."
  # Dc is a more recent term meaning "domain component.")
  #
  # === LDAP Versions
  # (stub, discuss v2 and v3)
  #
  # === LDAP Operations
  # The essential operations are: #bind, #search, #add, #modify, #delete, and #rename.
  # ==== Bind
  # #bind supplies a user's authentication credentials to a server, which in turn verifies
  # or rejects them. There is a range of possibilities for credentials, but most directories
  # support a simple username and password authentication.
  #
  # Taken by itself, #bind can be used to authenticate a user against information
  # stored in a directory, for example to permit or deny access to some other resource.
  # In terms of the other LDAP operations, most directories require a successful #bind to
  # be performed before the other operations will be permitted. Some servers permit certain
  # operations to be performed with an "anonymous" binding, meaning that no credentials are
  # presented by the user. (We're glossing over a lot of platform-specific detail here.)
  #
  # ==== Search
  # Calling #search against the directory involves specifying a treebase, a set of <i>search filters,</i>
  # and a list of attribute values.
  # The filters specify ranges of possible values for particular attributes. Multiple
  # filters can be joined together with AND, OR, and NOT operators.
  # A server will respond to a #search by returning a list of matching DNs together with a
  # set of attribute values for each entity, depending on what attributes the search requested.
  # 
  # ==== Add
  # #add specifies a new DN and an initial set of attribute values. If the operation
  # succeeds, a new entity with the corresponding DN and attributes is added to the directory.
  #
  # ==== Modify
  # #modify specifies an entity DN, and a list of attribute operations. #modify is used to change
  # the attribute values stored in the directory for a particular entity.
  # #modify may add or delete attributes (which are lists of values) or it change attributes by
  # adding to or deleting from their values.
  # Net::LDAP provides three easier methods to modify an entry's attribute values:
  # #add_attribute, #replace_attribute, and #delete_attribute.
  #
  # ==== Delete
  # #delete specifies an entity DN. If it succeeds, the entity and all its attributes
  # is removed from the directory.
  #
  # ==== Rename (or Modify RDN)
  # #rename (or #modify_rdn) is an operation added to version 3 of the LDAP protocol. It responds to
  # the often-arising need to change the DN of an entity without discarding its attribute values.
  # In earlier LDAP versions, the only way to do this was to delete the whole entity and add it
  # again with a different DN.
  #
  # #rename works by taking an "old" DN (the one to change) and a "new RDN," which is the left-most
  # part of the DN string. If successful, #rename changes the entity DN so that its left-most
  # node corresponds to the new RDN given in the request. (RDN, or "relative distinguished name,"
  # denotes a single tree-node as expressed in a DN, which is a chain of tree nodes.)
  #
  # == How to use Net::LDAP
  #
  # To access Net::LDAP functionality in your Ruby programs, start by requiring
  # the library:
  #
  #  require 'net/ldap'
  #
  # If you installed the Gem version of Net::LDAP, and depending on your version of
  # Ruby and rubygems, you _may_ also need to require rubygems explicitly:
  #
  #  require 'rubygems'
  #  require 'net/ldap'
  #
  # Most operations with Net::LDAP start by instantiating a Net::LDAP object.
  # The constructor for this object takes arguments specifying the network location
  # (address and port) of the LDAP server, and also the binding (authentication)
  # credentials, typically a username and password.
  # Given an object of class Net:LDAP, you can then perform LDAP operations by calling
  # instance methods on the object. These are documented with usage examples below.
  #
  # The Net::LDAP library is designed to be very disciplined about how it makes network
  # connections to servers. This is different from many of the standard native-code
  # libraries that are provided on most platforms, which share bloodlines with the
  # original Netscape/Michigan LDAP client implementations. These libraries sought to
  # insulate user code from the workings of the network. This is a good idea of course,
  # but the practical effect has been confusing and many difficult bugs have been caused
  # by the opacity of the native libraries, and their variable behavior across platforms.
  #
  # In general, Net::LDAP instance methods which invoke server operations make a connection
  # to the server when the method is called. They execute the operation (typically binding first)
  # and then disconnect from the server. The exception is Net::LDAP#open, which makes a connection
  # to the server and then keeps it open while it executes a user-supplied block. Net::LDAP#open
  # closes the connection on completion of the block.
  #

  class LDAP

    class LdapError < Exception; end

    VERSION = "0.0.4"


    SearchScope_BaseObject = 0
    SearchScope_SingleLevel = 1
    SearchScope_WholeSubtree = 2
    SearchScopes = [SearchScope_BaseObject, SearchScope_SingleLevel, SearchScope_WholeSubtree]

    AsnSyntax = {
      :application => {
        :constructed => {
          0 => :array,              # BindRequest
          1 => :array,              # BindResponse
          2 => :array,              # UnbindRequest
          3 => :array,              # SearchRequest
          4 => :array,              # SearchData
          5 => :array,              # SearchResult
          6 => :array,              # ModifyRequest
          7 => :array,              # ModifyResponse
          8 => :array,              # AddRequest
          9 => :array,              # AddResponse
          10 => :array,             # DelRequest
          11 => :array,             # DelResponse
          12 => :array,             # ModifyRdnRequest
          13 => :array,             # ModifyRdnResponse
          14 => :array,             # CompareRequest
          15 => :array,             # CompareResponse
          16 => :array,             # AbandonRequest
          19 => :array,             # SearchResultReferral
          24 => :array,             # Unsolicited Notification
        }
      },
      :context_specific => {
        :primitive => {
          0 => :string,             # password
          1 => :string,             # Kerberos v4
          2 => :string,             # Kerberos v5
        },
        :constructed => {
          0 => :array,              # RFC-2251 Control
          3 => :array,              # Seach referral
        }
      }
    }

    DefaultHost = "127.0.0.1"
    DefaultPort = 389
    DefaultAuth = {:method => :anonymous}
    DefaultTreebase = "dc=com"


    ResultStrings = {
      0 => "Success",
      1 => "Operations Error",
      2 => "Protocol Error",
      3 => "Time Limit Exceeded",
      4 => "Size Limit Exceeded",
      12 => "Unavailable crtical extension",
      16 => "No Such Attribute",
      17 => "Undefined Attribute Type",
      20 => "Attribute or Value Exists",
      32 => "No Such Object",
      34 => "Invalid DN Syntax",
      48 => "Invalid DN Syntax",
      48 => "Inappropriate Authentication",
      49 => "Invalid Credentials",
      50 => "Insufficient Access Rights",
      51 => "Busy",
      52 => "Unavailable",
      53 => "Unwilling to perform",
      65 => "Object Class Violation",
      68 => "Entry Already Exists"
    }


    module LdapControls
      PagedResults = "1.2.840.113556.1.4.319" # Microsoft evil from RFC 2696
    end


    #
    # LDAP::result2string
    #
    def LDAP::result2string code # :nodoc:
      ResultStrings[code] || "unknown result (#{code})"
    end 


    attr_accessor :host, :port, :base


    # Instantiate an object of type Net::LDAP to perform directory operations.
    # This constructor takes a Hash containing arguments, all of which are either optional or may be specified later with other methods as described below. The following arguments
    # are supported:
    # * :host => the LDAP server's IP-address (default 127.0.0.1)
    # * :port => the LDAP server's TCP port (default 389)
    # * :auth => a Hash containing authorization parameters. Currently supported values include:
    #   {:method => :anonymous} and
    #   {:method => :simple, :username => your_user_name, :password => your_password }
    #   The password parameter may be a Proc that returns a String.
    # * :base => a default treebase parameter for searches performed against the LDAP server. If you don't give this value, then each call to #search must specify a treebase parameter. If you do give this value, then it will be used in subsequent calls to #search that do not specify a treebase. If you give a treebase value in any particular call to #search, that value will override any treebase value you give here.
    # * :encryption => specifies the encryption to be used in communicating with the LDAP server. The value is either a Hash containing additional parameters, or the Symbol :simple_tls, which is equivalent to specifying the Hash {:method => :simple_tls}. There is a fairly large range of potential values that may be given for this parameter. See #encryption for details.
    #
    # Instantiating a Net::LDAP object does <i>not</i> result in network traffic to
    # the LDAP server. It simply stores the connection and binding parameters in the
    # object.
    #
    def initialize args = {}
      @host = args[:host] || DefaultHost
      @port = args[:port] || DefaultPort
      @verbose = false # Make this configurable with a switch on the class.
      @auth = args[:auth] || DefaultAuth
      @base = args[:base] || DefaultTreebase
      encryption args[:encryption] # may be nil

      if pr = @auth[:password] and pr.respond_to?(:call)
        @auth[:password] = pr.call
      end

      # This variable is only set when we are created with LDAP::open.
      # All of our internal methods will connect using it, or else
      # they will create their own.
      @open_connection = nil
    end

    # Convenience method to specify authentication credentials to the LDAP
    # server. Currently supports simple authentication requiring
    # a username and password.
    #
    # Observe that on most LDAP servers,
    # the username is a complete DN. However, with A/D, it's often possible
    # to give only a user-name rather than a complete DN. In the latter
    # case, beware that many A/D servers are configured to permit anonymous
    # (uncredentialled) binding, and will silently accept your binding
    # as anonymous if you give an unrecognized username. This is not usually
    # what you want. (See #get_operation_result.)
    #
    # <b>Important:</b> The password argument may be a Proc that returns a string.
    # This makes it possible for you to write client programs that solicit
    # passwords from users or from other data sources without showing them
    # in your code or on command lines.
    #
    #  require 'net/ldap'
    #  
    #  ldap = Net::LDAP.new
    #  ldap.host = server_ip_address
    #  ldap.authenticate "cn=Your Username,cn=Users,dc=example,dc=com", "your_psw"
    #
    # Alternatively (with a password block):
    #
    #  require 'net/ldap'
    #  
    #  ldap = Net::LDAP.new
    #  ldap.host = server_ip_address
    #  psw = proc { your_psw_function }
    #  ldap.authenticate "cn=Your Username,cn=Users,dc=example,dc=com", psw
    #
    def authenticate username, password
      password = password.call if password.respond_to?(:call)
      @auth = {:method => :simple, :username => username, :password => password}
    end

    alias_method :auth, :authenticate

    # Convenience method to specify encryption characteristics for connections
    # to LDAP servers. Called implicitly by #new and #open, but may also be called
    # by user code if desired.
    # The single argument is generally a Hash (but see below for convenience alternatives).
    # This implementation is currently a stub, supporting only a few encryption
    # alternatives. As additional capabilities are added, more configuration values
    # will be added here.
    #
    # Currently, the only supported argument is {:method => :simple_tls}.
    # (Equivalently, you may pass the symbol :simple_tls all by itself, without
    # enclosing it in a Hash.)
    #
    # The :simple_tls encryption method encrypts <i>all</i> communications with the LDAP
    # server.
    # It completely establishes SSL/TLS encryption with the LDAP server 
    # before any LDAP-protocol data is exchanged.
    # There is no plaintext negotiation and no special encryption-request controls
    # are sent to the server. 
    # <i>The :simple_tls option is the simplest, easiest way to encrypt communications
    # between Net::LDAP and LDAP servers.</i>
    # It's intended for cases where you have an implicit level of trust in the authenticity
    # of the LDAP server. No validation of the LDAP server's SSL certificate is
    # performed. This means that :simple_tls will not produce errors if the LDAP
    # server's encryption certificate is not signed by a well-known Certification
    # Authority.
    # If you get communications or protocol errors when using this option, check
    # with your LDAP server administrator. Pay particular attention to the TCP port
    # you are connecting to. It's impossible for an LDAP server to support plaintext
    # LDAP communications and <i>simple TLS</i> connections on the same port.
    # The standard TCP port for unencrypted LDAP connections is 389, but the standard
    # port for simple-TLS encrypted connections is 636. Be sure you are using the
    # correct port.
    #
    # <i>[Note: a future version of Net::LDAP will support the STARTTLS LDAP control,
    # which will enable encrypted communications on the same TCP port used for
    # unencrypted connections.]</i>
    #
    def encryption args
      if args == :simple_tls
        args = {:method => :simple_tls}
      end
      @encryption = args
    end


    # #open takes the same parameters as #new. #open makes a network connection to the
    # LDAP server and then passes a newly-created Net::LDAP object to the caller-supplied block.
    # Within the block, you can call any of the instance methods of Net::LDAP to
    # perform operations against the LDAP directory. #open will perform all the
    # operations in the user-supplied block on the same network connection, which
    # will be closed automatically when the block finishes.
    #
    #  # (PSEUDOCODE)
    #  auth = {:method => :simple, :username => username, :password => password}
    #  Net::LDAP.open( :host => ipaddress, :port => 389, :auth => auth ) do |ldap|
    #    ldap.search( ... )
    #    ldap.add( ... )
    #    ldap.modify( ... )
    #  end
    #
    def LDAP::open args
      ldap1 = LDAP.new args
      ldap1.open {|ldap| yield ldap }
    end

    # Returns a meaningful result any time after
    # a protocol operation (#bind, #search, #add, #modify, #rename, #delete)
    # has completed.
    # It returns an #OpenStruct containing an LDAP result code (0 means success),
    # and a human-readable string.
    #  unless ldap.bind
    #    puts "Result: #{ldap.get_operation_result.code}"
    #    puts "Message: #{ldap.get_operation_result.message}"
    #  end
    #
    def get_operation_result
      os = OpenStruct.new
      if @result
        os.code = @result
      else
        os.code = 0
      end
      os.message = LDAP.result2string( os.code )
      os
    end


    # Opens a network connection to the server and then
    # passes <tt>self</tt> to the caller-supplied block. The connection is
    # closed when the block completes. Used for executing multiple
    # LDAP operations without requiring a separate network connection
    # (and authentication) for each one.
    # <i>Note:</i> You do not need to log-in or "bind" to the server. This will
    # be done for you automatically.
    # For an even simpler approach, see the class method Net::LDAP#open.
    #
    #  # (PSEUDOCODE)
    #  auth = {:method => :simple, :username => username, :password => password}
    #  ldap = Net::LDAP.new( :host => ipaddress, :port => 389, :auth => auth )
    #  ldap.open do |ldap|
    #    ldap.search( ... )
    #    ldap.add( ... )
    #    ldap.modify( ... )
    #  end
    #--
    # First we make a connection and then a binding, but we don't
    # do anything with the bind results.
    # We then pass self to the caller's block, where he will execute
    # his LDAP operations. Of course they will all generate auth failures
    # if the bind was unsuccessful.
    def open
      raise LdapError.new( "open already in progress" ) if @open_connection
      @open_connection = Connection.new( :host => @host, :port => @port, :encryption => @encryption )
      @open_connection.bind @auth
      yield self
      @open_connection.close
      @open_connection = nil
    end


    # Searches the LDAP directory for directory entries.
    # Takes a hash argument with parameters. Supported parameters include:
    # * :base (a string specifying the tree-base for the search);
    # * :filter (an object of type Net::LDAP::Filter, defaults to objectclass=*);
    # * :attributes (a string or array of strings specifying the LDAP attributes to return from the server);
    # * :return_result (a boolean specifying whether to return a result set).
    # * :attributes_only (a boolean flag, defaults false)
    # * :scope (one of: Net::LDAP::SearchScope_BaseObject, Net::LDAP::SearchScope_SingleLevel, Net::LDAP::SearchScope_WholeSubtree. Default is WholeSubtree.)
    #
    # #search queries the LDAP server and passes <i>each entry</i> to the
    # caller-supplied block, as an object of type Net::LDAP::Entry.
    # If the search returns 1000 entries, the block will
    # be called 1000 times. If the search returns no entries, the block will
    # not be called.
    #
    #--
    # ORIGINAL TEXT, replaced 04May06.
    # #search returns either a result-set or a boolean, depending on the
    # value of the <tt>:return_result</tt> argument. The default behavior is to return
    # a result set, which is a hash. Each key in the hash is a string specifying
    # the DN of an entry. The corresponding value for each key is a Net::LDAP::Entry object.
    # If you request a result set and #search fails with an error, it will return nil.
    # Call #get_operation_result to get the error information returned by
    # the LDAP server.
    #++
    # #search returns either a result-set or a boolean, depending on the
    # value of the <tt>:return_result</tt> argument. The default behavior is to return
    # a result set, which is an Array of objects of class Net::LDAP::Entry.
    # If you request a result set and #search fails with an error, it will return nil.
    # Call #get_operation_result to get the error information returned by
    # the LDAP server.
    #
    # When <tt>:return_result => false,</tt> #search will
    # return only a Boolean, to indicate whether the operation succeeded. This can improve performance
    # with very large result sets, because the library can discard each entry from memory after
    # your block processes it.
    #
    #
    #  treebase = "dc=example,dc=com"
    #  filter = Net::LDAP::Filter.eq( "mail", "a*.com" )
    #  attrs = ["mail", "cn", "sn", "objectclass"]
    #  ldap.search( :base => treebase, :filter => filter, :attributes => attrs, :return_result => false ) do |entry|
    #    puts "DN: #{entry.dn}"
    #    entry.each do |attr, values|
    #      puts ".......#{attr}:"
    #      values.each do |value|
    #        puts "          #{value}"
    #      end
    #    end
    #  end
    #
    #--
    # This is a re-implementation of search that replaces the
    # original one (now renamed searchx and possibly destined to go away).
    # The difference is that we return a dataset (or nil) from the
    # call, and pass _each entry_ as it is received from the server
    # to the caller-supplied block. This will probably make things
    # far faster as we can do useful work during the network latency
    # of the search. The downside is that we have no access to the
    # whole set while processing the blocks, so we can't do stuff
    # like sort the DNs until after the call completes.
    # It's also possible that this interacts badly with server timeouts.
    # We'll have to ensure that something reasonable happens if
    # the caller has processed half a result set when we throw a timeout
    # error.
    # Another important difference is that we return a result set from
    # this method rather than a T/F indication.
    # Since this can be very heavy-weight, we define an argument flag
    # that the caller can set to suppress the return of a result set,
    # if he's planning to process every entry as it comes from the server.
    #
    # REINTERPRETED the result set, 04May06. Originally this was a hash
    # of entries keyed by DNs. But let's get away from making users
    # handle DNs. Change it to a plain array. Eventually we may
    # want to return a Dataset object that delegates to an internal
    # array, so we can provide sort methods and what-not.
    #
    def search args = {}
      args[:base] ||= @base
      result_set = (args and args[:return_result] == false) ? nil : []

      if @open_connection
        @result = @open_connection.search( args ) {|entry|
          result_set << entry if result_set
          yield( entry ) if block_given?
        }
      else
        @result = 0
        conn = Connection.new( :host => @host, :port => @port, :encryption => @encryption )
        if (@result = conn.bind( args[:auth] || @auth )) == 0
          @result = conn.search( args ) {|entry|
            result_set << entry if result_set
            yield( entry ) if block_given?
          }
        end
        conn.close
      end

      @result == 0 and result_set
    end

    # #bind connects to an LDAP server and requests authentication
    # based on the <tt>:auth</tt> parameter passed to #open or #new.
    # It takes no parameters.
    #
    # User code does not need to call #bind directly. It will be called
    # implicitly by the library whenever you invoke an LDAP operation,
    # such as #search or #add.
    #
    # It is useful, however, to call #bind in your own code when the
    # only operation you intend to perform against the directory is
    # to validate a login credential. #bind returns true or false
    # to indicate whether the binding was successful. Reasons for
    # failure include malformed or unrecognized usernames and
    # incorrect passwords. Use #get_operation_result to find out
    # what happened in case of failure.
    #
    # Here's a typical example using #bind to authenticate a
    # credential which was (perhaps) solicited from the user of a
    # web site:
    #
    #  require 'net/ldap'
    #  ldap = Net::LDAP.new
    #  ldap.host = your_server_ip_address
    #  ldap.port = 389
    #  ldap.auth your_user_name, your_user_password
    #  if ldap.bind
    #    # authentication succeeded
    #  else
    #    # authentication failed
    #    p ldap.get_operation_result
    #  end
    #
    # You don't have to create a new instance of Net::LDAP every time
    # you perform a binding in this way. If you prefer, you can cache the Net::LDAP object
    # and re-use it to perform subsequent bindings, <i>provided</i> you call
    # #auth to specify a new credential before calling #bind. Otherwise, you'll
    # just re-authenticate the previous user! (You don't need to re-set
    # the values of #host and #port.) As noted in the documentation for #auth,
    # the password parameter can be a Ruby Proc instead of a String.
    #
    #--
    # If there is an @open_connection, then perform the bind
    # on it. Otherwise, connect, bind, and disconnect.
    # The latter operation is obviously useful only as an auth check.
    #
    def bind auth=@auth
      if @open_connection
        @result = @open_connection.bind auth
      else
        conn = Connection.new( :host => @host, :port => @port , :encryption => @encryption)
        @result = conn.bind @auth
        conn.close
      end

      @result == 0
    end

    #
    # #bind_as is for testing authentication credentials.
    #
    # As described under #bind, most LDAP servers require that you supply a complete DN
    # as a binding-credential, along with an authenticator such as a password.
    # But for many applications (such as authenticating users to a Rails application),
    # you often don't have a full DN to identify the user. You usually get a simple
    # identifier like a username or an email address, along with a password.
    # #bind_as allows you to authenticate these user-identifiers.
    #
    # #bind_as is a combination of a search and an LDAP binding. First, it connects and
    # binds to the directory as normal. Then it searches the directory for an entry
    # corresponding to the email address, username, or other string that you supply.
    # If the entry exists, then #bind_as will <b>re-bind</b> as that user with the
    # password (or other authenticator) that you supply.
    #
    # #bind_as takes the same parameters as #search, <i>with the addition of an
    # authenticator.</i> Currently, this authenticator must be <tt>:password</tt>.
    # Its value may be either a String, or a +proc+ that returns a String.
    # #bind_as returns +false+ on failure. On success, it returns a result set,
    # just as #search does. This result set is an Array of objects of
    # type Net::LDAP::Entry. It contains the directory attributes corresponding to
    # the user. (Just test whether the return value is logically true, if you don't
    # need this additional information.)
    #
    # Here's how you would use #bind_as to authenticate an email address and password:
    #
    #  require 'net/ldap'
    #  
    #  user,psw = "joe_user@yourcompany.com", "joes_psw"
    #  
    #  ldap = Net::LDAP.new
    #  ldap.host = "192.168.0.100"
    #  ldap.port = 389
    #  ldap.auth "cn=manager,dc=yourcompany,dc=com", "topsecret"
    #  
    #  result = ldap.bind_as(
    #    :base => "dc=yourcompany,dc=com",
    #    :filter => "(mail=#{user})",
    #    :password => psw
    #  )
    #  if result
    #    puts "Authenticated #{result.first.dn}"
    #  else
    #    puts "Authentication FAILED."
    #  end
    def bind_as args={}
      result = false
      open {|me|
        rs = search args
        if rs and rs.first and dn = rs.first.dn
          password = args[:password]
          password = password.call if password.respond_to?(:call)
          result = rs if bind :method => :simple, :username => dn, :password => password
        end
      }
      result
    end


    # Adds a new entry to the remote LDAP server.
    # Supported arguments:
    # :dn :: Full DN of the new entry
    # :attributes :: Attributes of the new entry.
    #
    # The attributes argument is supplied as a Hash keyed by Strings or Symbols
    # giving the attribute name, and mapping to Strings or Arrays of Strings
    # giving the actual attribute values. Observe that most LDAP directories
    # enforce schema constraints on the attributes contained in entries.
    # #add will fail with a server-generated error if your attributes violate
    # the server-specific constraints.
    # Here's an example:
    #
    #  dn = "cn=George Smith,ou=people,dc=example,dc=com"
    #  attr = {
    #    :cn => "George Smith",
    #    :objectclass => ["top", "inetorgperson"],
    #    :sn => "Smith",
    #    :mail => "gsmith@example.com"
    #  }
    #  Net::LDAP.open (:host => host) do |ldap|
    #    ldap.add( :dn => dn, :attributes => attr )
    #  end
    #
    def add args
      if @open_connection
          @result = @open_connection.add( args )
      else
        @result = 0
        conn = Connection.new( :host => @host, :port => @port, :encryption => @encryption)
        if (@result = conn.bind( args[:auth] || @auth )) == 0
          @result = conn.add( args )
        end
        conn.close
      end
      @result == 0
    end


    # Modifies the attribute values of a particular entry on the LDAP directory.
    # Takes a hash with arguments. Supported arguments are:
    # :dn :: (the full DN of the entry whose attributes are to be modified)
    # :operations :: (the modifications to be performed, detailed next)
    #
    # This method returns True or False to indicate whether the operation
    # succeeded or failed, with extended information available by calling
    # #get_operation_result.
    #
    # Also see #add_attribute, #replace_attribute, or #delete_attribute, which
    # provide simpler interfaces to this functionality.
    #
    # The LDAP protocol provides a full and well thought-out set of operations
    # for changing the values of attributes, but they are necessarily somewhat complex
    # and not always intuitive. If these instructions are confusing or incomplete,
    # please send us email or create a bug report on rubyforge.
    #
    # The :operations parameter to #modify takes an array of operation-descriptors.
    # Each individual operation is specified in one element of the array, and
    # most LDAP servers will attempt to perform the operations in order.
    #
    # Each of the operations appearing in the Array must itself be an Array
    # with exactly three elements:
    # an operator:: must be :add, :replace, or :delete
    # an attribute name:: the attribute name (string or symbol) to modify
    # a value:: either a string or an array of strings.
    #
    # The :add operator will, unsurprisingly, add the specified values to
    # the specified attribute. If the attribute does not already exist,
    # :add will create it. Most LDAP servers will generate an error if you
    # try to add a value that already exists.
    #
    # :replace will erase the current value(s) for the specified attribute,
    # if there are any, and replace them with the specified value(s).
    #
    # :delete will remove the specified value(s) from the specified attribute.
    # If you pass nil, an empty string, or an empty array as the value parameter
    # to a :delete operation, the _entire_ _attribute_ will be deleted, along
    # with all of its values.
    #
    # For example:
    #
    #  dn = "mail=modifyme@example.com,ou=people,dc=example,dc=com"
    #  ops = [
    #    [:add, :mail, "aliasaddress@example.com"],
    #    [:replace, :mail, ["newaddress@example.com", "newalias@example.com"]],
    #    [:delete, :sn, nil]
    #  ]
    #  ldap.modify :dn => dn, :operations => ops
    #
    # <i>(This example is contrived since you probably wouldn't add a mail
    # value right before replacing the whole attribute, but it shows that order
    # of execution matters. Also, many LDAP servers won't let you delete SN
    # because that would be a schema violation.)</i>
    #
    # It's essential to keep in mind that if you specify more than one operation in
    # a call to #modify, most LDAP servers will attempt to perform all of the operations
    # in the order you gave them.
    # This matters because you may specify operations on the
    # same attribute which must be performed in a certain order.
    #
    # Most LDAP servers will _stop_ processing your modifications if one of them
    # causes an error on the server (such as a schema-constraint violation).
    # If this happens, you will probably get a result code from the server that
    # reflects only the operation that failed, and you may or may not get extended
    # information that will tell you which one failed. #modify has no notion
    # of an atomic transaction. If you specify a chain of modifications in one
    # call to #modify, and one of them fails, the preceding ones will usually
    # not be "rolled back," resulting in a partial update. This is a limitation
    # of the LDAP protocol, not of Net::LDAP.
    #
    # The lack of transactional atomicity in LDAP means that you're usually
    # better off using the convenience methods #add_attribute, #replace_attribute,
    # and #delete_attribute, which are are wrappers over #modify. However, certain
    # LDAP servers may provide concurrency semantics, in which the several operations
    # contained in a single #modify call are not interleaved with other
    # modification-requests received simultaneously by the server.
    # It bears repeating that this concurrency does _not_ imply transactional
    # atomicity, which LDAP does not provide.
    #
    def modify args
      if @open_connection
          @result = @open_connection.modify( args )
      else
        @result = 0
        conn = Connection.new( :host => @host, :port => @port, :encryption => @encryption )
        if (@result = conn.bind( args[:auth] || @auth )) == 0
          @result = conn.modify( args )
        end
        conn.close
      end
      @result == 0
    end


    # Add a value to an attribute.
    # Takes the full DN of the entry to modify,
    # the name (Symbol or String) of the attribute, and the value (String or
    # Array). If the attribute does not exist (and there are no schema violations),
    # #add_attribute will create it with the caller-specified values.
    # If the attribute already exists (and there are no schema violations), the
    # caller-specified values will be _added_ to the values already present.
    #
    # Returns True or False to indicate whether the operation
    # succeeded or failed, with extended information available by calling
    # #get_operation_result. See also #replace_attribute and #delete_attribute.
    #
    #  dn = "cn=modifyme,dc=example,dc=com"
    #  ldap.add_attribute dn, :mail, "newmailaddress@example.com"
    #
    def add_attribute dn, attribute, value
      modify :dn => dn, :operations => [[:add, attribute, value]]
    end

    # Replace the value of an attribute.
    # #replace_attribute can be thought of as equivalent to calling #delete_attribute
    # followed by #add_attribute. It takes the full DN of the entry to modify,
    # the name (Symbol or String) of the attribute, and the value (String or
    # Array). If the attribute does not exist, it will be created with the
    # caller-specified value(s). If the attribute does exist, its values will be
    # _discarded_ and replaced with the caller-specified values.
    #
    # Returns True or False to indicate whether the operation
    # succeeded or failed, with extended information available by calling
    # #get_operation_result. See also #add_attribute and #delete_attribute.
    #
    #  dn = "cn=modifyme,dc=example,dc=com"
    #  ldap.replace_attribute dn, :mail, "newmailaddress@example.com"
    #
    def replace_attribute dn, attribute, value
      modify :dn => dn, :operations => [[:replace, attribute, value]]
    end

    # Delete an attribute and all its values.
    # Takes the full DN of the entry to modify, and the
    # name (Symbol or String) of the attribute to delete.
    #
    # Returns True or False to indicate whether the operation
    # succeeded or failed, with extended information available by calling
    # #get_operation_result. See also #add_attribute and #replace_attribute.
    #
    #  dn = "cn=modifyme,dc=example,dc=com"
    #  ldap.delete_attribute dn, :mail
    #
    def delete_attribute dn, attribute
      modify :dn => dn, :operations => [[:delete, attribute, nil]]
    end


    # Rename an entry on the remote DIS by changing the last RDN of its DN.
    # _Documentation_ _stub_
    #
    def rename args
      if @open_connection
          @result = @open_connection.rename( args )
      else
        @result = 0
        conn = Connection.new( :host => @host, :port => @port, :encryption => @encryption )
        if (@result = conn.bind( args[:auth] || @auth )) == 0
          @result = conn.rename( args )
        end
        conn.close
      end
      @result == 0
    end

    # modify_rdn is an alias for #rename.
    def modify_rdn args
      rename args
    end

    # Delete an entry from the LDAP directory.
    # Takes a hash of arguments.
    # The only supported argument is :dn, which must
    # give the complete DN of the entry to be deleted.
    # Returns True or False to indicate whether the delete
    # succeeded. Extended status information is available by
    # calling #get_operation_result.
    #
    #  dn = "mail=deleteme@example.com,ou=people,dc=example,dc=com"
    #  ldap.delete :dn => dn
    #
    def delete args
      if @open_connection
          @result = @open_connection.delete( args )
      else
        @result = 0
        conn = Connection.new( :host => @host, :port => @port, :encryption => @encryption )
        if (@result = conn.bind( args[:auth] || @auth )) == 0
          @result = conn.delete( args )
        end
        conn.close
      end
      @result == 0
    end

  end # class LDAP



  class LDAP
  # This is a private class used internally by the library. It should not be called by user code.
  class Connection # :nodoc:

    LdapVersion = 3


    #--
    # initialize
    #
    def initialize server
      begin
        @conn = TCPsocket.new( server[:host], server[:port] )
      rescue
        raise LdapError.new( "no connection to server" )
      end

      if server[:encryption]
        setup_encryption server[:encryption]
      end

      yield self if block_given?
    end


    #--
    # Helper method called only from new, and only after we have a successfully-opened
    # @conn instance variable, which is a TCP connection.
    # Depending on the received arguments, we establish SSL, potentially replacing
    # the value of @conn accordingly.
    # Don't generate any errors here if no encryption is requested.
    # DO raise LdapError objects if encryption is requested and we have trouble setting
    # it up. That includes if OpenSSL is not set up on the machine. (Question:
    # how does the Ruby OpenSSL wrapper react in that case?)
    # DO NOT filter exceptions raised by the OpenSSL library. Let them pass back
    # to the user. That should make it easier for us to debug the problem reports.
    # Presumably (hopefully?) that will also produce recognizable errors if someone
    # tries to use this on a machine without OpenSSL.
    #
    # The simple_tls method is intended as the simplest, stupidest, easiest solution
    # for people who want nothing more than encrypted comms with the LDAP server.
    # It doesn't do any server-cert validation and requires nothing in the way
    # of key files and root-cert files, etc etc.
    # OBSERVE: WE REPLACE the value of @conn, which is presumed to be a connected
    # TCPsocket object.
    #
    def setup_encryption args
      case args[:method]
      when :simple_tls
        raise LdapError.new("openssl unavailable") unless $net_ldap_openssl_available
        ctx = OpenSSL::SSL::SSLContext.new
        @conn = OpenSSL::SSL::SSLSocket.new(@conn, ctx)
        @conn.connect
        @conn.sync_close = true
      # additional branches requiring server validation and peer certs, etc. go here.
      else
        raise LdapError.new( "unsupported encryption method #{args[:method]}" )
      end
    end

    #--
    # close
    # This is provided as a convenience method to make
    # sure a connection object gets closed without waiting
    # for a GC to happen. Clients shouldn't have to call it,
    # but perhaps it will come in handy someday.
    def close
      @conn.close
      @conn = nil
    end

    #--
    # next_msgid
    #
    def next_msgid
      @msgid ||= 0
      @msgid += 1
    end


    #--
    # bind
    #
    def bind auth
      user,psw = case auth[:method]
      when :anonymous
        ["",""]
      when :simple
        [auth[:username] || auth[:dn], auth[:password]]
      end
      raise LdapError.new( "invalid binding information" ) unless (user && psw)

      msgid = next_msgid.to_ber
      request = [LdapVersion.to_ber, user.to_ber, psw.to_ber_contextspecific(0)].to_ber_appsequence(0)
      request_pkt = [msgid, request].to_ber_sequence
      @conn.write request_pkt

      (be = @conn.read_ber(AsnSyntax) and pdu = Net::LdapPdu.new( be )) or raise LdapError.new( "no bind result" )
      pdu.result_code
    end

    #--
    # search
    # Alternate implementation, this yields each search entry to the caller
    # as it are received.
    # TODO, certain search parameters are hardcoded.
    # TODO, if we mis-parse the server results or the results are wrong, we can block
    # forever. That's because we keep reading results until we get a type-5 packet,
    # which might never come. We need to support the time-limit in the protocol.
    #--
    # WARNING: this code substantially recapitulates the searchx method.
    #
    # 02May06: Well, I added support for RFC-2696-style paged searches.
    # This is used on all queries because the extension is marked non-critical.
    # As far as I know, only A/D uses this, but it's required for A/D. Otherwise
    # you won't get more than 1000 results back from a query.
    # This implementation is kindof clunky and should probably be refactored.
    # Also, is it my imagination, or are A/Ds the slowest directory servers ever???
    #
    def search args = {}
      search_filter = (args && args[:filter]) || Filter.eq( "objectclass", "*" )
      search_filter = Filter.construct(search_filter) if search_filter.is_a?(String)
      search_base = (args && args[:base]) || "dc=example,dc=com"
      search_attributes = ((args && args[:attributes]) || []).map {|attr| attr.to_s.to_ber}
      return_referrals = args && args[:return_referrals] == true

      attributes_only = (args and args[:attributes_only] == true)
      scope = args[:scope] || Net::LDAP::SearchScope_WholeSubtree
      raise LdapError.new( "invalid search scope" ) unless SearchScopes.include?(scope)

      # An interesting value for the size limit would be close to A/D's built-in
      # page limit of 1000 records, but openLDAP newer than version 2.2.0 chokes
      # on anything bigger than 126. You get a silent error that is easily visible
      # by running slapd in debug mode. Go figure.
      rfc2696_cookie = [126, ""]
      result_code = 0

      loop {
        # should collect this into a private helper to clarify the structure

        request = [
          search_base.to_ber,
          scope.to_ber_enumerated,
          0.to_ber_enumerated,
          0.to_ber,
          0.to_ber,
          attributes_only.to_ber,
          search_filter.to_ber,
          search_attributes.to_ber_sequence
        ].to_ber_appsequence(3)
  
        controls = [
          [
          LdapControls::PagedResults.to_ber,
          false.to_ber, # criticality MUST be false to interoperate with normal LDAPs.
          rfc2696_cookie.map{|v| v.to_ber}.to_ber_sequence.to_s.to_ber
          ].to_ber_sequence
        ].to_ber_contextspecific(0)

        pkt = [next_msgid.to_ber, request, controls].to_ber_sequence
        @conn.write pkt

        result_code = 0
        controls = []

        while (be = @conn.read_ber(AsnSyntax)) && (pdu = LdapPdu.new( be ))
          case pdu.app_tag
          when 4 # search-data
            yield( pdu.search_entry ) if block_given?
          when 19 # search-referral
            if return_referrals
              if block_given?
                se = Net::LDAP::Entry.new
                se[:search_referrals] = (pdu.search_referrals || [])
                yield se
              end
            end
            #p pdu.referrals
          when 5 # search-result
            result_code = pdu.result_code
            controls = pdu.result_controls
            break
          else
            raise LdapError.new( "invalid response-type in search: #{pdu.app_tag}" )
          end
        end

        # When we get here, we have seen a type-5 response.
        # If there is no error AND there is an RFC-2696 cookie,
        # then query again for the next page of results.
        # If not, we're done.
        # Don't screw this up or we'll break every search we do.
        more_pages = false
        if result_code == 0 and controls
          controls.each do |c|
            if c.oid == LdapControls::PagedResults
              more_pages = false # just in case some bogus server sends us >1 of these.
              if c.value and c.value.length > 0
                cookie = c.value.read_ber[1]
                if cookie and cookie.length > 0
                  rfc2696_cookie[1] = cookie
                  more_pages = true
                end
              end
            end
          end
        end

        break unless more_pages
      } # loop

      result_code
    end




    #--
    # modify
    # TODO, need to support a time limit, in case the server fails to respond.
    # TODO!!! We're throwing an exception here on empty DN.
    # Should return a proper error instead, probaby from farther up the chain.
    # TODO!!! If the user specifies a bogus opcode, we'll throw a
    # confusing error here ("to_ber_enumerated is not defined on nil").
    #
    def modify args
      modify_dn = args[:dn] or raise "Unable to modify empty DN"
      modify_ops = []
      a = args[:operations] and a.each {|op, attr, values|
        # TODO, fix the following line, which gives a bogus error
        # if the opcode is invalid.
        op_1 = {:add => 0, :delete => 1, :replace => 2} [op.to_sym].to_ber_enumerated
        modify_ops << [op_1, [attr.to_s.to_ber, values.to_a.map {|v| v.to_ber}.to_ber_set].to_ber_sequence].to_ber_sequence
      }

      request = [modify_dn.to_ber, modify_ops.to_ber_sequence].to_ber_appsequence(6)
      pkt = [next_msgid.to_ber, request].to_ber_sequence
      @conn.write pkt

      (be = @conn.read_ber(AsnSyntax)) && (pdu = LdapPdu.new( be )) && (pdu.app_tag == 7) or raise LdapError.new( "response missing or invalid" )
      pdu.result_code
    end


    #--
    # add
    # TODO, need to support a time limit, in case the server fails to respond.
    #
    def add args
      add_dn = args[:dn] or raise LdapError.new("Unable to add empty DN")
      add_attrs = []
      a = args[:attributes] and a.each {|k,v|
        add_attrs << [ k.to_s.to_ber, v.to_a.map {|m| m.to_ber}.to_ber_set ].to_ber_sequence
      }

      request = [add_dn.to_ber, add_attrs.to_ber_sequence].to_ber_appsequence(8)
      pkt = [next_msgid.to_ber, request].to_ber_sequence
      @conn.write pkt

      (be = @conn.read_ber(AsnSyntax)) && (pdu = LdapPdu.new( be )) && (pdu.app_tag == 9) or raise LdapError.new( "response missing or invalid" )
      pdu.result_code
    end


    #--
    # rename
    # TODO, need to support a time limit, in case the server fails to respond.
    #
    def rename args
      old_dn = args[:olddn] or raise "Unable to rename empty DN"
      new_rdn = args[:newrdn] or raise "Unable to rename to empty RDN"
      delete_attrs = args[:delete_attributes] ? true : false

      request = [old_dn.to_ber, new_rdn.to_ber, delete_attrs.to_ber].to_ber_appsequence(12)
      pkt = [next_msgid.to_ber, request].to_ber_sequence
      @conn.write pkt

      (be = @conn.read_ber(AsnSyntax)) && (pdu = LdapPdu.new( be )) && (pdu.app_tag == 13) or raise LdapError.new( "response missing or invalid" )
      pdu.result_code
    end


    #--
    # delete
    # TODO, need to support a time limit, in case the server fails to respond.
    #
    def delete args
      dn = args[:dn] or raise "Unable to delete empty DN"

      request = dn.to_s.to_ber_application_string(10)
      pkt = [next_msgid.to_ber, request].to_ber_sequence
      @conn.write pkt

      (be = @conn.read_ber(AsnSyntax)) && (pdu = LdapPdu.new( be )) && (pdu.app_tag == 11) or raise LdapError.new( "response missing or invalid" )
      pdu.result_code
    end


  end # class Connection
  end # class LDAP


end # module Net


