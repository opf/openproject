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

module Rates
  class UpdateHistoryService < ::BaseServices::BaseCallable
    def initialize(user:, principal:, project: nil)
      super()

      @user = user
      @principal = principal
      @project = project
    end

    protected

    attr_reader :user, :principal, :project

    def perform(*)
      result = ServiceResult.success(result: principal)

      ActiveRecord::Base.transaction do
        persisted_rates.each { |rate| result.add_dependent!(update_or_delete(rate)) }
        added_rates.each_value { |attributes| result.add_dependent!(create(attributes)) }

        raise ActiveRecord::Rollback if result.failure?
      end

      result
    end

    private

    # Queried off the rate classes rather than through the principal's
    # associations, so that calling the service does not leave the caller
    # holding a stale, already loaded collection.
    def persisted_rates
      if project
        ::HourlyRate.for_principal(principal).in_project(project).to_a
      else
        ::DefaultHourlyRate.for_principal(principal).to_a
      end
    end

    def added_rates
      params[:new_rate_attributes] || {}
    end

    def changed_rates
      (params[:existing_rate_attributes] || {}).stringify_keys
    end

    # A row the form no longer submits has been removed by the user, so the rate
    # goes with it.
    def update_or_delete(rate)
      attributes = changed_rates[rate.id.to_s]

      if attributes && attributes[:rate].present?
        services::UpdateService.new(user:, model: rate).call(attributes)
      else
        services::DeleteService.new(user:, model: rate).call
      end
    end

    def create(attributes)
      services::CreateService
        .new(user:)
        .call(attributes.merge(user_id: principal.id, project_id: project&.id))
    end

    def services
      project ? HourlyRates : DefaultHourlyRates
    end
  end
end
