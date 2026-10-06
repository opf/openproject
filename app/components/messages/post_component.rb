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

module Messages
  class PostComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    with_collection_parameter :message

    def initialize(message:, topic:)
      super
      @message = message
      @topic = topic
    end

    private

    attr_reader :message, :topic

    def reply? = message.parent_id.present?

    def project = topic.project

    def forum = topic.forum

    def quotable?
      !topic.locked? && User.current.allowed_in_project?(:add_messages, project)
    end

    def action_menu # rubocop:disable Metrics/AbcSize
      render(Primer::Alpha::ActionMenu.new(test_selector: "message-actions-#{message.id}")) do |menu|
        menu.with_show_button(icon: "kebab-horizontal", scheme: :invisible, "aria-label": t("forums.topic.message_actions"))

        copy_link_item(menu)
        quote_item(menu) if quotable?
        edit_item(menu) if message.editable_by?(User.current)
        with_item_group(menu) { delete_item(menu) } if reply? && message.destroyable_by?(User.current)
      end
    end

    def copy_link_item(menu)
      menu.with_item(label: t(:button_copy_link_to_clipboard),
                     tag: :"clipboard-copy",
                     content_arguments: { value: helpers.message_url(message) }) do |item|
        item.with_leading_visual_icon(icon: :copy)
      end
    end

    def quote_item(menu)
      menu.with_item(label: t(:button_quote),
                     href: quote_project_forum_topic_path(project, forum, message),
                     content_arguments: { data: { action: "forum-messages#quote" } }) do |item|
        item.with_leading_visual_icon(icon: :quote)
      end
    end

    def edit_item(menu)
      menu.with_item(label: t(:button_edit), href: edit_project_forum_topic_path(project, forum, message)) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end
    end

    def delete_item(menu)
      menu.with_item(label: t(:button_delete),
                     tag: :button,
                     scheme: :danger,
                     href: project_forum_topic_path(project, forum, message),
                     content_arguments: { data: { turbo_confirm: t(:text_are_you_sure) } },
                     form_arguments: { method: :delete }) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end
  end
end
