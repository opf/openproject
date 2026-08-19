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

module HealthReports
  class ReportComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    alias report model

    # The i18n_scope parameter defines the I18n scope that should be used to resolve
    # names of groups, checks and error messages indicated by the results.
    def initialize(*, i18n_scope:, **)
      super(*, **)
      @i18n_scope = i18n_scope
    end

    private

    attr_reader :i18n_scope

    def summary_icon(check_tally)
      case check_tally
      in { failure: 1.. }
        { icon: :alert, color: :danger }
      in { warning: 1.. }
        { icon: :alert, color: :attention }
      else
        { icon: :"check-circle", color: :success }
      end
    end

    def humanize_summary(check_tally)
      case check_tally
      in { failure: 1.. }
        I18n.t("health_reports.common.checks.failures", count: check_tally[:failure])
      in { warning: 1.. }
        I18n.t("health_reports.common.checks.warnings", count: check_tally[:warning])
      else
        I18n.t("health_reports.common.checks.success")
      end
    end
  end
end
