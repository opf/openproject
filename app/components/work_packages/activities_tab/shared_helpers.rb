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
  module ActivitiesTab
    module SharedHelpers
      extend ActiveSupport::Concern

      included do
        include WorkPackages::ActivitiesTab::JournalSortingInquirable
      end

      def truncated_user_name(user, hover_card: false)
        helpers.primer_link_to_user(user, scheme: :primary, font_weight: :bold, hover_card:)
      end

      def activity_anchor_link(journal)
        auto_scrolling_controller = WorkPackages::ActivitiesTab::StimulusControllers.auto_scrolling_stimulus_controller

        render(Primer::Beta::Link.new(
                 href: activity_url(journal),
                 scheme: :secondary,
                 underline: false,
                 font_size: :small,
                 data: {
                   test_selector: "activity-anchor-link",
                   turbo: false,
                   action: "click->#{auto_scrolling_controller}#setAnchor:prevent",
                   "#{auto_scrolling_controller}-id-param": journal_activity_id(journal),
                   "#{auto_scrolling_controller}-anchor-name-param": activity_anchor_name
                 }
               )) do
          journal_created_at_formatted_time(journal)
        end
      end

      def journal_created_at_formatted_time(journal)
        render(Primer::Beta::Text.new(font_size: :small, color: :subtle, mt: 1)) do
          format_time(journal.created_at)
        end
      end

      def activity_url(journal)
        "#{project_work_package_url(journal.journable.project, journal.journable)}/activity#{activity_anchor(journal)}"
      end

      def activity_anchor(journal)
        "##{activity_anchor_name}-#{journal_activity_id(journal)}"
      end

      def activity_anchor_name
        "comment"
      end

      def journal_activity_id(journal)
        journal.id
      end
    end
  end
end
