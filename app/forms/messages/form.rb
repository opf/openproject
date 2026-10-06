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
  class Form < ApplicationForm
    form do |f|
      unless replying?
        f.text_field(
          name: :subject,
          label: Message.human_attribute_name(:subject),
          required: true,
          autofocus: true,
          autocomplete: "off",
          input_width: :large
        )
      end

      if moderating?
        f.check_box(name: :sticky, label: I18n.t("js.label_board_sticky"))
        f.check_box(name: :locked, label: I18n.t("js.label_board_locked"))
      end

      if relocatable?
        f.select_list(name: :forum_id, label: Forum.model_name.human, input_width: :large) do |list|
          model.project.forums.each do |forum|
            list.option(label: forum.name, value: forum.id, selected: forum.id == model.forum_id)
          end
        end
      end

      f.rich_text_area(
        name: :content,
        label: I18n.t(:description_message_content),
        visually_hide_label: replying?,
        required: true,
        rich_text_options: {
          with_text_formatting: true,
          resource:,
          previewContext: helpers.preview_context(model),
          turboMode: false
        }
      )

      f.group(layout: :horizontal) do |buttons|
        buttons.button(name: :cancel, label: I18n.t(:button_cancel), tag: :a, href: cancel_href) if cancel_href
        buttons.submit(name: :submit, label: submit_label, scheme: :primary)
      end
    end

    def initialize(submit_label:, replying: false, cancel_href: nil)
      super()
      @submit_label = submit_label
      @replying = replying
      @cancel_href = cancel_href
    end

    private

    attr_reader :submit_label, :cancel_href

    def replying? = @replying

    def moderating?
      !replying? && User.current.allowed_in_project?(:edit_messages, model.project)
    end

    def relocatable? = moderating? && model.persisted?

    def resource
      API::V3::Posts::PostRepresenter.new(model, current_user: User.current, embed_links: true)
    end
  end
end
