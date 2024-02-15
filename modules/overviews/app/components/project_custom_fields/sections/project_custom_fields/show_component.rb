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

module ProjectCustomFields
  module Sections
    module ProjectCustomFields
      class ShowComponent < ApplicationComponent
        include ApplicationHelper
        include CustomFieldsHelper
        include OpPrimer::ComponentHelpers

        def initialize(project_custom_field:, project_custom_field_values:)
          super

          @project_custom_field = project_custom_field
          @project_custom_field_values = project_custom_field_values
        end

        private

        def render_value
          if @project_custom_field.field_format == "text"
            render_rich_text
          else
            render(Primer::Beta::Text.new) do
              @project_custom_field_values&.map do |cf_value|
                format_value(cf_value.value, @project_custom_field)
              end&.join(", ")&.html_safe
            end
          end
        end

        def render_rich_text
          truncation_length = 100

          if @project_custom_field_values.first&.value&.length.to_i > truncation_length
            render_truncated_preview_and_dialog_for_rich_text_value(truncation_length)
          else
            render(Primer::Beta::Text.new) do
              format_value(@project_custom_field_values.first&.value, @project_custom_field)
            end
          end
        end

        def render_truncated_preview_and_dialog_for_rich_text_value(truncation_length)
          flex_layout do |rich_text_preview_container|
            rich_text_preview_container.with_row do
              render(Primer::Beta::Text.new) do
                format_value(@project_custom_field_values.first&.value&.truncate(truncation_length), @project_custom_field)
              end
            end
            rich_text_preview_container.with_row do
              render(Primer::Alpha::Dialog.new(size: :medium_portrait, title: @project_custom_field.name)) do |d|
                d.with_show_button(scheme: :link) { "Expand" }
                d.with_body(style: "max-height: 500px;") do
                  format_value(@project_custom_field_values.first&.value, @project_custom_field)
                end
              end
            end
          end
        end

        def not_set?
          @project_custom_field_values.empty? || @project_custom_field_values.all? { |cf_value| cf_value.value.blank? }
        end
      end
    end
  end
end
