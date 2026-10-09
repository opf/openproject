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
module Projects
  module Wizard
    class CustomFieldsForm < ApplicationForm
      include ::CustomFields::CustomFieldRendering

      form do |custom_fields_form|
        # This placeholder is relevant in cases where no custom fields are rendered at all or all
        # custom fields rendered are disabled. Without it, the form might be completely empty and
        # the controller would complain about a missing parameter namespace expected by the ActionController::Parameters.
        custom_fields_form.hidden(name: "_placeholder", value: "")

        render_custom_fields(form: custom_fields_form)
      end

      def initialize(project:, custom_fields:)
        super()

        @project = project
        @custom_fields = custom_fields
      end

      def model
        @project
      end

      def additional_custom_field_input_arguments
        {
          model: @project,
          wrapper_data_attributes: ->(custom_field) {
            { custom_field_id: custom_field.id }
          }
        }
      end

      private

      attr_reader :custom_fields
    end
  end
end
