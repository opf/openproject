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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Wikis
  module Admin
    module SidePanel
      class HealthStatusComponent < ApplicationComponent
        include ApplicationHelper
        include OpTurbo::Streamable
        include OpPrimer::ComponentHelpers

        private

        def report
          model.health_reports.order(created_at: :asc).last
        end

        def summary_header
          tally = report.tally
          case tally
          in { failure: 1.. }
            {
              icon: :alert,
              icon_color: :danger,
              text: I18n.t("health_reports.common.checks.failures", count: tally[:failure])
            }
          in { warning: 1.. }
            {
              icon: :alert,
              icon_color: :attention,
              text: I18n.t("health_reports.common.checks.warnings", count: tally[:warning])
            }
          else
            { icon: :"check-circle", icon_color: :success, text: I18n.t("health_reports.common.checks.success") }
          end
        end

        def summary_description
          text = if report.healthy?
                   I18n.t("health_reports.common.summary.success")
                 elsif report.unhealthy?
                   I18n.t("health_reports.common.summary.failure")
                 else
                   I18n.t("health_reports.common.summary.warning")
                 end

          "#{text} #{t('.last_check', datetime: helpers.format_time(report.created_at))}"
        end
      end
    end
  end
end
