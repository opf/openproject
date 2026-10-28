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

module SquashTMIntegration
  module WorkPackageTab
    class RequirementComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      alias_method :tab_state, :model

      delegate :server, :work_package_link, :requirement, to: :tab_state

      def requirement_id
        work_package_link.squashtm_requirement_id_in_database
      end

      def name
        requirement&.name || work_package_link.squashtm_requirement_name_in_database
      end

      def url
        server.requirement_url(requirement_id)
      end

      def status_label
        I18n.t(requirement.status.to_s.downcase,
               scope: "squashtm_integration.requirement_statuses",
               default: requirement.status.to_s.humanize)
      end
    end
  end
end
