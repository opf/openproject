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

    # The list item component to use for backlog cards: a lazily loaded
    # turbo-frame placeholder when the backlogs_lazy_cards feature is enabled,
    # or this inline card component otherwise.
    def self.for_current_feature
      if OpenProject::FeatureDecisions.backlogs_lazy_cards_active?
        WorkPackageCardListItemLoadingComponent
      else
        self
      end
    end

    private

    def build_card
      # The card wires up its own interactive behaviour and classes from the
      # work package, project and user, so that it renders identically whether
      # inline here or lazily through Backlogs::WorkPackages::CardsController.
      WorkPackageCardComponent.new(
        work_package:,
        project:,
        menu_src:,
        current_user:
      )
    end

    def draggable?
      user_allowed?(:manage_sprint_items)
    end

    def menu_src
      url_helpers.menu_project_backlogs_work_package_path(project, work_package)
    end

    def draggable_data
      {
        controller: "sortable-lists--item",
        sortable_lists__item_id_value: work_package.id,
        sortable_lists__item_type_value: "work_package"
      }
    end

    public

    def row_args
      arguments = super
      arguments[:draggable] = true if draggable?
      arguments
    end
  end
end
