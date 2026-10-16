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

module Bim
  module IfcModels
    class IfcConversionJob < ::ApplicationJob
      queue_as :ifc_conversion

      ##
      # Run the conversion of IFC to
      def perform(ifc_model)
        User.system.run_given do
          result = ViewConverterService.new(ifc_model).call

          unless result.success?
            errors = result.errors.full_messages.join(". ")
            Rails.logger.error "Failed to convert IFC model #{ifc_model.inspect}: #{errors}"
          end
        end
      end
    end
  end
end
