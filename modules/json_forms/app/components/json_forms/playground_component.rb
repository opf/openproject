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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module JsonForms
  class PlaygroundComponent < ApplicationComponent
    DOCS = { schema: [:json_schema, Schema::DOCS_URL], ui_schema: [:ui_schema, UiSchema::DOCS_URL] }.freeze

    def initialize(schema_text:, ui_schema_text:, errors:, form:)
      super
      @schema_text = schema_text
      @ui_schema_text = ui_schema_text
      @errors = errors
      @form = form
    end

    def call
      safe_join([
                  page_header,
                  render(Primer::Box.new(display: :flex, flex_wrap: :wrap, style: "gap: var(--stack-gap-spacious)")) do
                    safe_join([column(grow: 3) { editor }, column(grow: 2) { safe_join([render(@errors), render(@form)]) }])
                  end
                ])
    end

    private

    def page_header
      render(Primer::OpenProject::PageHeader.new) do |header|
        header.with_title { t("json_forms.playground.title") }
        header.with_breadcrumbs([{ href: home_path, text: t(:label_home) }, t("json_forms.playground.title")])
        header.with_description { t("json_forms.playground.description") }
      end
    end

    def column(grow:, &)
      render(Primer::Box.new(style: "flex: #{grow} 1 24rem; min-width: 0"), &)
    end

    # The form is posted to the preview action whenever an editor's content changes.
    def editor
      data = { controller: "refresh-on-form-changes", refresh_on_form_changes_target: "form",
               refresh_on_form_changes_turbo_stream_url_value: preview_dev_json_forms_playground_path,
               action: "code-editor:changed->refresh-on-form-changes#triggerTurboStream" }
      form_with(url: preview_dev_json_forms_playground_path, scope: :playground, data:) do |f|
        safe_join([code_editor(f, :schema, @schema_text, height: "40rem"),
                   code_editor(f, :ui_schema, @ui_schema_text, height: "24rem")])
      end
    end

    def code_editor(form, name, value, height:)
      docs_key, docs_url = DOCS.fetch(name)
      data = { controller: "code-editor", code_editor_mode_value: "json", code_editor_height_value: height }
      content_tag(:div, class: "FormControl width-full mb-3", data:) do
        safe_join([
                    form.label(name, t("json_forms.playground.#{name}"), class: "FormControl-label"),
                    form.text_area(name, value:, spellcheck: false, class: "width-full",
                                         data: { code_editor_target: "textarea" }),
                    render(Primer::Beta::Text.new(tag: :span, classes: "FormControl-caption")) do
                      render(Primer::Beta::Link.new(href: docs_url, target: "_blank", rel: "noopener noreferrer")) do
                        t("json_forms.docs.#{docs_key}")
                      end
                    end
                  ])
      end
    end
  end
end
