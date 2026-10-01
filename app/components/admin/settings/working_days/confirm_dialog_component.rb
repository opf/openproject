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

module Admin
  module Settings
    module WorkingDays
      class ConfirmDialogComponent < ApplicationComponent
        include OpTurbo::Streamable

        DIALOG_ID = "working-days-change-dialog"

        attr_reader :form_values, :removed_non_working_days

        def initialize(form_values: {}, removed_non_working_days: [])
          super
          @form_values = form_values
          @removed_non_working_days = removed_non_working_days
        end

        private

        def form_arguments
          {
            action: helpers.admin_settings_working_days_and_hours_path,
            method: :patch,
            data: { turbo: false }
          }
        end

        def hidden_settings_fields
          hidden_field_tags_for("settings", form_values)
        end

        def hidden_field_tags_for(name, value)
          case value
          when Hash
            safe_join(
              value.flat_map do |key, nested_value|
                hidden_field_tags_for("#{name}[#{key}]", nested_value)
              end
            )
          when Array
            safe_join(value.map { |array_value| hidden_field_tag("#{name}[]", array_value) })
          else
            hidden_field_tag(name, value)
          end
        end
      end
    end
  end
end
