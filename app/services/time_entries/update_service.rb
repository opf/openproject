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

class TimeEntries::UpdateService
  attr_accessor :user, :time_entry

  def initialize(user:, time_entry:)
    self.user = user
    self.time_entry = time_entry
  end

  def call(attributes: {})
    set_attributes attributes

    success = validate_and_save
    ServiceResult.new success: success, errors: time_entry.errors, result: time_entry
  end

  private

  def set_attributes(attributes)
    time_entry.attributes = attributes

    ##
    # Update project context if moving time entry
    if time_entry.work_package_id_changed?
      time_entry.project_id = time_entry.work_package.project_id
    end
  end

  def validate_and_save
    ##
    # Perform additional validations on the model,
    # since the errors from reform are not merged into the model for form errors
    validate_visible_work_package

    if time_entry.errors.empty?
      time_entry.save
    else
      false
    end
  end

  def validate_visible_work_package
    if time_entry.work_package
      time_entry.errors.add :work_package_id, :invalid unless time_entry.work_package.visible?(user)
    end
  end
end
