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
          details_container.with_row(flex_layout: true, align_items: :center,
                                     justify_content: :space_between, classes: "details-header-container") do |header_container|
            header_container.with_column(flex_layout: true, align_items: :center) do |header_start_container|
              header_start_container.with_column(mr: 2, classes: "timeline-icon") do
                if journal.initial?
                  render Primer::Beta::Octicon.new(icon: "diff-added", size: :small, "aria-label": "Add", color: :subtle)
                else
                  render Primer::Beta::Octicon.new(icon: "diff-modified", size: :small, "aria-label": "Change", color: :subtle)
                end
              end
              header_start_container.with_column(mr: 2) do
                render Users::AvatarComponent.new(user: journal.user, show_name: false, size: :mini)
              end
              header_start_container.with_column(mr: 1) do
                render(Primer::Beta::Link.new(
                         href: user_url(journal.user),
                         target: "_blank",
                         scheme: :primary,
                         underline: false,
                         font_weight: :bold
                       )) do
                  journal.user.name
                end
              end
              header_start_container.with_column(mr: 1, classes: "hidden-for-mobile") do
                if journal.initial?
                  render(Primer::Beta::Text.new(color: :subtle, mt: 1)) do
                    t("activities.work_packages.activity_tab.created_on")
                  end
                else
                  render(Primer::Beta::Text.new(color: :subtle, mt: 1)) do
                    t("activities.work_packages.activity_tab.changed_on")
                  end
                end
              end
              header_start_container.with_column(mr: 1) do
                render(Primer::Beta::Text.new(color: :subtle, mt: 1)) { format_time(journal.updated_at) }
              end
            end
            header_container.with_column(flex_layout: true, align_items: :center) do |header_end_container|
              if has_unread_notifications
                header_end_container.with_column(mr: 2, pt: 1) do
                  bubble_html
                end
              end
              header_end_container.with_column(pr: 3) do
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
          end
        end

        def render_details(details_container)
          return if journal.initial? && journal_sorting == "desc"

          details_container.with_row(flex_layout: true, pt: 1, pb: 3) do |details_container_inner|
            if journal.initial?
              render_empty_line(details_container_inner)
            else
              journal.details.each do |detail|
                details_container_inner.with_row(flex_layout: true, my: 1, align_items: :flex_start) do |detail_container|
                  detail_container.with_column(classes: "detail-stem-line")
                  detail_container.with_column(pl: 1, font_size: :small) do
                    render(Primer::Beta::Text.new(classes: "detail-description")) { journal.render_detail(detail) }
                  end
                end
              end
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
          ".html_safe
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
