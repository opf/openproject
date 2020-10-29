# frozen_string_literal: true

module Grape
  class Cookies
    def initialize
      @cookies = {}
      @send_cookies = {}
    end

    def read(request)
      request.cookies.each do |name, value|
        @cookies[name.to_s] = value
      end
    end

    def write(header)
      @cookies.select { |key, _value| @send_cookies[key] == true }.each do |name, value|
        cookie_value = value.is_a?(Hash) ? value : { value: value }
        Rack::Utils.set_cookie_header! header, name, cookie_value
      end
    end

    def [](name)
      @cookies[name.to_s]
    end

    def []=(name, value)
      @cookies[name.to_s] = value
      @send_cookies[name.to_s] = true
    end

    def each(&block)
      @cookies.each(&block)
    end

    def delete(name, **opts)
      options = opts.merge(value: 'deleted', expires: Time.at(0))
      self.[]=(name, options)
    end
  end
end
