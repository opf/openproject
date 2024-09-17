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

module ProjectCustomFields
  module Sections
    class ShowComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def initialize(project:, project_custom_field_section:, project_custom_fields:)
        super

        @project = project
        @project_custom_field_section = project_custom_field_section
        @project_custom_fields = project_custom_fields

        eager_load_project_custom_field_values
      end

      private

      def allowed_to_edit?
        User.current.allowed_in_project?(:edit_project_attributes, @project)
      end

      def eager_load_project_custom_field_values
        # TODO: move to service
        @eager_loaded_project_custom_field_values = CustomValue
          .includes(custom_field: :custom_options)
          .where(
            custom_field_id: @project_custom_fields.pluck(:id),
            customized_id: @project.id
          )
        .to_a
      end

      def get_eager_loaded_project_custom_field_values_for(custom_field_id)
        @eager_loaded_project_custom_field_values.select { |pcfv| pcfv.custom_field_id == custom_field_id }
      end
    end
  end
end
