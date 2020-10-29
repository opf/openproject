require 'base64'
require 'digest'
require 'time'

module MessageBird
  class ValidationException < TypeError;
  end

  class SignedRequest
    def initialize(queryParameters, signature, requestTimestamp, body)

      if !queryParameters.is_a? Hash
        raise ValidationException, 'The "queryParameters" value is invalid.'
      end
      if !signature.is_a? String
        raise ValidationException, 'The "signature" value is invalid.'
      end
      if !requestTimestamp.is_a? Integer
        raise ValidationException, 'The "requestTimestamp" value is invalid.'
      end
      if !body.is_a? String
        raise ValidationException, 'The "body" value is invalid.'
      end

      @queryParameters, @signature, @requestTimestamp, @body = queryParameters, signature, requestTimestamp, body
    end

    def verify(signingKey)
      calculatedSignature = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), signingKey, buildPayload)
      expectedSignature = Base64.decode64(@signature)
      calculatedSignature.bytes == expectedSignature.bytes
    end

    def buildPayload
      parts = []
      parts.push(@requestTimestamp)
      parts.push(URI.encode_www_form(@queryParameters.sort))
      parts.push(Digest::SHA256.new.digest @body)
      parts.join("\n")
    end

    def isRecent(offset = 10)
      (Time.now.getutc.to_i - @requestTimestamp) < offset;
    end

  end
end
