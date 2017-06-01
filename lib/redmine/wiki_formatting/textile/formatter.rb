#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'redcloth3'

module Redmine
  module WikiFormatting
    module Textile
      class Formatter < RedCloth3
        include ERB::Util
        include ActionView::Helpers::TagHelper

        # auto_link rule after textile rules so that it doesn't break !image_url! tags
        RULES = [:textile, :block_markdown_rule, :inline_auto_link, :inline_auto_mailto]

        def initialize(*args)
          super
          self.hard_breaks = true
          self.no_span_caps = true
          self.filter_styles = true
        end

        def to_html(*_rules)
          @toc = []
          super(*RULES).to_s
        end

        private

        # Patch for RedCloth.  Fixed in RedCloth r128 but _why hasn't released it yet.
        # <a href="http://code.whytheluckystiff.net/redcloth/changeset/128">http://code.whytheluckystiff.net/redcloth/changeset/128</a>
        def hard_break(text)
          text.gsub!(/(.)\n(?!\n|\Z| *([#*=]+(\s|$)|[{|]))/, '\\1<br />') if hard_breaks
        end

        # Patch to add code highlighting support to RedCloth
        def smooth_offtags(text)
          unless @pre_list.empty?
            ## replace <pre> content
            text.gsub!(/<redpre#(\d+)>/) do
              content = @pre_list[$1.to_i]
              if content.match(/<code\s+class="(\w+)">\s?(.+)/m)
                content = "<code class=\"#{$1} CodeRay\">" +
                          Redmine::SyntaxHighlighting.highlight_by_language($2, $1)
              end
              content
            end
          end
        end

        AUTO_LINK_RE = %r{
                        (                          # leading text
                          <\w+.*?>|                # leading HTML tag, or
                          [^=<>!:'"/]|             # leading punctuation, or
                          \{\{\w+\(|               # inside a macro?
                          ^                        # beginning of line
                        )
                        (
                          (?:https?://)|           # protocol spec, or
                          (?:s?ftps?://)|
                          (?:www\.)                # www.*
                        )
                        (
                          (\S+?)                   # url
                          (\/)?                    # slash
                        )
                        ((?:&gt;)?|[^\w\=\/;\(\)]*?)               # post
                        (?=<|\s|$)
                       }x unless const_defined?(:AUTO_LINK_RE)

        # Turns all urls into clickable links (code from Rails).
        def inline_auto_link(text)
          text.gsub!(AUTO_LINK_RE) do
            all = $&
            leading = $1
            proto = $2
            url = $3
            post = $6
            if leading =~ /<a\s/i || leading =~ /![<>=]?/ || leading =~ /\{\{\w+\(/
              # don't replace URLs that are already linked
              # and URLs prefixed with ! !> !< != (textile images)
              all
            else
              # Idea below : an URL with unbalanced parethesis and
              # ending by ')' is put into external parenthesis
              if url[-1] == ?) and ((url.count('(') - url.count(')')) < 0)
                url = url[0..-2] # discard closing parenth from url
                post = ')' + post # add closing parenth to post
              end
              tag = content_tag('a',
                                proto + url,
                                href: "#{proto == 'www.' ? 'http://www.' : proto}#{url}",
                                class: 'external icon-context icon-copy')
              %(#{leading}#{tag}#{post})
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
              content_tag('a', mail, href: "mailto:#{mail}", class: 'email')
            end
          end
        end
      end
    end
  end
end
