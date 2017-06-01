#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

# Currently this is only a stub.
# The intend for this service is for it to include all the vast scheduling rules that make up the work package scheduling.

class ScheduleWorkPackageService
  include Concerns::Contracted

  attr_accessor :user, :work_package

  self.contract = WorkPackages::UpdateContract

  def initialize(user:, work_package:)
    self.user = user
    self.work_package = work_package

    self.contract = self.class.contract.new(work_package, user)
  end

  def call(attributes: {})
    update(attributes)
  end

  private

  def update(attributes)
    set_dates_on_parent_updates unless attributes[:start_date]
  end

  def set_dates_on_parent_updates
    return unless date_before_newly_added_parents_soonest_start?

    new_start_date = work_package.parent.soonest_start

    current_duration = work_package.duration

    work_package.start_date = new_start_date
    work_package.due_date = new_start_date + current_duration
  end

  def date_before_newly_added_parents_soonest_start?
    work_package.parent_id_changed? &&
      work_package.parent &&
      date_before_soonest_start?(work_package.parent)
  end

  def date_before_soonest_start?(other_work_package)
    other_work_package.soonest_start &&
      (!work_package.start_date ||
      work_package.start_date < other_work_package.soonest_start)
  end
end
