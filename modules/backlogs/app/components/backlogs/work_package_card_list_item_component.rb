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

module Backlogs
  class WorkPackageCardListItemComponent < OpenProject::Common::BorderBoxListComponent::WorkPackageItem
    include CommonHelper

    private

    def build_card
      WorkPackageCardComponent.new(
        work_package:,
        menu_src:,
        **card_arguments
      )
    end

    def draggable?
      user_allowed?(:manage_sprint_items)
    end

    def split_url
      url_helpers.project_backlogs_backlog_details_path(project, work_package, params)
    end

    def full_url
      url_helpers.work_package_path(work_package)
    end

    def move_url
      url_helpers.move_project_backlogs_work_package_path(project, work_package, params)
    end

    def menu_src
      url_helpers.menu_project_backlogs_work_package_path(project, work_package, params)
    end

    def card_arguments
      {
        classes: "Box-card",
        tabindex: 0,
        data: card_data
      }
    end

    def card_data
      data = {
        story: true,
        controller: "backlogs--story",
        backlogs__story_id_value: work_package.id,
        backlogs__story_display_id_value: work_package.display_id,
        backlogs__story_split_url_value: split_url,
        backlogs__story_full_url_value: full_url,
        backlogs__story_selected_class: "Box-row--blue"
      }

      return data unless draggable?

      data.merge(sortable_lists__item_target: "preview handle")
    end

    def draggable_data
      {
        controller: "sortable-lists--item",
        sortable_lists__item_id_value: work_package.id,
        sortable_lists__item_type_value: "work_package",
        sortable_lists__item_move_url_value: move_url
      }
    end

    public

    def row_args
      arguments = super
      arguments.delete(:tabindex)
      arguments[:draggable] = true if draggable?
      arguments
    end
  end
end
