require "cgi"
require "uri"
require "logger"

require "openid/extras"

# See OpenID::Consumer or OpenID::Server modules, as well as the store classes
module OpenID
  class AssertionError < Exception
  end

  # Exceptions that are raised by the library are subclasses of this
  # exception type, so if you want to catch all exceptions raised by
  # the library, you can catch OpenIDError
  class OpenIDError < StandardError
  end

  module Util

    BASE64_CHARS = ('ABCDEFGHIJKLMNOPQRSTUVWXYZ' \
                    'abcdefghijklmnopqrstuvwxyz0123456789+/')
    BASE64_RE = Regexp.compile("
    \\A
    ([#{BASE64_CHARS}]{4})*
    ([#{BASE64_CHARS}]{2}==|
     [#{BASE64_CHARS}]{3}=)?
    \\Z", Regexp::EXTENDED)

    def Util.assert(value, message=nil)
      if not value
        raise AssertionError, message or value
      end
    end

    def Util.to_base64(s)
      [s].pack('m').gsub("\n", "")
    end

    def Util.from_base64(s)
      without_newlines = s.gsub(/[\r\n]+/, '')
      if !BASE64_RE.match(without_newlines)
        raise ArgumentError, "Malformed input: #{s.inspect}"
      end
      without_newlines.unpack('m').first
    end

    def Util.urlencode(args)
      a = []
      args.each do |key, val|
        val = '' unless val
        a << (CGI::escape(key) + "=" + CGI::escape(val))
      end
      a.join("&")
    end

    def Util.parse_query(qs)
      query = {}
      CGI::parse(qs).each {|k,v| query[k] = v[0]}
      return query
    end

    def Util.append_args(url, args)
      url = url.dup
      return url if args.length == 0

      if args.respond_to?('each_pair')
        args = args.sort
      end

      url << (url.include?("?") ? "&" : "?")
      url << Util.urlencode(args)
    end

    @@logger = Logger.new(STDERR)
    @@logger.progname = "OpenID"

    def Util.logger=(logger)
      @@logger = logger
    end

    def Util.logger
      @@logger
    end

    # change the message below to do whatever you like for logging
    def Util.log(message)
      logger.info(message)
    end

    def Util.auto_submit_html(form, title='OpenID transaction in progress')
      return "
<html>
<head>
  <title>#{title}</title>
</head>
<body onload='document.forms[0].submit();'>
#{form}
<script>
var elements = document.forms[0].elements;
for (var i = 0; i < elements.length; i++) {
  elements[i].style.display = \"none\";
}
</script>
</body>
</html>
"
    end
  end

end
