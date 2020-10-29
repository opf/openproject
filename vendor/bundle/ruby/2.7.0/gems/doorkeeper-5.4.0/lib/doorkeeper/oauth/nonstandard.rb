# frozen_string_literal: true

module Doorkeeper
  module OAuth
    class NonStandard
      # These are not part of the OAuth 2 specification but are still in use by Google
      # and in some other implementations. Native applications should use one of the
      # approaches discussed in RFC8252. OOB is 'Out of Band'

      # This value signals to the Google Authorization Server that the authorization
      # code should be returned in the title bar of the browser, with the page text
      # prompting the user to copy the code and paste it in the application.
      # This is useful when the client (such as a Windows application) cannot listen
      # on an HTTP port without significant client configuration.

      # When you use this value, your application can then detect that the page has loaded, and can
      # read the title of the HTML page to obtain the authorization code. It is then up to your
      # application to close the browser window if you want to ensure that the user never sees the
      # page that contains the authorization code. The mechanism for doing this varies from platform
      # to platform.
      #
      # If your platform doesn't allow you to detect that the page has loaded or read the title of
      # the page, you can have the user paste the code back to your application, as prompted by the
      # text in the confirmation page that the OAuth 2.0 server generates.
      IETF_WG_OAUTH2_OOB = "urn:ietf:wg:oauth:2.0:oob"

      # This is identical to urn:ietf:wg:oauth:2.0:oob, but the text in the confirmation page that
      # the OAuth 2.0 server generates won't instruct the user to copy the authorization code, but
      # instead will simply ask the user to close the window.
      #
      # This is useful when your application reads the title of the HTML page (by checking window
      # titles on the desktop, for example) to obtain the authorization code, but can't close the
      # page on its own.
      IETF_WG_OAUTH2_OOB_AUTO = "urn:ietf:wg:oauth:2.0:oob:auto"

      IETF_WG_OAUTH2_OOB_METHODS = [IETF_WG_OAUTH2_OOB, IETF_WG_OAUTH2_OOB_AUTO].freeze
    end
  end
end
