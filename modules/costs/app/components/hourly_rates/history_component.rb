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

module HourlyRates
  class HistoryComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    options :principal

    private

    def rate_history
      @rate_history ||= ::HourlyRate.history_for_user(principal)
    end

    def default_rates
      rate_history[nil] || []
    end

    def project_rates
      @project_rates ||= rate_history.except(nil)
    end

    def current_default_rate
      @current_default_rate ||= principal.current_default_rate
    end

    def current_rate_for(project)
      helpers.at_date_in_project_with_ancestors(Time.zone.today, project_rates, project)
    end

    def default_caption
      rate_caption(Rate.human_attribute_name(:current_rate), current_default_rate)
    end

    # Without a rate of its own a project bills at the default rate, so the
    # caption names which of the two is in effect.
    def project_caption(project)
      rate = current_rate_for(project)
      return rate_caption(Rate.human_attribute_name(:current_rate), rate) if rate

      rate_caption(t(:label_current_default_rate), current_default_rate)
    end

    def rate_caption(label, rate)
      return if rate.nil?

      "#{label}: #{helpers.number_to_currency(rate.rate)}"
    end

    def new_default_rate_url
      return unless DefaultHourlyRates::BaseContract.can_manage?(user: User.current)

      helpers.new_default_hourly_rate_path(principal_id: principal.id)
    end

    def new_project_rate_url(project)
      return unless HourlyRates::BaseContract.can_manage?(user: User.current, principal_id: principal.id, project:)

      helpers.new_projects_hourly_rate_path(project_id: project, principal_id: principal.id)
    end
  end
end
