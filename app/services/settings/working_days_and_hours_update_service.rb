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

class Settings::WorkingDaysAndHoursUpdateService < Settings::UpdateService
  def call(params)
    params = params.to_h.deep_symbolize_keys
    self.non_working_days_params = params.delete(:non_working_days) || []
    self.previous_working_days = Setting[:working_days]
    self.previous_non_working_days = NonWorkingDay.pluck(:date)
    super
  end

  def validate_params(params)
    contract = Settings::WorkingDaysAndHoursParamsContract.new(model, user, params:)
    ServiceResult.new success: contract.valid?,
                      errors: contract.errors,
                      result: model
  end

  def persist(call)
    results = call
    ActiveRecord::Base.transaction do
      # The order of merging the service is important to preserve
      # the errors model's base object, which is a NonWorkingDay
      results = persist_non_working_days
      results.merge!(super) if results.success?

      raise ActiveRecord::Rollback if results.failure?
    end

    results
  end

  def after_perform(call)
    super.tap do
      WorkPackages::ApplyWorkingDaysChangeJob.perform_later(
        user_id: User.current.id,
        previous_working_days:,
        previous_non_working_days:
      )
    end
  end

  private

  attr_accessor :non_working_days_params, :previous_working_days, :previous_non_working_days

  def persist_non_working_days
    # We don't support update for now
    to_create, to_delete = attributes_to_create_and_delete
    results = destroy_records(to_delete)
    create_results = create_records(to_create)
    results.merge!(create_results)
    results.result = Array(results.result) + Array(create_results.result)
    results
  end

  def attributes_to_create_and_delete
    non_working_days_params.reduce([[], []]) do |results, nwd|
      results.first << nwd if !nwd[:id]
      results.last << nwd[:id] if nwd[:_destroy] && nwd[:id]
      results
    end
  end

  def create_records(attributes)
    wrap_result(attributes.map { |attrs| NonWorkingDay.create(attrs) })
  end

  def destroy_records(ids)
    records = NonWorkingDay.where(id: ids)
    # In case the transaction fails we also mark the records for destruction,
    # this way we can display them correctly on the frontend.
    records.each(&:mark_for_destruction)
    wrap_result records.destroy_all
  end

  def wrap_result(result)
    model = NonWorkingDay.new
    errors = model.errors.tap do |err|
      result.each do |r|
        err.merge!(r.errors)
      end
    end
    success = model.errors.empty?

    ServiceResult.new(success:, errors:, result:)
  end
end
