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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# The base sanitization policy is adapted from html-pipeline 2.14.3.
# Copyright (c) 2012 GitHub Inc. and Jerry Cheung
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module OpenProject::TextFormatting
  module Filters
    class SanitizationFilter < DomFilter
      # Prefix for all id and name attributes so they cannot clobber document/window
      # (e.g. id="constructor" becomes id="op-frag-constructor"). Anchors still work
      # because we rewrite fragment links to use the same prefix. Used by
      # TableOfContentsFilter when it assigns heading ids.
      FRAGMENT_ID_PREFIX = "op-frag-"

      WEB_PROTOCOLS = ["http", "https", :relative].freeze
      CONTAINERS = { "li" => %w[ul ol] }.merge(%w[tr td th thead tbody tfoot].index_with { ["table"] }).freeze
      BASE_ALLOWLIST = {
        elements: %w[
          h1 h2 h3 h4 h5 h6 h7 h8 br b i strong em a pre code img tt
          div ins del sup sub p ol ul table thead tbody tfoot blockquote
          dl dt dd kbd q samp var hr ruby rt rp li tr td th s strike summary
          details caption figure figcaption abbr bdo cite dfn mark small span time wbr
        ],
        remove_contents: %w[script],
        attributes: {
          "a" => %w[href], "img" => %w[src longdesc], "div" => %w[itemscope itemtype],
          "blockquote" => %w[cite], "del" => %w[cite], "ins" => %w[cite], "q" => %w[cite],
          all: %w[
            abbr accept accept-charset accesskey action align alt aria-describedby aria-hidden aria-label aria-labelledby
            axis border cellpadding cellspacing char charoff charset checked clear cols colspan color compact coords datetime
            dir disabled enctype for frame headers height hreflang hspace ismap label lang maxlength media method multiple
            name nohref noshade nowrap open progress prompt readonly rel rev role rows rowspan rules scope selected shape
            size span start summary tabindex target title type usemap valign value vspace width itemprop
          ]
        },
        protocols: {
          "a" => { "href" => [] },
          "blockquote" => { "cite" => WEB_PROTOCOLS }, "del" => { "cite" => WEB_PROTOCOLS },
          "ins" => { "cite" => WEB_PROTOCOLS }, "q" => { "cite" => WEB_PROTOCOLS },
          "img" => { "src" => WEB_PROTOCOLS, "longdesc" => WEB_PROTOCOLS }
        },
        transformers: [lambda { |env|
          node = env[:node]
          parents = CONTAINERS[env[:node_name]]
          node.replace(node.children) if parents && node.ancestors.none? { |ancestor| parents.include?(ancestor.name) }
        }]
      }.freeze

      def call
        Sanitize.clean_node!(doc, allowlist)
      end

      def allowlist # rubocop:disable Metrics/AbcSize
        base = context[:allowlist] || context[:whitelist] || BASE_ALLOWLIST
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
            "macro" => %w[
              class data-type data-classes data-page data-include-parent data-macro-name
              data-query-props data-pull-request-id data-pull-request-state
            ],
            # mentions
            "mention" => %w[data-type data-text data-id class],
            # add styles to tables
            "figure" => %w[class style],
            # allow inline image styles
            "img" => %w[src alt longdesc style],
            "table" => ["style"],
            "th" => ["style"],
            "tr" => ["style"],
            "td" => ["style"],
            "li" => %w[data-task],
            "span" => %w[data-task],
            "ul" => %w[data-task-list],
            "ol" => %w[data-task-list]
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
          code_block_transformer,
          TaskItemTransformer.new(plain_text: context[:plain_text])
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
