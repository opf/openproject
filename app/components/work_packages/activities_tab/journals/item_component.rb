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
        include WorkPackages::ActivitiesTab::SharedHelpers
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable

        def initialize(journal:, filter:, state: :show)
          super

          @journal = journal
          @state = state
          @filter = filter
        end

        private

        attr_reader :journal, :state, :filter

        def wrapper_uniq_by
          journal.id
        end

        def wrapper_data_attributes
          {
            controller: "work-packages--activities-tab--item",
            "application-target": "dynamic",
            "work-packages--activities-tab--item-activity-url-value": activity_url
          }
        end

        def show_comment_container?
          (journal.notes.present? || noop?) && filter != :only_changes
        end

        def noop?
          journal.noop?
        end

        def activity_url
          "#{project_work_package_url(journal.journable.project, journal.journable)}/activity#{activity_anchor}"
        end

        def activity_anchor
          "#activity-#{journal.version}"
        end

        def updated?
          return false if journal.initial?

          journal.updated_at - journal.created_at > 5.seconds
        end

        def has_unread_notifications?
          journal.notifications.where(read_ian: false, recipient_id: User.current.id).any?
        end

        def notification_on_details?
          has_unread_notifications? && journal.notes.blank?
        end

        def allowed_to_edit?
          journal.editable_by?(User.current)
        end

        def allowed_to_quote?
          User.current.allowed_in_project?(:add_work_package_notes, journal.journable.project)
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
                         href: edit_work_package_activity_path(journal.journable, journal, filter:),
                         content_arguments: {
                           data: { turbo_stream: true, test_selector: "op-wp-journal-#{journal.id}-edit" }
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
                             "user-name-param": I18n.t(:text_user_wrote, value: ERB::Util.html_escape(journal.user)),
                             test_selector: "op-wp-journal-#{journal.id}-quote"
                           }
                         }) do |item|
            item.with_leading_visual_icon(icon: :quote)
          end
        end
      end
    end
  end
end
