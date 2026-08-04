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
  class PageSearchService
    include Dry::Monads[:result]

    attr_reader :provider, :user

    def initialize(provider:, user:)
      @provider = provider
      @user = user
    end

    def search_pages(query)
      return Success([]) if query.blank?

      if url?(query)
        search_by_url(query).either(
          ->(page) { Success([to_tree_node(page:, enabled: true)]) },
          ->(failure) { failure.code == :not_found ? Success([]) : Failure(failure) }
        )
      else
        search_by_query(query)
      end
    end

    private

    def url?(string)
      uri = URI.parse(string)

      %w[http https].include?(uri.scheme)
    rescue URI::InvalidURIError
      false
    end

    def search_by_url(query)
      Adapters::Input::PageInfoForUrl.build(url: query).bind do |input_data|
        provider.auth_strategy_for(user).bind do |auth_strategy|
          provider.resolve("queries.page_info_for_url").call(input_data:, auth_strategy:)
        end
      end
    end

    def search_by_query(query)
      Adapters::Input::SearchPages.build(query:).bind do |input_data|
        provider.auth_strategy_for(user).bind do |auth_strategy|
          matching_pages(input_data:, auth_strategy:).bind do |pages|
            matching_wikis(input_data:, auth_strategy:).fmap { build_result_tree(pages:, wikis: it) }
          end
        end
      end
    end

    def matching_pages(input_data:, auth_strategy:)
      provider.resolve("queries.search_pages").call(input_data:, auth_strategy:)
    end

    def matching_wikis(input_data:, auth_strategy:)
      provider.resolve("queries.search_wikis").call(input_data:, auth_strategy:)
    end

    def to_tree_node(page:, enabled:)
      Adapters::Results::PageSearchTreeNode.leaf_page(page.identifier, page.title, enabled)
    end

    def build_result_tree(pages:, wikis:)
      root = Adapters::Results::PageSearchTreeNode.empty_root

      existing_nodes = {}
      wikis.each { insert_wiki_node(existing_nodes, it, root) }
      pages.each { insert_page_hierarchy(existing_nodes, it, root) }

      root.children
    end

    def insert_page_hierarchy(existing_nodes, page_hierarchy, root_node)
      insert_wiki_node(existing_nodes, page_hierarchy.wiki, root_node)
      insert_ancestor_nodes(existing_nodes, page_hierarchy)
      insert_page_node(existing_nodes, page_hierarchy)
    end

    def insert_wiki_node(node_list, wiki, root_node)
      wiki_node = Adapters::Results::PageSearchTreeNode.empty_wiki(wiki.identifier, wiki.name)

      node_list.fetch(wiki_node.key) do
        root_node.add_child(wiki_node)
        node_list[wiki_node.key] = wiki_node
      end
    end

    def insert_ancestor_nodes(node_list, page)
      page => { wiki:, ancestors: }

      previous_ancestor_node = node_list[node_key(:wiki, wiki.identifier)]

      ancestors.reduce(previous_ancestor_node) do |previous, current|
        ancestor_node = to_tree_node(page: current, enabled: false)

        node_list.fetch(ancestor_node.key) do
          previous.add_child(ancestor_node)
          node_list[ancestor_node.key] = ancestor_node
        end
      end
    end

    def insert_page_node(node_list, page_hierarchy)
      page_hierarchy => { page:, ancestors:, wiki: }

      new_node = to_tree_node(page:, enabled: true)
      return if enable_if_node_exists(node_list, new_node)

      parent_node = find_parent(node_list, ancestors, wiki)
      parent_node.add_child(new_node)
      node_list[new_node.key] = new_node
    end

    def find_parent(node_list, ancestors, wiki)
      key = if ancestors.any?
              node_key(:page, ancestors.first.identifier)
            else
              node_key(:wiki, wiki.identifier)
            end

      node_list[key]
    end

    def node_key(type, identifier)
      Adapters::Results::PageSearchTreeNode::NodeKey.new(type, identifier)
    end

    def enable_if_node_exists(node_list, node)
      existing_node = node_list.fetch(node.key) { return false }
      existing_node.enable
    end
  end
end
