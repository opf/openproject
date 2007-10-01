require 'redcloth'
require 'coderay'
require 'pp'
module Redmine
  module WikiFormatting
  
  private
  
    class TextileFormatter < RedCloth      
      RULES = [:inline_auto_link, :inline_auto_mailto, :textile, :inline_toc]
      
      def initialize(*args)
        super
        self.hard_breaks=true
        self.no_span_caps=true
      end
      
      def to_html
        @toc = []
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
      
      # Patch to add 'table of content' support to RedCloth
      def textile_p_withtoc(tag, atts, cite, content)
        if tag =~ /^h(\d)$/
          @toc << [$1.to_i, content]
        end
        content = "<a name=\"#{@toc.length}\" class=\"wiki-page\"></a>" + content
        textile_p(tag, atts, cite, content)
      end

      alias :textile_h1 :textile_p_withtoc
      alias :textile_h2 :textile_p_withtoc
      alias :textile_h3 :textile_p_withtoc
      
      def inline_toc(text)
        text.gsub!(/<p>\{\{([<>]?)toc\}\}<\/p>/i) do
          div_class = 'toc'
          div_class << ' right' if $1 == '>'
          div_class << ' left' if $1 == '<'
          out = "<div class=\"#{div_class}\">"
          @toc.each_with_index do |heading, index|
            # remove wiki links from the item
            toc_item = heading.last.gsub(/(\[\[|\]\])/, '')
            out << "<a href=\"##{index+1}\" class=\"heading#{heading.first}\">#{toc_item}</a>"
          end
          out << '</div>'
          out
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
                          (\S+?)                   # url
                          (\/)?                    # slash
                        )
                        ([^\w\=\/;]*?)               # post
                        (?=<|\s|$)
                       }x unless const_defined?(:AUTO_LINK_RE)

      # Turns all urls into clickable links (code from Rails).
      def inline_auto_link(text)
        text.gsub!(AUTO_LINK_RE) do
          all, leading, proto, url, post = $&, $1, $2, $3, $6
          if leading =~ /<a\s/i || leading =~ /![<>=]?/
            # don't replace URL's that are already linked
            # and URL's prefixed with ! !> !< != (textile images)
            all
          else            
            %(#{leading}<a class="external" href="#{proto=="www."?"http://www.":proto}#{url}">#{proto + url}</a>#{post})
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
