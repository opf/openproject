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

module CustomFields
  module ProjectSpecificValues
    # The project the value came from keeps it, even when the values are allowed per project.
    class MakeGlobalService < ::BaseServices::BaseContracted
      def initialize(user:, model:, contract_class: MakeGlobalContract)
        super(user:, contract_class:)
        self.model = model
      end

      private

      def before_perform(service_call)
        self.contract_options = { value:, project: }

        service_call
      end

      def persist(service_call)
        value.update!(project_id: nil)
        model.touch
        return service_call unless model.project_specific_value_restriction_allow?

        service_call.merge!(SetService.new(user:, model:).call(project:, value:, enabled: true))
      end

      def value
        params[:value]
      end

      def project
        params[:project]
      end
    end
  end
end
