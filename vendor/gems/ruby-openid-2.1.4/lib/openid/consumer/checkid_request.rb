require "openid/message"
require "openid/util"

module OpenID
  class Consumer
    # An object that holds the state necessary for generating an
    # OpenID authentication request. This object holds the association
    # with the server and the discovered information with which the
    # request will be made.
    #
    # It is separate from the consumer because you may wish to add
    # things to the request before sending it on its way to the
    # server. It also has serialization options that let you encode
    # the authentication request as a URL or as a form POST.
    class CheckIDRequest
      attr_accessor :return_to_args, :message
      attr_reader :endpoint

      # Users of this library should not create instances of this
      # class.  Instances of this class are created by the library
      # when needed.
      def initialize(assoc, endpoint)
        @assoc = assoc
        @endpoint = endpoint
        @return_to_args = {}
        @message = Message.new(endpoint.preferred_namespace)
        @anonymous = false
      end

      attr_reader :anonymous

      # Set whether this request should be made anonymously. If a
      # request is anonymous, the identifier will not be sent in the
      # request. This is only useful if you are making another kind of
      # request with an extension in this request.
      #
      # Anonymous requests are not allowed when the request is made
      # with OpenID 1.
      def anonymous=(is_anonymous)
        if is_anonymous && @message.is_openid1
          raise ArgumentError, ("OpenID1 requests MUST include the "\
                                "identifier in the request")
        end
        @anonymous = is_anonymous
      end

      # Add an object that implements the extension interface for
      # adding arguments to an OpenID message to this checkid request.
      #
      # extension_request: an OpenID::Extension object.
      def add_extension(extension_request)
        extension_request.to_message(@message)
      end

      # Add an extension argument to this OpenID authentication
      # request. You probably want to use add_extension and the
      # OpenID::Extension interface.
      #
      # Use caution when adding arguments, because they will be
      # URL-escaped and appended to the redirect URL, which can easily
      # get quite long.
      def add_extension_arg(namespace, key, value)
        @message.set_arg(namespace, key, value)
      end

      # Produce a OpenID::Message representing this request.
      #
      # Not specifying a return_to URL means that the user will not be
      # returned to the site issuing the request upon its completion.
      #
      # If immediate mode is requested, the OpenID provider is to send
      # back a response immediately, useful for behind-the-scenes
      # authentication attempts.  Otherwise the OpenID provider may
      # engage the user before providing a response.  This is the
      # default case, as the user may need to provide credentials or
      # approve the request before a positive response can be sent.
      def get_message(realm, return_to=nil, immediate=false)
        if !return_to.nil?
          return_to = Util.append_args(return_to, @return_to_args)
        elsif immediate
          raise ArgumentError, ('"return_to" is mandatory when using '\
                                '"checkid_immediate"')
        elsif @message.is_openid1
          raise ArgumentError, ('"return_to" is mandatory for OpenID 1 '\
                                'requests')
        elsif @return_to_args.empty?
          raise ArgumentError, ('extra "return_to" arguments were specified, '\
                                'but no return_to was specified')
        end


        message = @message.copy

        mode = immediate ? 'checkid_immediate' : 'checkid_setup'
        message.set_arg(OPENID_NS, 'mode', mode)

        realm_key = message.is_openid1 ? 'trust_root' : 'realm'
        message.set_arg(OPENID_NS, realm_key, realm)

        if !return_to.nil?
          message.set_arg(OPENID_NS, 'return_to', return_to)
        end

        if not @anonymous
          if @endpoint.is_op_identifier
            # This will never happen when we're in OpenID 1
            # compatibility mode, as long as is_op_identifier()
            # returns false whenever preferred_namespace returns
            # OPENID1_NS.
            claimed_id = request_identity = IDENTIFIER_SELECT
          else
            request_identity = @endpoint.get_local_id
            claimed_id = @endpoint.claimed_id
          end

          # This is true for both OpenID 1 and 2
          message.set_arg(OPENID_NS, 'identity', request_identity)

          if message.is_openid2
            message.set_arg(OPENID2_NS, 'claimed_id', claimed_id)
          end
        end

        if @assoc
          message.set_arg(OPENID_NS, 'assoc_handle', @assoc.handle)
          assoc_log_msg = "with assocication #{@assoc.handle}"
        else
          assoc_log_msg = 'using stateless mode.'
        end

        Util.log("Generated #{mode} request to #{@endpoint.server_url} "\
                 "#{assoc_log_msg}")
        return message
      end

      # Returns a URL with an encoded OpenID request.
      #
      # The resulting URL is the OpenID provider's endpoint URL with
      # parameters appended as query arguments.  You should redirect
      # the user agent to this URL.
      #
      # OpenID 2.0 endpoints also accept POST requests, see
      # 'send_redirect?' and 'form_markup'.
      def redirect_url(realm, return_to=nil, immediate=false)
        message = get_message(realm, return_to, immediate)
        return message.to_url(@endpoint.server_url)
      end

      # Get html for a form to submit this request to the IDP.
      #
      # form_tag_attrs is a hash of attributes to be added to the form
      # tag. 'accept-charset' and 'enctype' have defaults that can be
      # overridden. If a value is supplied for 'action' or 'method',
      # it will be replaced.
      def form_markup(realm, return_to=nil, immediate=false,
                      form_tag_attrs=nil)
        message = get_message(realm, return_to, immediate)
        return message.to_form_markup(@endpoint.server_url, form_tag_attrs)
      end

      # Get a complete HTML document that autosubmits the request to the IDP
      # with javascript.  This method wraps form_markup - see that method's
      # documentation for help with the parameters.
      def html_markup(realm, return_to=nil, immediate=false,
                      form_tag_attrs=nil)
        Util.auto_submit_html(form_markup(realm, 
                                          return_to, 
                                          immediate, 
                                          form_tag_attrs))
      end

      # Should this OpenID authentication request be sent as a HTTP
      # redirect or as a POST (form submission)?
      #
      # This takes the same parameters as redirect_url or form_markup
      def send_redirect?(realm, return_to=nil, immediate=false)
        if @endpoint.compatibility_mode
          return true
        else
          url = redirect_url(realm, return_to, immediate)
          return url.length <= OPENID1_URL_LIMIT
        end
      end
    end
  end
end
