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
        label: WikiPage.human_attribute_name(:title),
        required: true
      )

      f.select_list(
        name: :parent_id,
        label: WikiPage.human_attribute_name(:parent_title)
      ) do |list|
        helpers.wiki_page_options_for_select(model.wiki.pages).each do |label, value|
          list.option(
            label:,
            value:,
            selected: model.parent_id == value
          )
        end
      end

      unless create?
        f.hidden(name: :lock_version)
      end

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

      f.text_field(
        name: :journal_notes,
        label: I18n.t(:"attributes.comment"),
        caption: I18n.t(:text_wiki_page_comment_caption),
        autocomplete: :off,
        input_width: :large,
        placeholder: I18n.t(:text_wiki_page_comment_placeholder)
      )

      f.group(layout: :horizontal) do |button_group|
        button_group.submit(
          name: :save,
          label: submit_label,
          scheme: :primary
        )

        unless create?
          button_group.button(
            name: :cancel,
            label: I18n.t(:button_cancel),
            tag: :a,
            href: cancel_href,
            data: { turbo_confirm: I18n.t(:text_are_you_sure) }
          )
        end
      end
    end

    def initialize(create:)
      super()
      @create = create
    end

    private

    attr_reader :create
    alias_method :create?, :create

    def resource
      return unless model

      API::V3::WikiPages::WikiPageRepresenter.new(
        model,
        current_user: User.current,
        embed_links: true
      )
    end

    def submit_label
      if create?
        I18n.t(:button_create)
      else
        I18n.t(:button_save)
      end
    end

    def preview_context
      helpers.preview_context(model, model.project)
    end

    def cancel_href
      url_helpers.url_for(controller: "wiki",
                          action: "show",
                          project_id: model.wiki.project,
                          id: model.new_record? ? nil : model,
                          only_path: true)
    end
  end
end
