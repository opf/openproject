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
        search_by_query(query).fmap { build_result_tree(it) }
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
          provider.resolve("queries.search_pages").call(input_data:, auth_strategy:)
        end
      end
    end

    def to_tree_node(page:, enabled:)
      Adapters::Results::PageSearchTreeNode.new(identifier: page.identifier,
                                                type: :page,
                                                name: page.title,
                                                children: [],
                                                enabled:)
    end

    def build_result_tree(pages)
      root = Adapters::Results::PageSearchTreeNode.new(identifier: "root",
                                                       type: :root,
                                                       name: "root",
                                                       children: [],
                                                       enabled: false)

      tree_construct = pages.reduce({ root:, all_nodes: [root] }) do |acc, page|
        insert_wiki_node(acc, page.wiki)
        insert_ancestor_nodes(acc, page)
        insert_page_node(acc, page)

        acc
      end

      tree_construct[:root].children
    end

    def insert_wiki_node(accumulator, wiki)
      wiki_node = accumulator[:all_nodes].find { it.key == node_key(type: :wiki, identifier: wiki.identifier) }
      return if wiki_node.present?

      wiki_node = Adapters::Results::PageSearchTreeNode.new(identifier: wiki.identifier,
                                                            type: :wiki,
                                                            name: wiki.name,
                                                            children: [],
                                                            enabled: false)
      accumulator[:all_nodes] << wiki_node
      accumulator[:root].children << wiki_node
    end

    def insert_ancestor_nodes(accumulator, page) # rubocop:disable Metrics/AbcSize
      ancestors = page.ancestors
      wiki = page.wiki
      previous_ancestor_node = accumulator[:all_nodes].find do |node|
        node.key == node_key(type: :wiki, identifier: wiki.identifier)
      end

      ancestors.reverse_each do |ancestor|
        ancestor_node = accumulator[:all_nodes].find { it.key == node_key(type: :page, identifier: ancestor.identifier) }
        if ancestor_node.nil?
          ancestor_node = to_tree_node(page: ancestor, enabled: false)
          previous_ancestor_node.children << ancestor_node
          accumulator[:all_nodes] << ancestor_node
        end

        previous_ancestor_node = ancestor_node
      end
    end

    def insert_page_node(accumulator, page_hierarchy)
      page_hierarchy => { page:, ancestors:, wiki: }

      return if enable_if_node_exists(accumulator, page)

      parent_node = find_parent(accumulator, ancestors, wiki)
      new_node = to_tree_node(page:, enabled: true)
      parent_node.children << new_node
      accumulator[:all_nodes] << new_node
    end

    def find_parent(accumulator, ancestors, wiki)
      accumulator[:all_nodes].find do |node|
        parent_key = if ancestors.any?
                       node_key(type: :page, identifier: ancestors.first.identifier)
                     else
                       node_key(type: :wiki, identifier: wiki.identifier)
                     end
        node.key == parent_key
      end
    end

    def enable_if_node_exists(accumulator, page) # rubocop:disable Naming/PredicateMethod
      node = accumulator[:all_nodes].find { it.key == node_key(type: :page, identifier: page.identifier) }
      return false if node.nil?

      node.enabled = true
      true
    end

    def node_key(type:, identifier:)
      "#{type}:#{identifier}"
    end
  end
end
