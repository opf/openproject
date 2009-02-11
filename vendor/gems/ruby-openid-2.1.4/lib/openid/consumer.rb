require "openid/consumer/idres.rb"
require "openid/consumer/checkid_request.rb"
require "openid/consumer/associationmanager.rb"
require "openid/consumer/responses.rb"
require "openid/consumer/discovery_manager"
require "openid/consumer/discovery"
require "openid/message"
require "openid/yadis/discovery"
require "openid/store/nonce"

module OpenID
  # OpenID support for Relying Parties (aka Consumers).
  #
  # This module documents the main interface with the OpenID consumer
  # library.  The only part of the library which has to be used and
  # isn't documented in full here is the store required to create an
  # Consumer instance.
  #
  # = OVERVIEW
  #
  # The OpenID identity verification process most commonly uses the
  # following steps, as visible to the user of this library:
  #
  # 1. The user enters their OpenID into a field on the consumer's
  #    site, and hits a login button.
  #
  # 2. The consumer site discovers the user's OpenID provider using
  #    the Yadis protocol.
  #
  # 3. The consumer site sends the browser a redirect to the OpenID
  #    provider.  This is the authentication request as described in
  #    the OpenID specification.
  #
  # 4. The OpenID provider's site sends the browser a redirect back to
  #    the consumer site.  This redirect contains the provider's
  #    response to the authentication request.
  #
  # The most important part of the flow to note is the consumer's site
  # must handle two separate HTTP requests in order to perform the
  # full identity check.
  #
  # = LIBRARY DESIGN
  #
  # This consumer library is designed with that flow in mind.  The
  # goal is to make it as easy as possible to perform the above steps
  # securely.
  #
  # At a high level, there are two important parts in the consumer
  # library.  The first important part is this module, which contains
  # the interface to actually use this library.  The second is
  # openid/store/interface.rb, which describes the interface to use if
  # you need to create a custom method for storing the state this
  # library needs to maintain between requests.
  #
  # In general, the second part is less important for users of the
  # library to know about, as several implementations are provided
  # which cover a wide variety of situations in which consumers may
  # use the library.
  #
  # The Consumer class has methods corresponding to the actions
  # necessary in each of steps 2, 3, and 4 described in the overview.
  # Use of this library should be as easy as creating an Consumer
  # instance and calling the methods appropriate for the action the
  # site wants to take.
  #
  # This library automatically detects which version of the OpenID
  # protocol should be used for a transaction and constructs the
  # proper requests and responses.  Users of this library do not need
  # to worry about supporting multiple protocol versions; the library
  # supports them implicitly.  Depending on the version of the
  # protocol in use, the OpenID transaction may be more secure.  See
  # the OpenID specifications for more information.
  #
  # = SESSIONS, STORES, AND STATELESS MODE
  #
  # The Consumer object keeps track of two types of state:
  #
  # 1. State of the user's current authentication attempt.  Things
  #    like the identity URL, the list of endpoints discovered for
  #    that URL, and in case where some endpoints are unreachable, the
  #    list of endpoints already tried.  This state needs to be held
  #    from Consumer.begin() to Consumer.complete(), but it is only
  #    applicable to a single session with a single user agent, and at
  #    the end of the authentication process (i.e. when an OP replies
  #    with either <tt>id_res</tt>. or <tt>cancel</tt> it may be
  #    discarded.
  #
  # 2. State of relationships with servers, i.e. shared secrets
  #    (associations) with servers and nonces seen on signed messages.
  #    This information should persist from one session to the next
  #    and should not be bound to a particular user-agent.
  #
  # These two types of storage are reflected in the first two
  # arguments of Consumer's constructor, <tt>session</tt> and
  # <tt>store</tt>.  <tt>session</tt> is a dict-like object and we
  # hope your web framework provides you with one of these bound to
  # the user agent.  <tt>store</tt> is an instance of Store.
  #
  # Since the store does hold secrets shared between your application
  # and the OpenID provider, you should be careful about how you use
  # it in a shared hosting environment.  If the filesystem or database
  # permissions of your web host allow strangers to read from them, do
  # not store your data there!  If you have no safe place to store
  # your data, construct your consumer with nil for the store, and it
  # will operate only in stateless mode.  Stateless mode may be
  # slower, put more load on the OpenID provider, and trusts the
  # provider to keep you safe from replay attacks.
  #
  # Several store implementation are provided, and the interface is
  # fully documented so that custom stores can be used as well.  See
  # the documentation for the Consumer class for more information on
  # the interface for stores.  The implementations that are provided
  # allow the consumer site to store the necessary data in several
  # different ways, including several SQL databases and normal files
  # on disk.
  #
  # = IMMEDIATE MODE
  #
  # In the flow described above, the user may need to confirm to the
  # OpenID provider that it's ok to disclose his or her identity.  The
  # provider may draw pages asking for information from the user
  # before it redirects the browser back to the consumer's site.  This
  # is generally transparent to the consumer site, so it is typically
  # ignored as an implementation detail.
  #
  # There can be times, however, where the consumer site wants to get
  # a response immediately.  When this is the case, the consumer can
  # put the library in immediate mode.  In immediate mode, there is an
  # extra response possible from the server, which is essentially the
  # server reporting that it doesn't have enough information to answer
  # the question yet.
  #
  # = USING THIS LIBRARY
  #
  # Integrating this library into an application is usually a
  # relatively straightforward process.  The process should basically
  # follow this plan:
  #
  # Add an OpenID login field somewhere on your site.  When an OpenID
  # is entered in that field and the form is submitted, it should make
  # a request to the your site which includes that OpenID URL.
  #
  # First, the application should instantiate a Consumer with a
  # session for per-user state and store for shared state using the
  # store of choice.
  #
  # Next, the application should call the <tt>begin</tt> method of
  # Consumer instance.  This method takes the OpenID URL as entered by
  # the user.  The <tt>begin</tt> method returns a CheckIDRequest
  # object.
  #
  # Next, the application should call the redirect_url method on the
  # CheckIDRequest object.  The parameter <tt>return_to</tt> is the
  # URL that the OpenID server will send the user back to after
  # attempting to verify his or her identity.  The <tt>realm</tt>
  # parameter is the URL (or URL pattern) that identifies your web
  # site to the user when he or she is authorizing it.  Send a
  # redirect to the resulting URL to the user's browser.
  #
  # That's the first half of the authentication process.  The second
  # half of the process is done after the user's OpenID Provider sends
  # the user's browser a redirect back to your site to complete their
  # login.
  #
  # When that happens, the user will contact your site at the URL
  # given as the <tt>return_to</tt> URL to the redirect_url call made
  # above.  The request will have several query parameters added to
  # the URL by the OpenID provider as the information necessary to
  # finish the request.
  #
  # Get a Consumer instance with the same session and store as before
  # and call its complete() method, passing in all the received query
  # arguments and URL currently being handled.
  #
  # There are multiple possible return types possible from that
  # method. These indicate the whether or not the login was
  # successful, and include any additional information appropriate for
  # their type.
  class Consumer
    attr_accessor :session_key_prefix

    # Initialize a Consumer instance.
    #
    # You should create a new instance of the Consumer object with
    # every HTTP request that handles OpenID transactions.
    #
    # session: the session object to use to store request information.
    # The session should behave like a hash.
    #
    # store: an object that implements the interface in Store.
    def initialize(session, store)
      @session = session
      @store = store
      @session_key_prefix = 'OpenID::Consumer::'
    end

    # Start the OpenID authentication process. See steps 1-2 in the
    # overview for the Consumer class.
    #
    # user_url: Identity URL given by the user. This method performs a
    # textual transformation of the URL to try and make sure it is
    # normalized. For example, a user_url of example.com will be
    # normalized to http://example.com/ normalizing and resolving any
    # redirects the server might issue.
    #
    # anonymous: A boolean value.  Whether to make an anonymous
    # request of the OpenID provider.  Such a request does not ask for
    # an authorization assertion for an OpenID identifier, but may be
    # used with extensions to pass other data.  e.g. "I don't care who
    # you are, but I'd like to know your time zone."
    #
    # Returns a CheckIDRequest object containing the discovered
    # information, with a method for building a redirect URL to the
    # server, as described in step 3 of the overview. This object may
    # also be used to add extension arguments to the request, using
    # its add_extension_arg method.
    #
    # Raises DiscoveryFailure when no OpenID server can be found for
    # this URL.
    def begin(openid_identifier, anonymous=false)
      manager = discovery_manager(openid_identifier)
      service = manager.get_next_service(&method(:discover))

      if service.nil?
        raise DiscoveryFailure.new("No usable OpenID services were found "\
                                   "for #{openid_identifier.inspect}", nil)
      else
        begin_without_discovery(service, anonymous)
      end
    end

    # Start OpenID verification without doing OpenID server
    # discovery. This method is used internally by Consumer.begin()
    # after discovery is performed, and exists to provide an interface
    # for library users needing to perform their own discovery.
    #
    # service: an OpenID service endpoint descriptor.  This object and
    # factories for it are found in the openid/consumer/discovery.rb
    # module.
    #
    # Returns an OpenID authentication request object.
    def begin_without_discovery(service, anonymous)
      assoc = association_manager(service).get_association
      checkid_request = CheckIDRequest.new(assoc, service)
      checkid_request.anonymous = anonymous

      if service.compatibility_mode
        rt_args = checkid_request.return_to_args
        rt_args[Consumer.openid1_return_to_nonce_name] = Nonce.mk_nonce
        rt_args[Consumer.openid1_return_to_claimed_id_name] =
          service.claimed_id
      end

      self.last_requested_endpoint = service
      return checkid_request
    end

    # Called to interpret the server's response to an OpenID
    # request. It is called in step 4 of the flow described in the
    # Consumer overview.
    #
    # query: A hash of the query parameters for this HTTP request.
    # Note that in rails, this is <b>not</b> <tt>params</tt> but
    # <tt>params.reject{|k,v|request.path_parameters[k]}</tt>
    # because <tt>controller</tt> and <tt>action</tt> and other
    # "path parameters" are included in params.
    #
    # current_url: Extract the URL of the current request from your
    # application's web request framework and specify it here to have it
    # checked against the openid.return_to value in the response.  Do not
    # just pass <tt>args['openid.return_to']</tt> here; that will defeat the
    # purpose of this check.  (See OpenID Authentication 2.0 section 11.1.)
    #
    # If the return_to URL check fails, the status of the completion will be
    # FAILURE.

    #
    # Returns a subclass of Response. The type of response is
    # indicated by the status attribute, which will be one of
    # SUCCESS, CANCEL, FAILURE, or SETUP_NEEDED.
    def complete(query, current_url)
      message = Message.from_post_args(query)
      mode = message.get_arg(OPENID_NS, 'mode', 'invalid')
      begin
        meth = method('complete_' + mode)
      rescue NameError
        meth = method(:complete_invalid)
      end
      response = meth.call(message, current_url)
      cleanup_last_requested_endpoint
      if [SUCCESS, CANCEL].member?(response.status)
        cleanup_session
      end
      return response
    end

    protected

    def session_get(name)
      @session[session_key(name)]
    end

    def session_set(name, val)
      @session[session_key(name)] = val
    end

    def session_key(suffix)
      @session_key_prefix + suffix
    end

    def last_requested_endpoint
      session_get('last_requested_endpoint')
    end

    def last_requested_endpoint=(endpoint)
      session_set('last_requested_endpoint', endpoint)
    end

    def cleanup_last_requested_endpoint
      @session[session_key('last_requested_endpoint')] = nil
    end

    def discovery_manager(openid_identifier)
      DiscoveryManager.new(@session, openid_identifier, @session_key_prefix)
    end

    def cleanup_session
      discovery_manager(nil).cleanup(true)
    end


    def discover(identifier)
      OpenID.discover(identifier)
    end

    def negotiator
      DefaultNegotiator
    end

    def association_manager(service)
      AssociationManager.new(@store, service.server_url,
                             service.compatibility_mode, negotiator)
    end

    def handle_idres(message, current_url)
      IdResHandler.new(message, current_url, @store, last_requested_endpoint)
    end

    def complete_invalid(message, unused_return_to)
      mode = message.get_arg(OPENID_NS, 'mode', '<No mode set>')
      return FailureResponse.new(last_requested_endpoint,
                                 "Invalid openid.mode: #{mode}")
    end

    def complete_cancel(unused_message, unused_return_to)
      return CancelResponse.new(last_requested_endpoint)
    end

    def complete_error(message, unused_return_to)
      error = message.get_arg(OPENID_NS, 'error')
      contact = message.get_arg(OPENID_NS, 'contact')
      reference = message.get_arg(OPENID_NS, 'reference')

      return FailureResponse.new(last_requested_endpoint,
                                 error, contact, reference)
    end

    def complete_setup_needed(message, unused_return_to)
      if message.is_openid1
        return complete_invalid(message, nil)
      else
        setup_url = message.get_arg(OPENID2_NS, 'user_setup_url')
        return SetupNeededResponse.new(last_requested_endpoint, setup_url)
      end
    end

    def complete_id_res(message, current_url)
      if message.is_openid1
        setup_url = message.get_arg(OPENID1_NS, 'user_setup_url')
        if !setup_url.nil?
          return SetupNeededResponse.new(last_requested_endpoint, setup_url)
        end
      end

      begin
        idres = handle_idres(message, current_url)
      rescue OpenIDError => why
        return FailureResponse.new(last_requested_endpoint, why.message)
      else
        return SuccessResponse.new(idres.endpoint, message,
                                     idres.signed_fields)
      end
    end
  end
end
