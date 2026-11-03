# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

module Import
  module JiraWikiMarkup
    # Table cells are emitted as HTML, so their contents cannot stay Markdown:
    # CommonMark does not format the inside of an HTML block. Only the renderers
    # that would produce Markdown are overridden here; the ones already emitting
    # HTML or plain text are inherited unchanged.
    class HtmlCellRenderer < Renderer
      NEWLINE_ENTITY = "&#10;"

      def render_cell(nodes)
        encode_newlines(render_inline(nodes))
      end

      private

      # A multi-line macro in a cell would otherwise put a blank line inside the
      # table, ending the CommonMark HTML block halfway through it. The entity
      # still decodes to a newline, so <pre> content keeps its line breaks.
      def encode_newlines(html)
        html.gsub(/\r\n?|\n/, NEWLINE_ENTITY)
      end

      def render_text(node)
        escape(node.content)
      end

      def render_bold(node)
        "<strong>#{render_inline(node.children)}</strong>"
      end

      def render_italic(node)
        "<em>#{render_inline(node.children)}</em>"
      end

      def render_strikethrough(node)
        "<del>#{render_inline(node.children)}</del>"
      end

      def render_inline_code(node)
        "<code>#{escape(node.content)}</code>"
      end

      def render_link(node)
        "<a href=\"#{escape(node.url)}\">#{escape(node.text || node.url)}</a>"
      end

      def render_image(node)
        %(<img src="#{escape(attachment_reference(node.url))}" alt="#{escape(node.params['alt'] || '')}">)
      end

      def render_line_break(_node)
        "<br>"
      end

      def render_code_block(node)
        language = node.language ? %( class="language-#{escape(node.language)}") : ""
        "<pre><code#{language}>#{escape(node.content)}</code></pre>"
      end

      def render_panel(node)
        content = render_inline(node.children)
        title = node.params["title"]
        return content if title.blank?

        "<strong>#{escape(title)}</strong><br>#{content}"
      end

      def render_noformat_block(node)
        "<pre><code>#{escape(node.content)}</code></pre>"
      end

      def escape(text)
        ERB::Util.html_escape(text)
      end
    end
  end
end
