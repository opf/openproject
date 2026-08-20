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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Wikis
  module WikiPages
    class SidemenuTreeService
      attr_reader :query_terms

      def initialize(wiki:, current_page:, query:, href_resolver:)
        @wiki = wiki
        @current_page = current_page
        @query_terms = query.to_s.downcase.split
        @href_resolver = href_resolver
      end

      def nodes
        pages = sidemenu_pages
        nodes = sidemenu_nodes(pages)
        roots = sidemenu_roots(pages, nodes)

        expand_sidemenu_tree!(roots)
      end

      private

      attr_reader :wiki,
                  :current_page,
                  :href_resolver

      def sidemenu_nodes(pages)
        included_ids = included_sidemenu_page_ids(pages)

        pages
          .select { |wiki_page| included_ids.include?(wiki_page.id) }
          .index_by(&:id)
          .transform_values { |wiki_page| sidemenu_node(wiki_page) }
      end

      def sidemenu_node(wiki_page)
        OpenProject::Sidemenu::TreeNode.new(
          id: wiki_page.id,
          label: wiki_page.title,
          href: href_resolver.call(wiki_page),
          current: wiki_page.id == current_page&.id,
          disabled: !matches_query?(wiki_page)
        )
      end

      def sidemenu_roots(pages, nodes)
        pages.each_with_object([]) do |wiki_page, roots|
          next unless (node = nodes[wiki_page.id])

          if (parent = nodes[wiki_page.parent_id])
            parent.children << node
          else
            roots << node
          end
        end
      end

      def sidemenu_pages
        wiki
          .pages
          .visible
          .order(Arel.sql("LOWER(title)"))
          .to_a
      end

      def included_sidemenu_page_ids(pages)
        return pages.to_set(&:id) if query_terms.empty?

        pages_by_id = pages.index_by(&:id)

        pages.each_with_object(Set.new) do |wiki_page, ids|
          next unless matches_query?(wiki_page)

          page = wiki_page
          while page
            ids << page.id
            page = pages_by_id[page.parent_id]
          end
        end
      end

      def expand_sidemenu_tree!(nodes)
        nodes.each do |node|
          expand_sidemenu_tree!(node.children)
          node.expanded = query_terms.any? || node.current? || node.children.any?(&:expanded?)
        end
      end

      def matches_query?(wiki_page)
        return true if query_terms.empty?

        title = wiki_page.title.downcase
        query_terms.all? { |term| title.include?(term) }
      end
    end
  end
end
