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

module OpenProject::TextFormatting
  module Filters
    class SanitizationFilter < HTML::Pipeline::SanitizationFilter
      # Prefix for all id and name attributes so they cannot clobber document/window
      # (e.g. id="constructor" becomes id="op-frag-constructor"). Anchors still work
      # because we rewrite fragment links to use the same prefix. Used by
      # TableOfContentsFilter when it assigns heading ids.
      FRAGMENT_ID_PREFIX = "op-frag-"

      def allowlist # rubocop:disable Metrics/AbcSize
        base = super
        # Ensure id is allowed (for anchors); we make it safe by prefixing in the transformer.
        base_attrs = base[:attributes].deep_dup
        all_attrs = Array(base_attrs[:all])
        base_attrs[:all] = all_attrs.include?("id") ? all_attrs : all_attrs + ["id"]

        Sanitize::Config.merge(
          base,
          elements: base[:elements] + %w[macro mention],
          # Strip SVG entirely (tag + all nested content). SVG is not on the allowlist, but
          # without remove_contents Sanitize would keep SVG child nodes as orphaned content.
          remove_contents: Array(base[:remove_contents]) | %w[svg style],

          attributes: base_attrs.deep_merge(
            # Explicit allowlist of data-* attributes used by registered macros.
            "macro" => %w[class data-type data-classes data-page data-include-parent data-macro-name data-query-props data-pull-request-id data-pull-request-state],
            # mentions
            "mention" => %w[data-type data-text data-id class],
            # add styles to tables
            "figure" => %w[class style],
            # allow inline image styles
            "img" => %w[src alt longdesc style],
            "table" => ["style"],
            "th" => ["style"],
            "tr" => ["style"],
            "td" => ["style"]
          ),

          # Add rel attribute to prevent tabnabbing and SEO spam
          add_attributes: {
            "a" => { "rel" => "noopener noreferrer nofollow" }
          },

          # Add custom transformer logic for more complex modifications
          transformers: base[:transformers] + transformers,

          # Restrict CSS to still allow some basic color and text styles
          # used within the CKEditor table layout plugins
          css: {
            properties: %w[
              text-align vertical-align font-weight font-style font-size
              text-decoration color background-color
              border border-collapse border-spacing border-color border-style border-width
              width height max-width max-height min-width min-height
              padding padding-top padding-right padding-bottom padding-left
              margin margin-top margin-right margin-bottom margin-left
              white-space word-wrap overflow-wrap
              list-style-type
              float clear
            ]
          },

          # Allow our protocols, and relative links always
          protocols: {
            "a" => { "href" => Setting::AllowedLinkProtocols.all + %i[relative] }
          }
        )
      end

      private

      def transformers
        [
          fragment_id_prefix_transformer,
          fragment_link_rewrite_transformer,
          todo_list_transformer,
          code_block_transformer
        ]
      end

      # Prefix all id and name attributes so they cannot clobber document/window.
      # e.g. id="constructor" -> id="op-frag-constructor"; anchors still work.
      def fragment_id_prefix_transformer
        prefix = FRAGMENT_ID_PREFIX
        lambda { |env|
          node = env[:node]
          next unless node.element?

          %w[id name].each do |attr|
            val = node[attr]
            next if val.blank?
            next if val.start_with?(prefix)

            node[attr] = "#{prefix}#{val}"
          end
        }
      end

      # Rewrite same-document fragment links to use the same prefix so anchors match.
      # e.g. <a href="#section"> -> href="#op-frag-section"
      def fragment_link_rewrite_transformer
        prefix = FRAGMENT_ID_PREFIX
        lambda { |env|
          node = env[:node]
          next unless node.name == "a"

          href = node["href"]
          return if href.blank?

          # Only rewrite fragment-only links (#foo), not full URLs with fragment
          next unless href.start_with?("#") && href.length > 1

          fragment = href.slice(1..)
          next if fragment.empty? || fragment.start_with?(prefix)

          node["href"] = "##{prefix}#{fragment}"
        }
      end

      # Transformer to fix task lists in sanitization
      # Replace to do lists in tables with their markdown equivalent
      def todo_list_transformer # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
        lambda { |env|
          name = env[:node_name]
          table = env[:node]

          next unless name == "table"

          # Support both the old css ('todo-list__label') as well as the new one
          # ('op-uc-list_task-list').
          table.css("label.todo-list__label, .op-uc-list_task-list label").each do |label|
            # table.css('.op-uc-list_task-list label').each do |label|
            checkbox = label.css("input[type=checkbox]").first
            li_node = label.ancestors.detect { |node| node.name == "li" }

            # assign all children of the label to its parent
            # that might be the LI, or another element (code, link)
            parent = label.parent

            # CKEditor splits text nodes within task lists so that there are multiple labels
            # but only the first has a checkbox
            # e.g., - [ ] Foo [Bar](https://example.com)
            # both Foo and Bar are contained by labels
            if checkbox.nil?
              # In case we don't have a checkbox, add the content of the label
              # or its parent in case of links directly to the node
              to_add = li_node == parent ? label.children : parent
              li_node.add_child to_add
            else
              checked = checkbox.attr("checked") == "checked" ? "x" : " "
              checkbox.unlink

              # Ensure the task list text is be added as first child to the LI
              li_node.prepend_child " [#{checked}] "

              # Prepend if there is a parent in between
              if parent == li_node
                parent.add_child label.children
              else
                parent.prepend_child label.children
              end
            end
          end
        }
      end

      # Prevent nested pre + code.
      # In such a case, the code is removed.
      def code_block_transformer
        lambda { |env|
          name = env[:node_name]
          code = env[:node]

          next unless name == "code"

          parent = code.parent

          if parent&.name == "pre"
            parent.children = code.children
          end
        }
      end
    end
  end
end
