require 'uri'

require "openid/extras"

module OpenID

  module URINorm
    public
    def URINorm.urinorm(uri)
      uri = URI.parse(uri)

      raise URI::InvalidURIError.new('no scheme') unless uri.scheme
      uri.scheme = uri.scheme.downcase
      unless ['http','https'].member?(uri.scheme)
        raise URI::InvalidURIError.new('Not an HTTP or HTTPS URI')
      end

      raise URI::InvalidURIError.new('no host') unless uri.host
      uri.host = uri.host.downcase

      uri.path = remove_dot_segments(uri.path)
      uri.path = '/' if uri.path.length == 0

      uri = uri.normalize.to_s
      uri = uri.gsub(PERCENT_ESCAPE_RE) {
        sub = $&[1..2].to_i(16).chr
        reserved(sub) ? $&.upcase : sub
      }

      return uri
    end

    private
    RESERVED_RE = /[A-Za-z0-9._~-]/
    PERCENT_ESCAPE_RE = /%[0-9a-zA-Z]{2}/

    def URINorm.reserved(chr)
      not RESERVED_RE =~ chr
    end

    def URINorm.remove_dot_segments(path)
      result_segments = []

      while path.length > 0
        if path.starts_with?('../')
          path = path[3..-1]
        elsif path.starts_with?('./')
          path = path[2..-1]
        elsif path.starts_with?('/./')
          path = path[2..-1]
        elsif path == '/.'
          path = '/'
        elsif path.starts_with?('/../')
          path = path[3..-1]
          result_segments.pop if result_segments.length > 0
        elsif path == '/..'
          path = '/'
          result_segments.pop if result_segments.length > 0
        elsif path == '..' or path == '.'
          path = ''
        else
          i = 0
          i = 1 if path[0].chr == '/'
          i = path.index('/', i)
          i = path.length if i.nil?
          result_segments << path[0...i]
          path = path[i..-1]
        end
      end

      return result_segments.join('')
    end
  end

end
