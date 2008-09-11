# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'redcloth3'
require 'coderay'

module Redmine
  module WikiFormatting
  
  private
  
    class TextileFormatter < RedCloth3
      
      # auto_link rule after textile rules so that it doesn't break !image_url! tags
      RULES = [:textile, :block_markdown_rule, :inline_auto_link, :inline_auto_mailto, :inline_toc, :inline_macros]
      
      def initialize(*args)
        super
        self.hard_breaks=true
        self.no_span_caps=true
      end
      
      def to_html(*rules, &block)
        @toc = []
        @macros_runner = block
        super(*RULES).to_s
      end

    private

      # Patch for RedCloth.  Fixed in RedCloth r128 but _why hasn't released it yet.
      # <a href="http://code.whytheluckystiff.net/redcloth/changeset/128">http://code.whytheluckystiff.net/redcloth/changeset/128</a>
      def hard_break( text ) 
        text.gsub!( /(.)\n(?!\n|\Z|>| *(>? *[#*=]+(\s|$)|[{|]))/, "\\1<br />\n" ) if hard_breaks 
      end
      
      # Patch to add code highlighting support to RedCloth
      def smooth_offtags( text )
        unless @pre_list.empty?
          ## replace <pre> content
          text.gsub!(/<redpre#(\d+)>/) do
            content = @pre_list[$1.to_i]
            if content.match(/<code\s+class="(\w+)">\s?(.+)/m)
              content = "<code class=\"#{$1} CodeRay\">" + 
                CodeRay.scan($2, $1.downcase).html(:escape => false, :line_numbers => :inline)
            end
            content
          end
        end
      end
      
      # Patch to add 'table of content' support to RedCloth
      def textile_p_withtoc(tag, atts, cite, content)
        # removes wiki links from the item
        toc_item = content.gsub(/(\[\[|\]\])/, '')
        # removes styles
        # eg. %{color:red}Triggers% => Triggers
        toc_item.gsub! %r[%\{[^\}]*\}([^%]+)%], '\\1'
        
        # replaces non word caracters by dashes
        anchor = toc_item.gsub(%r{[^\w\s\-]}, '').gsub(%r{\s+(\-+\s*)?}, '-')

        unless anchor.blank?
          if tag =~ /^h(\d)$/
            @toc << [$1.to_i, anchor, toc_item]
          end
          atts << " id=\"#{anchor}\""
          content = content + "<a href=\"##{anchor}\" class=\"wiki-anchor\">&para;</a>"
        end
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
          out = "<ul class=\"#{div_class}\">"
          @toc.each do |heading|
            level, anchor, toc_item = heading
            out << "<li class=\"heading#{level}\"><a href=\"##{anchor}\">#{toc_item}</a></li>\n"
          end
          out << '</ul>'
          out
        end
      end
      
      MACROS_RE = /
                    (!)?                        # escaping
                    (
                    \{\{                        # opening tag
                    ([\w]+)                     # macro name
                    (\(([^\}]*)\))?             # optional arguments
                    \}\}                        # closing tag
                    )
                  /x unless const_defined?(:MACROS_RE)
      
      def inline_macros(text)
        text.gsub!(MACROS_RE) do
          esc, all, macro = $1, $2, $3.downcase
          args = ($5 || '').split(',').each(&:strip)
          if esc.nil?
            begin
              @macros_runner.call(macro, args)
            rescue => e
              "<div class=\"flash error\">Error executing the <strong>#{macro}</strong> macro (#{e})</div>"
            end || all
          else
            all
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
                          (?:ftp://)|
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
          mail = $1
          if text.match(/<a\b[^>]*>(.*)(#{Regexp.escape(mail)})(.*)<\/a>/)
            mail
          else
            %{<a href="mailto:#{mail}" class="email">#{mail}</a>}
          end
        end
      end
    end
    
  public
  
    def self.to_html(text, options = {}, &block)
      TextileFormatter.new(text).to_html(&block)
    end
  end
end
