require "openid/message"
require "openid/fetchers"

module OpenID
  # Exception that is raised when the server returns a 400 response
  # code to a direct request.
  class ServerError < OpenIDError
    attr_reader :error_text, :error_code, :message

    def initialize(error_text, error_code, message)
      super(error_text)
      @error_text = error_text
      @error_code = error_code
      @message = message
    end

    def self.from_message(msg)
      error_text = msg.get_arg(OPENID_NS, 'error',
                               '<no error message supplied>')
      error_code = msg.get_arg(OPENID_NS, 'error_code')
      return self.new(error_text, error_code, msg)
    end
  end

  class KVPostNetworkError < OpenIDError
  end
  class HTTPStatusError < OpenIDError
  end

  class Message
    def self.from_http_response(response, server_url)
      msg = self.from_kvform(response.body)
      case response.code.to_i
      when 200
        return msg
      when 206
        return msg
      when 400
        raise ServerError.from_message(msg)
      else
        error_message = "bad status code from server #{server_url}: "\
        "#{response.code}"
        raise HTTPStatusError.new(error_message)
      end
    end
  end

  # Send the message to the server via HTTP POST and receive and parse
  # a response in KV Form
  def self.make_kv_post(request_message, server_url)
    begin
      http_response = self.fetch(server_url, request_message.to_url_encoded)
    rescue Exception
      raise KVPostNetworkError.new("Unable to contact OpenID server: #{$!.to_s}")
    end
    return Message.from_http_response(http_response, server_url)
  end
end
