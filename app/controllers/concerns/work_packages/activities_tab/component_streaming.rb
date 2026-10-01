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

module WorkPackages
  module ActivitiesTab
    # Renders the activity tab's ViewComponents as turbo-stream mutations: the index
    # shell and list, and individual journal items in their show/edit states. Mixed
    # into the controller so it emits through OpTurbo and reads the request state the
    # before_actions set up (@work_package, @paginated_journals, @paginator, @filter,
    # @resolved_anchor) along with #initialize_pagination and #get_current_server_timestamp.
    module ComponentStreaming
      extend ActiveSupport::Concern

      private

      def replace_whole_tab
        initialize_pagination # re-initialize pagination to pick up changes to sorting/filtering
        replace_via_turbo_stream(component: lazy_index_shell)
      end

      def update_index_component
        initialize_pagination # re-initialize pagination to pick up changes to sorting/filtering
        update_via_turbo_stream(component: lazy_index_list)
      end

      def lazy_index_shell
        WorkPackages::ActivitiesTab::LazyIndexComponent.new(
          work_package: @work_package,
          journals: @paginated_journals,
          paginator: @paginator,
          filter: @filter,
          last_server_timestamp: get_current_server_timestamp,
          resolved_anchor: @resolved_anchor
        )
      end

      def lazy_index_list
        WorkPackages::ActivitiesTab::Journals::LazyIndexComponent.new(
          work_package: @work_package,
          journals: @paginated_journals,
          paginator: @paginator,
          filter: @filter
        )
      end

      def update_item_edit_component(journal:, grouped_emoji_reactions: {})
        update_item_component(journal:, state: :edit, grouped_emoji_reactions:)
      end

      def update_item_show_component(journal:, grouped_emoji_reactions:)
        update_item_component(journal:, state: :show, grouped_emoji_reactions:)
      end

      def update_item_component(journal:, grouped_emoji_reactions:, state:, filter: @filter)
        update_via_turbo_stream(
          component: WorkPackages::ActivitiesTab::Journals::ItemComponent.new(
            journal:,
            state:,
            filter:,
            grouped_emoji_reactions:
          )
        )
      end
    end
  end
end
