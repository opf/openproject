module OpenIDConnect
  class Exception < StandardError; end

  class ValidationFailed < Exception
    attr_reader :object

    def initialize(object)
      super object.errors.full_messages.to_sentence
      @object = object
    end
  end

  class HttpError < Exception
    attr_accessor :status, :response
    def initialize(status, message = nil, response = nil)
      super message
      @status = status
      @response = response
    end
  end

  class BadRequest < HttpError
    def initialize(message = nil, response = nil)
      super 400, message, response
    end
  end

  class Unauthorized < HttpError
    def initialize(message = nil, response = nil)
      super 401, message, response
    end
  end

  class Forbidden < HttpError
    def initialize(message = nil, response = nil)
      super 403, message, response
    end
  end
end