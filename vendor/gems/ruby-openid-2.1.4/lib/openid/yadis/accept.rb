module OpenID

  module Yadis

    # Generate an accept header value
    #
    # [str or (str, float)] -> str
    def self.generate_accept_header(*elements)
      parts = []
      elements.each { |element|
        if element.is_a?(String)
          qs = "1.0"
          mtype = element
        else
          mtype, q = element
          q = q.to_f
          if q > 1 or q <= 0
            raise ArgumentError.new("Invalid preference factor: #{q}")
          end
          qs = sprintf("%0.1f", q)
        end

        parts << [qs, mtype]
      }

      parts.sort!
      chunks = []
      parts.each { |q, mtype|
        if q == '1.0'
          chunks << mtype
        else
          chunks << sprintf("%s; q=%s", mtype, q)
        end
      }

      return chunks.join(', ')
    end

    def self.parse_accept_header(value)
      # Parse an accept header, ignoring any accept-extensions
      #
      # returns a list of tuples containing main MIME type, MIME
      # subtype, and quality markdown.
      #
      # str -> [(str, str, float)]
      chunks = value.split(',', -1).collect { |v| v.strip }
      accept = []
      chunks.each { |chunk|
        parts = chunk.split(";", -1).collect { |s| s.strip }

        mtype = parts.shift
        if mtype.index('/').nil?
          # This is not a MIME type, so ignore the bad data
          next
        end

        main, sub = mtype.split('/', 2)

        q = nil
        parts.each { |ext|
          if !ext.index('=').nil?
            k, v = ext.split('=', 2)
            if k == 'q'
              q = v.to_f
            end
          end
        }

        q = 1.0 if q.nil?

        accept << [q, main, sub]
      }

      accept.sort!
      accept.reverse!

      return accept.collect { |q, main, sub| [main, sub, q] }
    end

    def self.match_types(accept_types, have_types)
      # Given the result of parsing an Accept: header, and the
      # available MIME types, return the acceptable types with their
      # quality markdowns.
      #
      # For example:
      #
      # >>> acceptable = parse_accept_header('text/html, text/plain; q=0.5')
      # >>> matchTypes(acceptable, ['text/plain', 'text/html', 'image/jpeg'])
      # [('text/html', 1.0), ('text/plain', 0.5)]
      #
      # Type signature: ([(str, str, float)], [str]) -> [(str, float)]
      if accept_types.nil? or accept_types == []
        # Accept all of them
        default = 1
      else
        default = 0
      end

      match_main = {}
      match_sub = {}
      accept_types.each { |main, sub, q|
        if main == '*'
          default = [default, q].max
          next
        elsif sub == '*'
          match_main[main] = [match_main.fetch(main, 0), q].max
        else
          match_sub[[main, sub]] = [match_sub.fetch([main, sub], 0), q].max
        end
      }

      accepted_list = []
      order_maintainer = 0
      have_types.each { |mtype|
        main, sub = mtype.split('/', 2)
        if match_sub.member?([main, sub])
          q = match_sub[[main, sub]]
        else
          q = match_main.fetch(main, default)
        end

        if q != 0
          accepted_list << [1 - q, order_maintainer, q, mtype]
          order_maintainer += 1
        end
      }

      accepted_list.sort!
      return accepted_list.collect { |_, _, q, mtype| [mtype, q] }
    end

    def self.get_acceptable(accept_header, have_types)
      # Parse the accept header and return a list of available types
      # in preferred order. If a type is unacceptable, it will not be
      # in the resulting list.
      #
      # This is a convenience wrapper around matchTypes and
      # parse_accept_header
      #
      # (str, [str]) -> [str]
      accepted = self.parse_accept_header(accept_header)
      preferred = self.match_types(accepted, have_types)
      return preferred.collect { |mtype, _| mtype }
    end

  end

end
