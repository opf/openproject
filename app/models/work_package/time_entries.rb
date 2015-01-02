#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module WorkPackage::TimeEntries
  extend ActiveSupport::Concern

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    protected

    def cleanup_time_entries_before_destruction_of(work_packages, user, to_do = { action: 'destroy' })
      return false unless to_do.present?

      case to_do[:action]
      when 'destroy'
        true
        # nothing to do
      when 'nullify'
        WorkPackage.update_time_entries(work_packages, 'work_package_id = NULL')
      when 'reassign'
        reassign_to = WorkPackage.includes(:project)
                      .where(Project.allowed_to_condition(user, :edit_time_entries))
                      .find_by_id(to_do[:reassign_to_id])

        if reassign_to.nil?
          Array(work_packages).each do |wp|
            wp.errors.add(:base, :is_not_a_valid_target_for_time_entries, id: to_do[:reassign_to_id])
          end

          false
        else
          WorkPackage.update_time_entries(work_packages, "work_package_id = #{reassign_to.id}, project_id = #{reassign_to.project_id}")
        end
      else
        false
      end
    end

    def update_time_entries(work_packages, action)
      TimeEntry.update_all(action, ['work_package_id IN (?)', work_packages])
    end
  end
end
