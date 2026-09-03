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
  class WorkPackageCardComponent < ApplicationComponent
    include CommonHelper
    include Primer::ClassNameHelper
    include Primer::AttributesHelper

    # Prefix added to a work package's dom_id to build its card turbo-frame
    # id. Shared with WorkPackageCardListItemLoadingComponent so the lazily
    # loaded placeholder and the rendered card target the same frame.
    FRAME_ID_PREFIX = "card"

    attr_reader :work_package, :project, :menu_src, :current_user

    delegate :with_menu, :with_metric, to: :card

    # @param work_package [WorkPackage] the work package the frame wraps.
    # @return [String] the turbo-frame id for that work package's card.
    def self.frame_id(work_package)
      ActionView::RecordIdentifier.dom_id(work_package, FRAME_ID_PREFIX)
    end

    def initialize(work_package:, project:, menu_src: nil, current_user: User.current, **system_arguments)
      super()

      @work_package = work_package
      @project = project
      @menu_src = menu_src
      @current_user = current_user
      @system_arguments = system_arguments
    end

    def call
      card_html = render(card) do |common_card|
        unless common_card.metric?
          common_card.with_metric do
            render(Backlogs::StoryPointsComponent.new(work_package:))
          end
        end
      end

      return card_html unless OpenProject::FeatureDecisions.backlogs_lazy_cards_active?

      # With lazy cards enabled the card is wrapped in a turbo-frame so the
      # placeholder rendered by WorkPackageCardListItemLoadingComponent is
      # replaced once the controller response arrives.
      helpers.turbo_frame_tag(card_frame_id) { card_html }
    end

    def card_frame_id
      self.class.frame_id(work_package)
    end

    private

    def card
      @card ||= OpenProject::Common::WorkPackageCardComponent.new(
        work_package:,
        menu_src:,
        show_assignee: true,
        show_priority: true,
        show_parent: true,
        status_scheme: :secondary,
        **interactive_arguments
      )
    end

    # Interactive wiring applied to the card so it behaves identically whether it
    # is rendered inline by WorkPackageCardListItemComponent or lazily by
    # Backlogs::WorkPackages::CardsController. Previously this lived in the list
    # item, which meant the lazily loaded card lost it (no split view, keyboard
    # activation, selection or drag preview/handle).
    def interactive_arguments
      arguments = @system_arguments.deep_dup
      arguments[:classes] = class_names(arguments[:classes], card_classes)
      arguments[:tabindex] = arguments.fetch(:tabindex, 0)
      arguments[:data] = merge_data(arguments, { data: card_data })
      arguments[:aria] = merge_aria(arguments, { aria: card_aria })
      arguments
    end

    def card_classes
      class_names(
        "Box-card",
        "Box-card--clickable",
        "Box-card--draggable" => draggable?
      )
    end

    def card_data
      data = {
        story: true,
        # Non-movable cards opt in too: they have no move actions, but their
        # singular menu is still worth reaching contextually.
        controller: "backlogs--work-package contextual-action-menu",
        backlogs__work_package_id_value: work_package.id,
        backlogs__work_package_display_id_value: work_package.display_id,
        backlogs__work_package_split_url_value: split_url,
        backlogs__work_package_full_url_value: full_url
      }

      return data unless draggable?

      data.merge(sortable_lists__item_target: "preview handle")
    end

    def card_aria
      {
        keyshortcuts: "Enter Shift+F10",
        label: work_package.to_fs(:caption)
      }
    end

    def split_url
      # NOTE: the backlog filter params (e.g. all=true for the expanded inbox) are
      # intentionally omitted here so the card stays cache-independent of the
      # current filter. They are merged back in at navigation time from the
      # browser's href by the backlogs--work-package Stimulus controller.
      url_helpers.project_backlogs_backlog_details_path(project, work_package)
    end

    def full_url
      url_helpers.work_package_path(work_package)
    end

    def draggable?
      user_allowed?(:manage_sprint_items)
    end

    def before_render
      content
    end
  end
end
