#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
    module Journals
      class ItemComponent::Details < ApplicationComponent
        include ApplicationHelper
        include AvatarHelper
        include JournalFormatter
        include WorkPackages::ActivitiesTab::SharedHelpers
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable

        def initialize(journal:, filter:, has_unread_notifications: false)
          super

          @journal = journal
          @has_unread_notifications = has_unread_notifications
          @filter = filter
        end

        private

        attr_reader :journal, :has_unread_notifications, :filter

        def wrapper_uniq_by
          journal.id
        end

        def render_details_header(details_container)
          details_container.with_row(
            flex_layout: true,
            justify_content: :space_between,
            classes: "work-packages-activities-tab-journals-item-component-details--journal-details-header-container",
            id: "activity-#{journal.version}"
          ) do |header_container|
            render_header_start(header_container)
            render_header_end(header_container)
          end
        end

        def render_header_start(header_container)
          header_container.with_column(
            flex_layout: true,
            classes: "work-packages-activities-tab-journals-item-component-details--journal-details-header",
            data: { "test-selector": "op-journal-details-header" }
          ) do |header_start_container|
            render_timeline_icon(header_start_container)
            render_user_avatar(header_start_container)
            render_user_name_and_time(header_start_container)
            # render_created_or_changed_on_text(header_start_container)
            render_updated_time(header_start_container)
          end
        end

        def render_timeline_icon(container)
          container.with_column(mr: 2, classes: "work-packages-activities-tab-journals-item-component-details--timeline-icon") do
            icon_name = journal.initial? ? "diff-added" : "diff-modified"
            render Primer::Beta::Octicon.new(icon: icon_name, size: :small, "aria-label": icon_aria_label, color: :subtle)
          end
        end

        def render_user_avatar(container)
          container.with_column(mr: 2) do
            render Users::AvatarComponent.new(user: journal.user, show_name: false, size: :mini)
          end
        end

        def render_user_name_and_time(container)
          container.with_column(mr: 1, flex_layout: true) do |user_name_container|
            user_name_container.with_row { truncated_user_name(journal.user) }
            user_name_container.with_row(classes: "hidden-for-desktop") do
              render(Primer::Beta::Text.new(font_size: :small, color: :subtle, mt: 1)) { format_time(journal.created_at) }
            end
          end
        end

        def render_created_or_changed_on_text(container)
          container.with_column(mr: 1, classes: "hidden-for-mobile") do
            text_key = if journal.initial?
                         "activities.work_packages.activity_tab.created_on"
                       else
                         "activities.work_packages.activity_tab.changed_on"
                       end
            render(Primer::Beta::Text.new(font_size: :small, color: :subtle, mt: 1)) { t(text_key) }
          end
        end

        def render_updated_time(container)
          container.with_column(mr: 1, classes: "hidden-for-mobile") do
            render(Primer::Beta::Text.new(font_size: :small, color: :subtle, mt: 1)) { format_time(journal.updated_at) }
          end
        end

        def render_header_end(header_container)
          header_container.with_column(flex_layout: true) do |header_end_container|
            render_notification_bubble(header_end_container) if has_unread_notifications
            render_activity_link(header_end_container)
          end
        end

        def render_notification_bubble(container)
          container.with_column(mr: 2,
                                classes: "work-packages-activities-tab-journals-item-component-details--bubble-container") do
            bubble_html
          end
        end

        def render_activity_link(container)
          container.with_column(pr: 3) do
            render(Primer::Beta::Link.new(
                     href: activity_anchor,
                     scheme: :secondary,
                     underline: false,
                     font_size: :small,
                     data: { turbo: false }
                   )) do
              "##{journal.version}"
            end
          end
        end

        def icon_aria_label
          journal.initial? ? "Add" : "Change"
        end

        def render_details(details_container)
          return if skip_rendering_details?

          details_container.with_row(flex_layout: true, pt: 1, pb: 3) do |details_container_inner|
            if journal.initial?
              render_empty_line(details_container_inner)
            else
              render_journal_details(details_container_inner)
            end
          end
        end

        def skip_rendering_details?
          journal.initial? && journal_sorting == "desc"
        end

        def render_journal_details(details_container_inner)
          journal.details.each do |detail|
            render_single_detail(details_container_inner, detail)
          end
        end

        def render_single_detail(container, detail)
          container.with_row(flex_layout: true, my: 1, align_items: :flex_start) do |detail_container|
            render_stem_line(detail_container)
            render_detail_description(detail_container, detail)
          end
        end

        def render_stem_line(container)
          container.with_column(classes: "work-packages-activities-tab-journals-item-component-details--journal-detail-stem-line")
        end

        def render_detail_description(container, detail)
          container.with_column(pl: 1, font_size: :small) do
            render(Primer::Beta::Text.new(
                     classes: "work-packages-activities-tab-journals-item-component-details--journal-detail-description",
                     data: { "test-selector": "op-journal-detail-description" }
                   )) do
              journal.render_detail(detail)
            end
          end
        end

        def render_empty_line(details_container)
          details_container.with_row(my: 1, font_size: :small, classes: "empty-line")
        end

        def bubble_html
          "
          <span
            class=\"comments-number--bubble op-bubble op-bubble_mini\"
            data-test-selector=\"user-activity-bubble\"
          ></span>
          ".html_safe # rubocop:disable Rails/OutputSafety
        end

        def activity_anchor
          "#activity-#{journal.version}"
        end

        def journal_sorting
          User.current.preference&.comments_sorting || "desc"
        end
      end
    end
  end
end
