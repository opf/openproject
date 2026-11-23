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
  # Development-only page to try out JSON Schemas and UI schemas with JsonForms::InputForm.
  class PlaygroundController < ::ApplicationController
    include OpTurbo::ComponentStream
    include SubmittedInput

    before_action :require_development
    before_action :require_admin
    before_action :load_schemas

    def show
      render locals: { component: PlaygroundComponent.new(schema_text: @schema_text, ui_schema_text: @ui_schema_text,
                                                          errors: errors_component,
                                                          form: problems.empty? ? form_component : empty_form_component) }
    end

    # Renders the form for the schemas in the editors, with their defaults.
    # While the schemas are invalid, only the errors are shown and the last valid form stays.
    def preview
      update_via_turbo_stream(component: errors_component)
      update_via_turbo_stream(component: form_component, method: :morph) if problems.empty?
      respond_with_turbo_streams
    end

    def refresh
      values = json_forms_refreshed_input(@schema)
      update_via_turbo_stream(component: form_component(values:, errors: json_forms_refresh_errors, state: json_forms_state),
                              method: :morph)
      respond_with_turbo_streams
    end

    def create
      input = json_forms_input(@schema)
      errors = Schema.new(@schema).validate(input)
      update_via_turbo_stream(component: form_component(values: input, errors:, submitted: errors.empty?,
                                                        state: json_forms_state),
                              status: errors.empty? ? :ok : :unprocessable_entity)
      respond_with_turbo_streams
    end

    private

    def require_development
      head :not_found unless Rails.env.development?
    end

    def load_schemas
      @schema_text = params.dig(:playground, :schema).presence || JSON.pretty_generate(PlaygroundFormComponent::EXAMPLE_SCHEMA)
      @ui_schema_text = params.dig(:playground, :ui_schema).presence || ""
      @schema = parse(@schema_text) || {}
      @ui_schema = parse(@ui_schema_text)
    end

    def parse(text)
      text.present? ? JSON.parse(text) : nil
    rescue JSON::ParserError => e
      (@parse_errors ||= []) << e.message
      nil
    end

    def problems
      @problems ||= (@parse_errors || []) + Schema.new(@schema).errors
    end

    def errors_component
      PlaygroundErrorsComponent.new(problems:)
    end

    def empty_form_component
      PlaygroundFormComponent.new(schema: Schema::EMPTY, ui_schema: nil, schema_text: "", ui_schema_text: "")
    end

    def form_component(**)
      PlaygroundFormComponent.new(schema: @schema, ui_schema: @ui_schema, schema_text: @schema_text,
                                  ui_schema_text: @ui_schema_text, **)
    end
  end
end
