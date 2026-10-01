# frozen_string_literal: true

# -- copyright
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
# ++

module WorkPackages
  module Progress
    # rubocop:disable OpenProject/AddPreviewForViewComponent
    class BaseModalComponent < ApplicationComponent
      # rubocop:enable OpenProject/AddPreviewForViewComponent
      include OpTurbo::Streamable

      FIELD_MAP = {
        "estimatedTime" => :estimated_hours,
        "work_package[estimated_hours]" => :estimated_hours,
        "remainingTime" => :remaining_hours,
        "work_package[remaining_hours]" => :remaining_hours,
        "work_package[status_id]" => :status_id,
        "statusId" => :status_id,
        "work_package[done_ratio]" => :done_ratio,
        "percentageDone" => :done_ratio,
        "" => :no_field
      }.freeze

      include ApplicationHelper
      include Turbo::FramesHelper
      include OpPrimer::ComponentHelpers
      include OpenProject::StaticRouting::UrlHelpers

      attr_reader :work_package,
                  :mode,
                  :focused_field,
                  :touched_field_map

      def initialize(work_package,
                     focused_field: nil,
                     touched_field_map: {},
                     submit_path: nil)
        super()

        @work_package = work_package
        @focused_field = map_field(focused_field)
        @touched_field_map = touched_field_map
        @submit_path = submit_path
      end

      # Defaults to the core progress controller, but callers reusing the modal
      # from another context (e.g. the resource planner) can point the form at
      # their own endpoint. The live preview derives its URL from the form
      # action too (`<action>/preview`), so a single override covers both.
      def submit_path
        return @submit_path if @submit_path

        if work_package.new_record?
          url_for(controller: "work_packages/progress",
                  action: "create")
        else
          url_for(controller: "work_packages/progress",
                  action: "update",
                  work_package_id: work_package.id)
        end
      end

      def learn_more_href
        OpenProject::Static::Links.url_for(:progress_tracking_docs)
      end

      private

      def map_field(field)
        # Scenarios when a field is not provided occur after a
        # form submission since the last focused element
        # was the submit button. In this case, don't focus on
        # an element by default.
        return nil if field.nil?

        FIELD_MAP[field.to_s].presence || :no_field
      end
    end
  end
end
