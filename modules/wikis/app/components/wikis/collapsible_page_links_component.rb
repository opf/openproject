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
  class CollapsiblePageLinksComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers

    attr_reader :heading, :container

    alias_method :page_links, :model

    def initialize(model = nil, heading:, container:, linkable:, already_related_page_keys:, **)
      @heading = heading
      @container = container
      @linkable = linkable
      @already_related_page_keys = already_related_page_keys

      super(model, **)
    end

    private

    attr_reader :linkable, :already_related_page_keys

    def menu_actions_for(page_info_result)
      page_info_result.either(
        ->(page_info) do
          can_manage_links? ? [add_to_relation_action(page_info:, already_related: already_related?(page_info))] : []
        end,
        ->(_failure) { [] }
      )
    end

    def already_related?(page_info)
      already_related_page_keys.include?([page_info.provider.id, page_info.identifier])
    end

    def add_to_relation_action(page_info:, already_related:)
      PageLinkComponent::AddToRelatedAction.new(page_info:, linkable:, already_related:)
    end

    def can_manage_links?
      helpers.current_user.allowed_in_project?(:manage_wiki_page_links, linkable.project)
    end
  end
end
