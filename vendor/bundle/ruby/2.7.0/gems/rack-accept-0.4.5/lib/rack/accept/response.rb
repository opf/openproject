require 'rack/response'

module Rack::Accept
  # The base class for responses issued by Rack::Accept.
  class Response < Rack::Response
    # Marks this response as being unacceptable and clears the response body.
    #
    # Note: The HTTP spec advises servers to respond with an "entity" that
    # describes acceptable parameters, but it fails to go into detail about its
    # implementation. Thus, it is up to the user of this library to create such
    # an entity if one is desired.
    def not_acceptable!
      self.status = 406
      self.body = []
      header['Content-Length'] = '0'
    end
  end
end
