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

        def render_formatted_value
          @project_custom_field_values&.map do |cf_value|
            format_value(cf_value.value, @project_custom_field)
          end&.join(", ")&.html_safe
        end

        def render_formatted_default_value
          if @project_custom_field.default_value.is_a?(Array)
            @project_custom_field.default_value.map do |default_value|
              format_value(default_value, @project_custom_field)
            end.join(", ").html_safe
          else
            format_value(@project_custom_field.default_value, @project_custom_field)
          end
        end

        def not_set?
          @project_custom_field_values.empty? || @project_custom_field_values.all? { |cf_value| cf_value.value.blank? }
        end
      end
    end
  end
end
