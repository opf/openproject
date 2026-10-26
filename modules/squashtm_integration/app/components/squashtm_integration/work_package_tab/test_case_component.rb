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
    class TestCaseComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers

      alias_method :test_case, :model

      def initialize(test_case, server:)
        super(test_case)
        @server = server
      end

      def url
        @server.test_case_url(test_case.id)
      end

      def description
        helpers.sanitize(test_case.description)
      end

      def execution_details
        return t(".not_executed") unless test_case.executed?

        t(".last_execution", user: test_case.last_executed_by, date_time: format_time(test_case.last_executed_on))
      end
    end
  end
end
