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

      UNKNOWN = Appearance.new(scheme: :secondary, icon: :circle)

      APPEARANCES = {
        success: Appearance.new(scheme: :success, icon: :"check-circle"),
        settled: Appearance.new(scheme: :success, icon: :check),
        failure: Appearance.new(scheme: :danger, icon: :"x-circle"),
        error: Appearance.new(scheme: :danger, icon: :stop),
        blocked: Appearance.new(scheme: :attention, icon: :blocked),
        warning: Appearance.new(scheme: :attention, icon: :alert),
        running: Appearance.new(scheme: :accent, icon: :sync),
        ready: Appearance.new(scheme: :secondary, icon: :circle),
        untestable: Appearance.new(scheme: :secondary, icon: :skip),
        skipped: Appearance.new(scheme: :secondary, icon: :skip),
        cancelled: Appearance.new(scheme: :secondary, icon: :x),
        not_run: Appearance.new(scheme: :secondary, icon: :dash),
        not_executed: Appearance.new(scheme: :secondary, icon: :dash),
        not_found: Appearance.new(scheme: :secondary, icon: :question)
      }.freeze

      alias_method :test_case, :model

      def appearance
        APPEARANCES.fetch(execution_status, UNKNOWN)
      end

      def label
        I18n.t(execution_status,
               scope: "squashtm_integration.execution_statuses",
               default: execution_status.to_s.humanize)
      end

      private

      def execution_status
        return :not_executed unless test_case.executed?

        test_case.execution_status.to_s.downcase.to_sym
      end
    end
  end
end
