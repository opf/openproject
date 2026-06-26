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
    # Suffix appended to a work package's dom_id to build its card turbo-frame
    # id. Shared with WorkPackageCardListItemLoadingComponent so the lazily
    # loaded placeholder and the rendered card target the same frame, and with
    # the backlogs Stimulus controller which keys cached frames off it.
    FRAME_ID_SUFFIX = "_card"

    attr_reader :work_package, :menu_src

    delegate :with_menu, :with_metric, to: :card

    # @param work_package [WorkPackage] the work package the frame wraps.
    # @return [String] the turbo-frame id for that work package's card.
    def self.frame_id(work_package)
      "#{ActionView::RecordIdentifier.dom_id(work_package)}#{FRAME_ID_SUFFIX}"
    end

    def initialize(work_package:, menu_src: nil)
      super()

      @work_package = work_package
      @menu_src = menu_src
    end

    def call
      # Wrapped in a turbo-frame so the lazily loaded placeholder rendered by
      # WorkPackageCardListItemLoadingComponent is replaced once the controller
      # response arrives.
      helpers.turbo_frame_tag(card_frame_id) do
        render(card) do |common_card|
          unless common_card.metric?
            common_card.with_metric do
              render(Backlogs::StoryPointsComponent.new(work_package:))
            end
          end
        end
      end
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
        status_scheme: :secondary
      )
    end

    def before_render
      content
    end
  end
end
