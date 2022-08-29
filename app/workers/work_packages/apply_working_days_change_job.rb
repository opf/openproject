#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

class WorkPackages::ApplyWorkingDaysChangeJob < ApplicationJob
  queue_with_priority :above_normal

  def perform(user_id:)
    user = User.find(user_id)

    WorkPackage
      .where(ignore_non_working_days: false)
      .find_each do |work_package|
        next if dates_and_duration_match?(work_package)

        WorkPackages::SetAttributesService
          .new(user:, model: work_package, contract_class: EmptyContract)
          .call(duration: work_package.duration)
        work_package.save
      end
  end

  private

  def dates_and_duration_match?(work_package)
    days.working?(work_package.start_date) \
      && days.working?(work_package.due_date) \
      && days.duration(work_package.start_date, work_package.due_date) == work_package.duration
  end

  def days
    @days ||= WorkPackages::Shared::WorkingDays.new
  end
end
