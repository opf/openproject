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

module WorkPackage::TimeEntriesCleaner
  extend ActiveSupport::Concern

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    protected

    def cleanup_time_entries_before_destruction_of(work_packages,
                                                   user,
                                                   to_do = { action: "destroy" })
      return false unless to_do.present?

      case to_do[:action]
      when "destroy"
        true
        # nothing to do
      when "nullify"
        work_packages = Array(work_packages)
        WorkPackage.update_time_entries(work_packages, "work_package_id = NULL")
      when "reassign"
        reassign_time_entries_before_destruction_of(work_packages, user, to_do[:reassign_to_id])
      else
        false
      end
    end

    def update_time_entries(work_packages, action)
      TimeEntry.where(["work_package_id IN (?)", work_packages.map(&:id)]).update_all(action)
    end

    def reassign_time_entries_before_destruction_of(work_packages, user, ids)
      work_packages = Array(work_packages)
      reassign_to = WorkPackage
                    .joins(:project)
                    .merge(Project.allowed_to(user, :edit_time_entries))
                    .find_by(id: ids)

      if reassign_to.nil?
        work_packages.each do |wp|
          wp.errors.add(:base, :is_not_a_valid_target_for_time_entries, id: ids)
        end

        false
      else
        condition = "work_package_id = #{reassign_to.id}, project_id = #{reassign_to.project_id}"
        WorkPackage.update_time_entries(work_packages, condition)
      end
    end
  end
end
