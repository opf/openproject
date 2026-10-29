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
    class ExecutionStatusComponent < ApplicationComponent
      Appearance = Data.define(:scheme, :icon)

      NOT_EXECUTED = Appearance.new(scheme: :secondary, icon: :dash)

      APPEARANCES = {
        "SUCCESS" => Appearance.new(scheme: :success, icon: :"check-circle"),
        "SETTLED" => Appearance.new(scheme: :success, icon: :check),
        "FAILURE" => Appearance.new(scheme: :danger, icon: :"x-circle"),
        "ERROR" => Appearance.new(scheme: :danger, icon: :stop),
        "BLOCKED" => Appearance.new(scheme: :attention, icon: :blocked),
        "WARNING" => Appearance.new(scheme: :attention, icon: :alert),
        "RUNNING" => Appearance.new(scheme: :accent, icon: :sync),
        "READY" => Appearance.new(scheme: :secondary, icon: :circle),
        "UNTESTABLE" => Appearance.new(scheme: :secondary, icon: :skip),
        "SKIPPED" => Appearance.new(scheme: :secondary, icon: :skip),
        "CANCELLED" => Appearance.new(scheme: :secondary, icon: :x),
        "NOT_RUN" => NOT_EXECUTED,
        "NOT_FOUND" => Appearance.new(scheme: :secondary, icon: :question)
      }.freeze

      alias_method :test_case, :model

      def appearance
        return NOT_EXECUTED unless test_case.executed?

        APPEARANCES.fetch(test_case.execution_status, Appearance.new(scheme: :secondary, icon: :circle))
      end

      def label
        return t(".not_executed") unless test_case.executed?

        I18n.t(test_case.execution_status.to_s.downcase,
               scope: "squashtm_integration.execution_statuses",
               default: test_case.execution_status.to_s.humanize)
      end
    end
  end
end
