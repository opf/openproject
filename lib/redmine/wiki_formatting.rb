require 'redcloth'
require 'coderay'

module Redmine
  module WikiFormatting
  
  private
  
    class TextileFormatter < RedCloth      
      RULES = [:inline_auto_link, :inline_auto_mailto, :textile ]

      def initialize(*args)
        super
        self.hard_breaks=true
      end
      
      def to_html
        super(*RULES).to_s
      end

    private

      # Patch for RedCloth.  Fixed in RedCloth r128 but _why hasn't released it yet.
      # <a href="http://code.whytheluckystiff.net/redcloth/changeset/128">http://code.whytheluckystiff.net/redcloth/changeset/128</a>
      def hard_break( text ) 
        text.gsub!( /(.)\n(?!\n|\Z| *([#*=]+(\s|$)|[{|]))/, "\\1<br />" ) if hard_breaks 
      end
      
      # Patch to add code highlighting support to RedCloth
      def smooth_offtags( text )
        unless @pre_list.empty?
          ## replace <pre> content
          text.gsub!(/<redpre#(\d+)>/) do
            content = @pre_list[$1.to_i]
            if content.match(/<code\s+class="(\w+)">\s?(.+)/m)
              content = "<code class=\"#{$1} CodeRay\">" + 
                CodeRay.scan($2, $1).html(:escape => false, :line_numbers => :inline)
            end
            content
          end
        end
      end
      
      AUTO_LINK_RE = %r{
                        (                          # leading text
                          <\w+.*?>|                # leading HTML tag, or
                          [^=<>!:'"/]|             # leading punctuation, or 
                          ^                        # beginning of line
                        )
                        (
                          (?:https?://)|           # protocol spec, or
                          (?:www\.)                # www.*
                        ) 
                        (
                          [-\w]+                   # subdomain or domain
                          (?:\.[-\w]+)*            # remaining subdomains or domain
                          (?::\d+)?                # port
                          (?:/(?:(?:[~\w\+%-]|(?:[,.;:][^\s$]))+)?)* # path
                          (?:\?[\w\+%&=.;-]+)?     # query string
                          (?:\#[\w\-]*)?           # trailing anchor
                        )
                        ([[:punct:]]|\s|<|$)       # trailing text
                       }x unless const_defined?(:AUTO_LINK_RE)

      # Turns all urls into clickable links (code from Rails).
      def inline_auto_link(text)
        text.gsub!(AUTO_LINK_RE) do
          all, a, b, c, d = $&, $1, $2, $3, $4
          if a =~ /<a\s/i || a =~ /![<>=]?/
            # don't replace URL's that are already linked
            # and URL's prefixed with ! !> !< != (textile images)
            all
          else
            text = b + c
            %(#{a}<a href="#{b=="www."?"http://www.":b}#{c}">#{text}</a>#{d})
          end
        end
      end
      
      # Turns all email addresses into clickable links (code from Rails).
      def inline_auto_mailto(text)
        text.gsub!(/([\w\.!#\$%\-+.]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)+)/) do
          text = $1
          %{<a href="mailto:#{$1}" class="email">#{text}</a>}
        end
      end
    end
    
  public
  
    def self.to_html(text, options = {})
      TextileFormatter.new(text).to_html    
    end
  end
end
