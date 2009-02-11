require "openid/yadis/htmltokenizer"
require 'cgi'

module OpenID
  module Yadis
    def Yadis.html_yadis_location(html)
      parser = HTMLTokenizer.new(html)

      # to keep track of whether or not we are in the head element
      in_head = false

      begin
        while el = parser.getTag('head', '/head', 'meta', 'body', '/body',
                                 'html', 'script')

          # we are leaving head or have reached body, so we bail
          return nil if ['/head', 'body', '/body'].member?(el.tag_name)

          if el.tag_name == 'head'
            unless el.to_s[-2] == ?/ # tag ends with a /: a short tag
              in_head = true
            end
          end
          next unless in_head

          if el.tag_name == 'script'
            unless el.to_s[-2] == ?/ # tag ends with a /: a short tag
              parser.getTag('/script')
            end
          end

          return nil if el.tag_name == 'html'

          if el.tag_name == 'meta' and (equiv = el.attr_hash['http-equiv'])
            if ['x-xrds-location','x-yadis-location'].member?(equiv.downcase) &&
                el.attr_hash.member?('content')
              return CGI::unescapeHTML(el.attr_hash['content'])
            end
          end
        end
      rescue HTMLTokenizerError # just stop parsing if there's an error
      end
    end
  end
end
