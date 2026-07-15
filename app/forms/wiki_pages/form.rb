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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WikiPages
  class Form < ApplicationForm
    form do |f|
      f.text_field(
        name: :title,
        label: I18n.t(:label_page_title),
        required: true
      )

      f.rich_text_area(
        name: :text,
        label: WikiPage.human_attribute_name(:text),
        visually_hide_label: true,
        rich_text_options: {
          with_text_formatting: true,
          macros: true,
          resource:,
          previewContext: preview_context,
          turboMode: false,
          showAttachments: false
        }
      )

      f.select_list(
        name: :parent_id,
        label: WikiPage.human_attribute_name(:parent_title),
        input_width: :xlarge
      ) do |list|
        helpers.wiki_page_options_for_select(model.wiki.pages).each do |label, value|
          list.option(
            label:,
            value:,
            selected: model.parent_id == value
          )
        end
      end

      f.text_field(
        name: :journal_notes,
        label: I18n.t(:"attributes.comment"),
        visually_hide_label: true,
        autocomplete: :off,
        input_width: :xlarge,
        placeholder: I18n.t(:text_what_did_you_change_click_to_add_comment)
      )

      f.group(layout: :horizontal) do |button_group|
        button_group.submit(
          name: :save,
          label: I18n.t(:button_save),
          scheme: :primary
        ) do |button|
          button.with_leading_visual_icon(icon: :check)
        end

        button_group.button(
          name: :cancel,
          label: I18n.t(:button_cancel),
          tag: :a,
          href: cancel_href,
          data: { turbo_confirm: I18n.t(:text_are_you_sure) }
        )
      end
    end

    private

    def resource
      return unless model

      API::V3::WikiPages::WikiPageRepresenter.new(
        model, current_user: User.current, embed_links: true
      )
    end

    def preview_context
      helpers.preview_context(model, model.project)
    end

    def cancel_href
      if model.new_record?
        url_helpers.url_for(controller: "wiki", action: "show", project_id: model.project, only_path: true)
      else
        url_helpers.project_wiki_path(model.project, model)
      end
    end
  end
end
