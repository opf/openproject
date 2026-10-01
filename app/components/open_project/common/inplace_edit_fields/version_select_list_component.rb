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

module OpenProject
  module Common
    module InplaceEditFields
      class VersionSelectListComponent < SelectListComponent
        def initialize(form:, attribute:, model:, **system_arguments)
          super

          unless custom_field?
            assign_defaults!
          end
        end

        private

        def render_custom_field_input
          input_class = if custom_field.multi_value?
                          CustomFields::Inputs::MultiVersionSelectList
                        else
                          CustomFields::Inputs::SingleVersionSelectList
                        end

          # Use fields_for to create the proper context for custom field inputs
          form.fields_for(:custom_field_values) do |builder|
            input_class.new(builder, custom_field:, object: model, **@system_arguments[:autocomplete_options])
          end
        end

        def render_autocompleter
          form.autocompleter(name: attribute, **@system_arguments) do |list|
            model.assignable_versions.each do |version|
              list.option(
                label: version.name,
                value: version.id,
                selected: version.id == model.version&.id
              )
            end
          end
        end

        def assign_defaults!
          version = model.version
          @system_arguments[:autocomplete_options][:inputValue] = version&.id
          @system_arguments[:autocomplete_options][:model] = version_model
          @system_arguments[:autocomplete_options][:decorated] = true
          @system_arguments[:autocomplete_options][:closeOnSelect] = true
          # Override inputName to use Rails form builder naming convention
          @system_arguments[:autocomplete_options][:inputName] = input_name
        end

        def version_model
          version ? { id: version.id, name: version.name } : nil
        end

        def input_name
          "#{model.class.model_name.param_key}[#{attribute}]"
        end
      end
    end
  end
end
