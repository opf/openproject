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
    class LazyIndexComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable
      include WorkPackages::ActivitiesTab::SharedHelpers
      include WorkPackages::ActivitiesTab::StimulusControllers

      def initialize(work_package:, journals:, paginator:, last_server_timestamp:, filter: Filters::ALL, resolved_anchor: nil)
        super

        @work_package = work_package
        @journals = journals
        @paginator = paginator
        @last_server_timestamp = last_server_timestamp
        @filter = filter
        @resolved_anchor = resolved_anchor
      end

      def self.wrapper_key = "work-package-activities-tab-content"
      def self.index_content_wrapper_key = WorkPackages::ActivitiesTab::StimulusControllers.index_stimulus_controller
      def self.add_comment_wrapper_key = "work-packages-activities-tab-add-comment-component"
      delegate :index_content_wrapper_key, :add_comment_wrapper_key, to: :class

      def list_journals_component
        WorkPackages::ActivitiesTab::Journals::LazyIndexComponent
          .new(work_package:, journals:, filter:, paginator:)
      end

      private

      attr_reader :work_package, :journals, :paginator, :filter, :last_server_timestamp, :resolved_anchor

      def wrapper_data_attributes # rubocop:disable Metrics/AbcSize
        stimulus_controllers = {
          controller: [
            index_stimulus_controller,
            polling_stimulus_controller,
            editor_stimulus_controller,
            auto_scrolling_stimulus_controller,
            stems_stimulus_controller
          ].join(" ")
        }
        stimulus_controller_values = {
          editor_stimulus_controller("-unsaved-changes-confirmation-message-value") => unsaved_changes_confirmation_message,
          index_stimulus_controller("-notification-center-path-name-value") => notifications_path,
          index_stimulus_controller("-sorting-value") => journal_sorting,
          index_stimulus_controller("-filter-value") => filter,
          index_stimulus_controller("-user-id-value") => User.current.id,
          index_stimulus_controller("-work-package-id-value") => work_package.id,
          polling_stimulus_controller("-last-server-timestamp-value") => last_server_timestamp,
          polling_stimulus_controller("-polling-interval-in-ms-value") => polling_interval,
          polling_stimulus_controller("-show-conflict-flash-message-url-value") => show_conflict_flash_message_work_packages_path,
          polling_stimulus_controller("-update-streams-path-value") => update_streams_work_package_activities_path(work_package)
        }
        # Only a legacy activity-N deep link sets this; it tells the client which
        # comment anchor the activity number resolved to so it can scroll there.
        if resolved_anchor
          stimulus_controller_values[auto_scrolling_stimulus_controller("-resolved-comment-id-value")] = resolved_anchor
        end
        stimulus_controller_outlets = {
          editor_stimulus_controller("-#{auto_scrolling_stimulus_controller}-outlet") => index_component_dom_selector,
          editor_stimulus_controller("-#{polling_stimulus_controller}-outlet") => index_component_dom_selector,
          editor_stimulus_controller("-#{stems_stimulus_controller}-outlet") => index_component_dom_selector,
          polling_stimulus_controller("-#{auto_scrolling_stimulus_controller}-outlet") => index_component_dom_selector,
          polling_stimulus_controller("-#{stems_stimulus_controller}-outlet") => index_component_dom_selector
        }

        { test_selector: "op-wp-activity-tab" }
            .merge(stimulus_controllers)
            .merge(stimulus_controller_values)
            .merge(stimulus_controller_outlets)
      end

      def add_comment_wrapper_data_attributes
        {
          test_selector: "op-work-package-journal--new-comment-component",
          controller: internal_comment_stimulus_controller,
          internal_comment_stimulus_controller("-target") => "formContainer",
          action: editor_stimulus_controller(":onSubmit-end@window->#{internal_comment_stimulus_controller}#onSubmitEnd"),
          internal_comment_stimulus_controller("-highlight-class") => "work-packages-activities-tab-journals-new-component--journal-notes-body__internal-comment", # rubocop:disable Layout/LineLength
          internal_comment_stimulus_controller("-hidden-class") => "d-none",
          internal_comment_stimulus_controller("-is-internal-value") => false, # Initial value
          internal_comment_stimulus_controller("-#{editor_stimulus_controller}-outlet") => index_component_dom_selector
        }
      end

      def polling_interval
        # Polling interval should only be adjustable in test environment
        if Rails.env.test?
          ENV["WORK_PACKAGES_ACTIVITIES_TAB_POLLING_INTERVAL_IN_MS"].presence || 10000
        else
          10000
        end
      end

      def adding_comment_allowed?
        User.current.allowed_in_work_package?(:add_work_package_comments, @work_package)
      end

      def unsaved_changes_confirmation_message
        I18n.t("activities.work_packages.activity_tab.unsaved_changes_confirmation_message")
      end
    end
  end
end
