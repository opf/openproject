module OpenIDConnect
  module JWTnizable
    def to_jwt(key, algorithm = :RS256, &block)
      as_jwt(key, algorithm, &block).to_s
    end

    def as_jwt(key, algorithm = :RS256, &block)
      token = JSON::JWT.new as_json
      yield token if block_given?
      token = token.sign key, algorithm if algorithm != :none
      token
    end
  end
end