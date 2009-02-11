require 'openid/message'

module OpenID
  # An interface for OpenID extensions.
  class Extension < Object

    def initialize
      @ns_uri = nil
      @ns_alias = nil
    end

    # Get the string arguments that should be added to an OpenID
    # message for this extension.
    def get_extension_args
      raise NotImplementedError
    end

    # Add the arguments from this extension to the provided
    # message, or create a new message containing only those
    # arguments.  Returns the message with added extension args.
    def to_message(message = nil)
      if message.nil?
#         warnings.warn('Passing None to Extension.toMessage is deprecated. '
#                       'Creating a message assuming you want OpenID 2.',
#                       DeprecationWarning, stacklevel=2)
        Message.new(OPENID2_NS)
      end
      message = Message.new if message.nil?

      implicit = message.is_openid1()

      message.namespaces.add_alias(@ns_uri, @ns_alias, implicit)
      # XXX python ignores keyerror if m.ns.getAlias(uri) == alias

      message.update_args(@ns_uri, get_extension_args)
      return message
    end
  end
end
