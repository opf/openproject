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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::Bim::Patches::WorkPackageSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
    base.attribute_names_for_required_references << "bcf_issue"
  end

  module InstanceMethods
    def create_or_update_work_package(attributes)
      uuid = attributes["bcf_issue_uuid"]
      if uuid
        time_tracking_attributes = time_tracking_attributes(attributes)

        work_package = find_bcf_issue(uuid)
        work_package.update_columns(created_at: Time.current,
                                    author_id: admin_user.id,
                                    assigned_to_id: find_principal(attributes["assigned_to"]).id,
                                    start_date: time_tracking_attributes[:start_date],
                                    due_date: time_tracking_attributes[:due_date],
                                    duration: time_tracking_attributes[:duration],
                                    ignore_non_working_days: time_tracking_attributes[:ignore_non_working_days])

        update_parent(work_package, attributes)
      else
        create_work_package(attributes)
      end
    end

    def update_parent(work_package, attributes)
      return unless attributes["parent"]

      parent = find_work_package(attributes["parent"])
      return if parent.nil?

      work_package.parent = parent
      work_package.save!
    end

    def find_bcf_issue(uuid)
      WorkPackage
        .joins(:bcf_issue)
        .where(project_id: project.id, "bcf_issues.uuid": uuid)
        .references(:bcf_issue).first
    end
  end
end
