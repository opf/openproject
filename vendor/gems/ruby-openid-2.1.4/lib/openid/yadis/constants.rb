
require 'openid/yadis/accept'

module OpenID

  module Yadis

    YADIS_HEADER_NAME = 'X-XRDS-Location'
    YADIS_CONTENT_TYPE = 'application/xrds+xml'

    # A value suitable for using as an accept header when performing
    # YADIS discovery, unless the application has special requirements
    YADIS_ACCEPT_HEADER = generate_accept_header(
                                                 ['text/html', 0.3],
                                                 ['application/xhtml+xml', 0.5],
                                                 [YADIS_CONTENT_TYPE, 1.0]
                                                 )

  end

end
