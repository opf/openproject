# --copyright
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
# ++

module API::V3::Values::Schemas
  module ValueSchemaFactory
    extend ::API::V3::Utilities::PathHelper
    SUPPORTED = %w(start_date due_date date).freeze

    module_function

    def for(property)
      return nil unless supported?(property)

      ::API::V3::Values::Schemas::PropertySchemaRepresenter
        .new(model_for(property),
             current_user: nil,
             self_link: api_v3_paths.value_schema(property.camelcase(:lower)))
    end

    def all_for(properties)
      properties.map { |property| self.for(property) }
    end

    def supported?(property)
      # This is but a stub. Currently, only 'start_date' and 'due_date'
      # need to be supported so this simple approach works.
      SUPPORTED.include?(property)
    end

    def model_for(property)
      API::V3::Values::Schemas::Model
        .new(i18n_for(property),
             type_for(property))
    end

    def i18n_for(property)
      # This is but a stub. Currently, only 'start_date' and 'due_date'
      # need to be supported so this simple approach works.
      I18n.t("attributes.#{property}")
    end

    def type_for(_property)
      # This is but a stub. Currently, only 'start_date' and 'due_date'
      # need to be supported so this simple approach works.
      "Date"
    end
  end
end
