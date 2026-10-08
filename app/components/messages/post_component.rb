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

    def initialize(message:, focus: false)
      super
      @message = message
      @focus = focus
    end

    private

    attr_reader :message

    def reply? = message.parent_id.present?

    def topic = message.parent || message

    def project = message.project

    def forum = message.forum

    def quotable?
      !topic.locked? && User.current.allowed_in_project?(:add_messages, project)
    end

    def byline # rubocop:disable Metrics/AbcSize
      flex_layout(align_items: :center, justify_content: :space_between) do |line|
        line.with_column(flex_layout: true, flex_wrap: :wrap, align_items: :center) do |author_and_time|
          if message.author
            author_and_time.with_column(mr: 2) do
              render(Users::AvatarComponent.new(user: message.author, show_name: false, size: :mini))
            end
            author_and_time.with_column(mr: 2) do
              helpers.primer_link_to_user(message.author, scheme: :primary, font_weight: :bold, hover_card: true)
            end
          end
          author_and_time.with_column { anchor_link }
        end
        line.with_column(ml: 1) { action_menu }
      end
    end

    def anchor_link
      render(Primer::Beta::Link.new(href: helpers.message_anchor_path(message), scheme: :secondary, underline: false,
                                    font_size: :small, data: { turbo: false })) do
        helpers.format_time(message.created_at)
      end
    end

    def action_menu # rubocop:disable Metrics/AbcSize
      render(Primer::Alpha::ActionMenu.new(test_selector: "message-actions-#{message.id}")) do |menu|
        menu.with_show_button(icon: "kebab-horizontal", scheme: :invisible, "aria-label": t("forums.topic.message_actions"))

        copy_link_item(menu)
        quote_item(menu) if quotable?
        create_work_package_item(menu) if work_package_creatable?
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

    def work_package_creatable?
      User.current.allowed_in_project?(:add_work_packages, project)
    end

    def create_work_package_item(menu)
      menu.with_item(label: t("forums.topic.create_work_package"),
                     href: new_project_forum_topic_work_package_path(project, forum, message),
                     test_selector: "message-create-work-package-#{message.id}",
                     content_arguments: { data: { controller: "async-dialog" } }) do |item|
        item.with_leading_visual_icon(icon: :"issue-opened")
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
