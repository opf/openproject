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

module CustomFields
  module ProjectSpecificValues
    class BaseContract < ::BaseContract
      include RequiresAdminGuard

      validate :validate_restriction_enabled
      validate :validate_enterprise_plan

      private

      def validate_restriction_enabled
        return if model.project_specific_value_restriction.present?

        errors.add :project_specific_value_restriction, :blank
      end

      def validate_enterprise_plan
        return if EnterpriseToken.allows_to?(:project_specific_list_values)

        errors.add :base, :error_enterprise_only, action: I18n.t("ee.features.project_specific_list_values")
      end
    end
  end
end
