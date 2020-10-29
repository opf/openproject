require 'securerandom'

class Gon
  module ControllerHelpers
    private

    # override this since ActionDispatch::Request#uuid appears only in Rails 3.2.1
    def gon_request_uuid
      @gon_request_uuid ||= SecureRandom.uuid
    end
  end
end
