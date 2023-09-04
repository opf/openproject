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

module Meetings
  class HeaderComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:, state: :show)
      super

      @meeting = meeting
      @state = state
    end

    def call
      component_wrapper do
        case @state
        when :show
          show_partial
        when :edit
          edit_partial if edit_enabled?
        end
      end
    end

    private

    def edit_enabled?
      User.current.allowed_to?(:edit_meetings, @meeting.project)
    end

    def delete_enabled?
      User.current.allowed_to?(:delete_meetings, @meeting.project)
    end

    def show_partial
      flex_layout do |flex|
        flex.with_row do
          title_and_actions_partial
        end
        flex.with_row do
          meta_info_partial
        end
      end
    end

    def title_and_actions_partial
      flex_layout(justify_content: :space_between, align_items: :center) do |flex|
        flex.with_column(flex: 1) do
          title_partial
        end
        flex.with_column do
          actions_partial
        end
      end
    end

    def title_partial
      render(Primer::Beta::Heading.new(tag: :h1)) { @meeting.title }
    end

    def actions_partial
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(icon: "kebab-horizontal", 'aria-label': t("label_meeting_actions"))
        edit_action_item(menu) if edit_enabled?
        delete_action_item(menu) if delete_enabled?
      end
    end

    def edit_action_item(menu)
      menu.with_item(label: t("label_meeting_edit_title"),
                     href: edit_meeting_path(@meeting),
                     content_arguments: {
                       data: { 'turbo-stream': true }
                     }) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end
    end

    def delete_action_item(menu)
      menu.with_item(label: t("label_meeting_delete"),
                     scheme: :danger,
                     href: meeting_path(@meeting),
                     form_arguments: {
                       method: :delete, data: { confirm: t("text_are_you_sure") }
                     }) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end

    def meta_info_partial
      flex_layout(align_items: :center) do |flex|
        flex.with_column(mr: 1) do
          render(Primer::Beta::Text.new(font_size: :small, color: :subtle)) { t("label_meeting_created_by") }
        end
        flex.with_column(mr: 1) do
          author_link_partial
        end
        flex.with_column(mr: 1) do
          render(Primer::Beta::Text.new(font_size: :small, color: :subtle)) { t("label_meeting_last_updated") }
        end
        flex.with_column do
          render(Primer::Beta::RelativeTime.new(font_size: :small, color: :subtle, datetime: last_updated_at))
        end
      end
    end

    def author_link_partial
      render(Primer::Beta::Link.new(font_size: :small, href: user_path(@meeting.author), underline: false,
                                    target: "_blank")) do
        "#{@meeting.author.name}."
      end
    end

    def last_updated_at
      latest_agenda_update = @meeting.agenda_items.maximum(:updated_at) || @meeting.updated_at
      latest_meeting_update = @meeting.updated_at

      [latest_agenda_update, latest_meeting_update].max
    end

    def edit_partial
      flex_layout do |flex|
        flex.with_row(mb: 2) do
          title_form_partial
        end
        flex.with_row do
          meta_info_partial
        end
      end
    end

    def title_form_partial
      primer_form_with(
        model: @meeting,
        method: :put,
        url: update_title_meeting_path(@meeting)
      ) do |f|
        form_content_partial(f)
      end
    end

    def form_content_partial(form)
      flex_layout do |flex|
        flex.with_column(flex: 1, mr: 2) do
          render(Meeting::Title.new(form))
        end
        flex.with_column(mr: 2) do
          render(Meeting::Submit.new(form))
        end
        flex.with_column do
          back_link_partial
        end
      end
    end

    def back_link_partial
      render(Primer::Beta::Button.new(
               scheme: :secondary,
               tag: :a,
               href: cancel_edit_meeting_path(@meeting),
               data: { 'turbo-stream': true }
             )) do |_c|
        t("button_cancel")
      end
    end
  end
end
