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
  class PlaygroundFormComponent < ApplicationComponent
    include OpTurbo::Streamable

    EXAMPLE_SCHEMA = {
      "type" => "object",
      "required" => ["title"],
      "properties" => {
        "title" => { "type" => "string", "title" => "Title", "maxLength" => 40 },
        "priority" => { "type" => "string", "title" => "Priority", "enum" => %w[low normal high], "default" => "normal" },
        "due" => { "type" => "string", "title" => "Due date", "format" => "date" },
        "owner" => { "type" => "string", "title" => "Owner", "format" => "op-user" },
        "notify" => { "type" => "boolean", "title" => "Send a notification" },
        "contact" => {
          "type" => "object", "title" => "Contact",
          "properties" => { "name" => { "type" => "string", "title" => "Name" },
                            "email" => { "type" => "string", "title" => "Email", "format" => "email" } }
        },
        "tasks" => {
          "type" => "array", "title" => "Tasks", "maxItems" => 3,
          "items" => { "type" => "object", "required" => ["title"],
                       "properties" => { "title" => { "type" => "string", "title" => "Title" },
                                         "hours" => { "type" => "number", "title" => "Hours", "minimum" => 0 } } }
        }
      }
    }.freeze

    def initialize(schema:, ui_schema:, schema_text:, ui_schema_text:, values: nil, errors: {}, submitted: false,
                   state: {})
      super
      @schema = schema
      @ui_schema = ui_schema
      @schema_text = schema_text
      @ui_schema_text = ui_schema_text
      @values = values || FormData.apply_defaults(schema, {})
      @errors = errors
      @submitted = submitted
      @state = state
    end

    def call
      component_wrapper do
        safe_join([input_form, (result if @submitted)].compact)
      end
    end

    private

    def input_form
      form_arguments = InputForm.form_arguments(url: dev_json_forms_playground_path,
                                                refresh_url: refresh_dev_json_forms_playground_path)
      primer_form_with(**form_arguments) do |form|
        safe_join([
                    hidden_field_tag("playground[schema]", @schema_text),
                    hidden_field_tag("playground[ui_schema]", @ui_schema_text),
                    render(InputForm.new(form, schema: @schema, ui_schema: @ui_schema, data: @values, errors: @errors,
                                               state: @state,
                                               refresh_url: refresh_dev_json_forms_playground_path)),
                    render(Primer::Beta::Button.new(type: :submit, scheme: :primary, mt: 3,
                                                    test_selector: "json-forms-playground-submit")) do
                      t("json_forms.playground.submit")
                    end
                  ])
      end
    end

    def result
      render(Primer::Box.new(mt: 4, test_selector: "json-forms-playground-result")) do
        safe_join([
                    render(Primer::Beta::Heading.new(tag: :h3, mb: 2)) { t("json_forms.playground.result") },
                    content_tag(:pre, JSON.pretty_generate(@values), class: "color-bg-subtle p-3 rounded-2")
                  ])
      end
    end
  end
end
