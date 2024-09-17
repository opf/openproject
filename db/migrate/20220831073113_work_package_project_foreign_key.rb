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

class WorkPackageProjectForeignKey < ActiveRecord::Migration[7.0]
  # Note: rails 7.1 breaks the class' ancestor chain, and raises an error, when a class
  # with an enum definition without a database field is being referenced.
  # Re-defining the Project class without the enum to avoid the issue.
  class Project < ApplicationRecord; end

  def change
    reversible do |dir|
      dir.up do
        cleanup_invalid_work_packages
      end
    end

    add_foreign_key :work_packages, :projects
  end

  private

  def cleanup_invalid_work_packages
    WorkPackage
      .where.not(project_id: Project.select(:id))
      .find_each do |work_package|
      WorkPackages::DeleteService
        .new(user: User.system, model: work_package)
        .call
        .on_success { Rails.logger.info "Deleted stale work package #{work_package.inspect}" }
        .on_failure { Rails.logger.error "Failed to delete stale work package #{work_package.inspect}" }
    rescue ::ActiveRecord::RecordNotFound
      # raised by #reload if work package no longer exists
      # nothing to do, work package was already deleted (eg. by a parent)
    end
  end
end
