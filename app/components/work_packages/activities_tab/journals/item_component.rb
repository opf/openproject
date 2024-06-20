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
      class ItemComponent < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable

        def initialize(journal:, state: :show)
          super

          @journal = journal
          @state = state
        end

        def content
          case state
          when :show
            render(WorkPackages::ActivitiesTab::Journals::ItemComponent::Show.new(**child_component_params))
          when :edit
            render(WorkPackages::ActivitiesTab::Journals::ItemComponent::Edit.new(**child_component_params))
          end
        end

        private

        attr_reader :journal, :state

        def wrapper_uniq_by
          journal.id
        end

        def child_component_params
          { journal: }.compact
        end

        def wrapper_data_attributes
          {
            controller: "work-packages--activities-tab--item",
            "application-target": "dynamic",
            "work-packages--activities-tab--item-activity-url-value": activity_url
          }
        end

        def activity_url
          "#{project_work_package_url(journal.journable.project, journal.journable)}/activity#{activity_anchor}"
        end

        def activity_anchor
          "#activity-#{journal.version}"
        end

        def editable?
          journal.user == User.current
        end

        def updated?
          return false if journal.initial?

          journal.updated_at - journal.created_at > 5.seconds
        end

        def has_unread_notifications?
          journal.notifications.where(read_ian: false, recipient_id: User.current.id).any?
        end

        def copy_url_action_item(menu)
          menu.with_item(label: t("button_copy_link_to_clipboard"),
                         tag: :button,
                         content_arguments: {
                           data: {
                             action: "click->work-packages--activities-tab--item#copyActivityUrlToClipboard"
                           }
                         }) do |item|
            item.with_leading_visual_icon(icon: :copy)
          end
        end

        def edit_action_item(menu)
          menu.with_item(label: t("js.label_edit_comment"),
                         href: edit_work_package_activity_path(journal.journable, journal),
                         content_arguments: {
                           data: { "turbo-stream": true }
                         }) do |item|
            item.with_leading_visual_icon(icon: :pencil)
          end
        end

        def quote_action_item(menu)
          menu.with_item(label: t("js.label_quote_comment"),
                         tag: :button,
                         content_arguments: {
                           data: {
                             action: "click->work-packages--activities-tab--index#quote",
                             "content-param": journal.notes,
                             "user-name-param": I18n.t(:text_user_wrote, value: ERB::Util.html_escape(journal.user))
                           }
                         }) do |item|
            item.with_leading_visual_icon(icon: :quote)
          end
        end

        def bubble_html
          "
          <span
            class=\"comments-number--bubble op-bubble op-bubble_mini\"
            data-test-selector=\"user-activity-bubble\"
          ></span>
          ".html_safe
        end
      end
    end
  end
end
