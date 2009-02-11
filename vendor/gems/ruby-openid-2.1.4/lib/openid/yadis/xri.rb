require 'openid/yadis/xrds'
require 'openid/fetchers'

module OpenID
  module Yadis
    module XRI

      # The '(' is for cross-reference authorities, and hopefully has a
      # matching ')' somewhere.
      XRI_AUTHORITIES = ["!", "=", "@", "+", "$", "("]

      def self.identifier_scheme(identifier)
        if (!identifier.nil? and
            identifier.length > 0 and
            (identifier.match('^xri://') or
             XRI_AUTHORITIES.member?(identifier[0].chr)))
          return :xri
        else
          return :uri
        end
      end

      # Transform an XRI reference to an IRI reference.  Note this is
      # not not idempotent, so do not apply this to an identifier more
      # than once.  XRI Syntax section 2.3.1
      def self.to_iri_normal(xri)
        iri = xri.dup
        iri.insert(0, 'xri://') if not iri.match('^xri://')
        return escape_for_iri(iri)
      end

      # Note this is not not idempotent, so do not apply this more than
      # once.  XRI Syntax section 2.3.2
      def self.escape_for_iri(xri)
        esc = xri.dup
        # encode all %
        esc.gsub!(/%/, '%25')
        esc.gsub!(/\((.*?)\)/) { |xref_match|
          xref_match.gsub(/[\/\?\#]/) { |char_match|
            CGI::escape(char_match)
          }
        }
        return esc
      end

      # Transform an XRI reference to a URI reference.  Note this is not
      # not idempotent, so do not apply this to an identifier more than
      # once.  XRI Syntax section 2.3.1
      def self.to_uri_normal(xri)
        return iri_to_uri(to_iri_normal(xri))
      end

      # RFC 3987 section 3.1
      def self.iri_to_uri(iri)
        uri = iri.dup
        # for char in ucschar or iprivate
        # convert each char to %HH%HH%HH (as many %HH as octets)
        return uri
      end

      def self.provider_is_authoritative(provider_id, canonical_id)
        lastbang = canonical_id.rindex('!')
        return false unless lastbang
        parent = canonical_id[0...lastbang]
        return parent == provider_id
      end

      def self.root_authority(xri)
        xri = xri[6..-1] if xri.index('xri://') == 0
        authority = xri.split('/', 2)[0]
        if authority[0].chr == '('
          root = authority[0...authority.index(')')+1]
        elsif XRI_AUTHORITIES.member?(authority[0].chr)
          root = authority[0].chr
        else
          root = authority.split(/[!*]/)[0]
        end

        self.make_xri(root)
      end

      def self.make_xri(xri)
        if xri.index('xri://') != 0
          xri = 'xri://' + xri
        end
        return xri
      end
    end
  end
end
