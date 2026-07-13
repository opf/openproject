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
    class Renderer
      N = Nodes

      EMOTICON_MAP = {
        ":)" => "\u{1F642}",
        ":(" => "\u{2639}\u{FE0F}",
        ":P" => "\u{1F61B}",
        ":D" => "\u{1F603}",
        ";)" => "\u{1F609}",
        "(y)" => "\u{1F44D}",
        "(n)" => "\u{1F44E}",
        "(i)" => "\u{2139}\u{FE0F}",
        "(/)" => "\u{2705}",
        "(x)" => "\u{274C}",
        "(!)" => "\u{26A0}\u{FE0F}",
        "(+)" => "\u{2795}",
        "(-)" => "\u{2796}",
        "(?)" => "\u{2753}",
        "(on)" => "\u{1F4A1}",
        "(off)" => "\u{1F4A1}",
        "(*)" => "\u{2B50}",
        "(*r)" => "\u{2B50}",
        "(*g)" => "\u{2B50}",
        "(*b)" => "\u{2B50}",
        "(*y)" => "\u{2B50}",
        "(flag)" => "\u{1F6A9}",
        "(flagoff)" => "\u{1F3F3}\u{FE0F}"
      }.freeze

      def initialize(document)
        @document = document
      end

      def render
        blocks = @document.children
        parts = []
        blocks.each_with_index do |block, i|
          rendered = render_block(block)
          parts[-1] = "#{parts[-1]}\n" if i > 0 && block.is_a?(N::Paragraph) && blocks[i - 1].is_a?(N::Paragraph)
          parts << rendered
        end
        parts.join("\n")
      end

      private

      def render_block(node)
        case node
        when N::Heading
          render_heading(node)
        when N::Paragraph
          render_inline(node.children)
        when N::CodeBlock
          render_code_block(node)
        when N::NoformatBlock
          render_noformat_block(node)
        when N::HorizontalRule
          render_horizontal_rule
        when N::List
          render_list(node, 0)
        when N::BlockQuote
          render_block_quote(node)
        when N::MultiLineBlockQuote
          render_multi_line_block_quote(node)
        when N::TableHeaderRow
          render_table_header_row(node)
        when N::TableDataRow
          node.raw
        when N::Panel
          render_panel(node)
        when N::BlankLine
          "\n"
        else
          ""
        end
      end

      def render_horizontal_rule
        "<hr>\n"
      end

      def render_heading(node)
        content = render_inline(node.children)
        content.empty? ? "" : "#{'#' * node.level} #{content}"
      end

      def render_code_block(node)
        lang = node.language
        "```#{lang}\n#{node.content}\n```"
      end

      def render_noformat_block(node)
        "```\n#{node.content}\n```"
      end

      def render_block_quote(node)
        "> #{render_inline(node.children)}\n"
      end

      def render_multi_line_block_quote(node)
        "#{node.lines.map { |line_nodes| "> #{render_inline(line_nodes)}" }.join("\n")}\n"
      end

      def render_table_header_row(node)
        return "" if node.cells.empty?

        header = "| #{node.cells.join(' | ')} |"
        separator = "| #{node.cells.map { '---' }.join(' | ')} |"
        "#{header}\n#{separator}"
      end

      def render_panel(node)
        title = node.params["title"]
        if title
          "**#{title}**\n#{node.content}"
        else
          node.content
        end
      end

      def render_list(list, depth)
        marker = list.list_type == :ordered ? "1. " : "- "
        indent = "   " * depth

        list.items.map do |item|
          line = "#{indent}#{marker}#{render_inline(item.children)}"
          if item.sublist
            "#{line}\n#{render_list(item.sublist, depth + 1)}"
          else
            line
          end
        end.join("\n")
      end

      def render_inline(nodes)
        nodes.map { |node| render_inline_node(node) }.join
      end

      def render_inline_node(node)
        renderer = inline_node_renderer(node)
        renderer ? send(renderer, node) : ""
      end

      def inline_node_renderer(node)
        {
          N::Text => :render_text,
          N::Bold => :render_bold,
          N::Italic => :render_italic,
          N::Strikethrough => :render_strikethrough,
          N::Underline => :render_underline,
          N::Citation => :render_citation,
          N::InlineCode => :render_inline_code,
          N::Superscript => :render_superscript,
          N::Subscript => :render_subscript,
          N::Link => :render_link,
          N::Image => :render_image,
          N::ColorMacro => :render_color_macro,
          N::Mention => :render_mention,
          N::Emoticon => :render_emoticon,
          N::LineBreak => :render_line_break,
          N::EmDash => :render_em_dash,
          N::EnDash => :render_en_dash
        }[node.class]
      end

      def render_text(node)
        node.content
      end

      def render_bold(node)
        "**#{render_inline(node.children)}**"
      end

      def render_italic(node)
        "*#{render_inline(node.children)}*"
      end

      def render_strikethrough(node)
        "~~#{render_inline(node.children)}~~"
      end

      def render_underline(node)
        "<u>#{render_inline(node.children)}</u>"
      end

      def render_citation(node)
        "<cite>#{render_inline(node.children)}</cite>"
      end

      def render_inline_code(node)
        "`#{node.content}`"
      end

      def render_superscript(node)
        "<sup>#{render_inline(node.children)}</sup>"
      end

      def render_subscript(node)
        "<sub>#{render_inline(node.children)}</sub>"
      end

      def render_link(node)
        if node.text
          "[#{node.text}](#{node.url})"
        else
          "<#{node.url}>"
        end
      end

      def render_image(node)
        # TODO get work package attachment and use OP image syntax (HTML <img> tag with data attributes)
        alt = node.params["alt"] || ""
        "![#{alt}](#{node.url})"
      end

      def render_mention(node)
        user = User.find_by(login: node.username)
        if user
          escaped_name = ERB::Util.html_escape(user.name)
          %(<mention class="mention" data-id="#{
            user.id
          }" data-type="user" data-text="@#{
            escaped_name
          }">@#{
            escaped_name
          }</mention>)
        else
          "@#{ERB::Util.html_escape(node.username)}"
        end
      end

      def render_color_macro(node)
        render_inline(node.children)
      end

      def render_emoticon(node)
        EMOTICON_MAP[node.key] || node.key
      end

      def render_line_break(_node)
        "  \n"
      end

      def render_em_dash(_node)
        "\u2014"
      end

      def render_en_dash(_node)
        "\u2013"
      end
    end
  end
end
