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
  class BrowsePagesService
    include Dry::Monads[:result]

    def initialize(provider:, user:)
      @provider = provider
      @user = user
    end

    def call(parent_identifier)
      browse_pages(parent_identifier)
        .either(->(page_hierarchies) { build_result_tree(page_hierarchies, parent_identifier) },
                ->(error) { error.code == :not_found ? Success([]) : Failure(error) })
    end

    private

    attr_reader :user, :provider

    def build_result_tree(page_hierarchies, parent_identifier)
      root_node = Adapters::Results::PageSearchTreeNode.root

      page_hierarchies.each do |page_hierarchy|
        page_hierarchy => { page:, wiki: }

        parent_node = if parent_identifier.blank?
                        root_node.find_or_add_child(Adapters::Results::PageSearchTreeNode.wiki(wiki.identifier, wiki.name))
                      else
                        root_node
                      end

        parent_node.find_or_add_child(Adapters::Results::PageSearchTreeNode.page(page.identifier, page.title))
      end

      Success(root_node.children)
    end

    def browse_pages(parent_identifier)
      Adapters::Input::BrowsePages.build(parent_identifier:).bind do |input_data|
        provider.auth_strategy_for(user).bind do |auth_strategy|
          provider.resolve("queries.browse_pages").call(input_data:, auth_strategy:)
        end
      end
    end
  end
end
