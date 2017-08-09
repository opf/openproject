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

class SetAttributesWorkPackageService
  include Concerns::Contracted

  attr_accessor :user,
                :work_package,
                :contract

  def initialize(user:, work_package:, contract:)
    self.user = user
    self.work_package = work_package

    self.contract = contract.new(work_package, user)
  end

  def call(attributes)
    set_attributes(attributes)

    validate_and_result
  end

  private

  def validate_and_result
    boolean, errors = validate(work_package)

    ServiceResult.new(success: boolean,
                      errors: errors)
  end

  def set_attributes(attributes)
    work_package.attributes = attributes

    unify_dates if work_package_now_milestone?

    # Take over any default custom values
    # for new custom fields
    work_package.set_default_values! if custom_field_context_changed?

    reschedule(attributes)
  end

  def reschedule(attributes)
    ScheduleWorkPackageService
      .new(user: user, work_package: work_package)
      .call(attributes: attributes)
  end

  def unify_dates
    unified_date = work_package.due_date || work_package.start_date
    work_package.start_date = work_package.due_date = unified_date
  end

  def custom_field_context_changed?
    work_package.type_id_changed? || work_package.project_id_changed?
  end

  def work_package_now_milestone?
    work_package.type_id_changed? && work_package.milestone?
  end
end
