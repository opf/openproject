#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Projects
  class DeleteService < ::BaseServices::Delete
    prepend Projects::Concerns::UpdateDemoData

    ##
    # Reference to the dependent projects that we're deleting
    attr_accessor :dependent_projects

    def initialize(user:, model:, contract_class: nil, contract_options: {})
      self.dependent_projects = model.descendants.to_a # Store an Array instead of a Project::ActiveRecord_Relation

      super
    end

    def call(*)
      super.tap do |service_call|
        notify(service_call.success?)
      end
    end

    private

    def before_perform(*)
      OpenProject::Notifications.send(:project_deletion_imminent, project: @project_to_destroy)

      delete_all_members
      destroy_all_work_packages
      destroy_all_storages

      super
    end

    # Deletes all project's members
    def delete_all_members
      MemberRole
        .includes(:member)
        .where(members: { project_id: model.id })
        .delete_all

      Member.where(project_id: model.id).destroy_all
    end

    def destroy_all_work_packages
      model.work_packages.each do |wp|
        wp.reload
        wp.destroy
      rescue ActiveRecord::RecordNotFound
        # Everything fine, we wanted to delete it anyway
      end
    end

    def destroy_all_storages
      model.project_storages.map do |project_storage|
        Storages::ProjectStorages::DeleteService.new(user:, model: project_storage).call
      end
    end

    def notify(success)
      if success
        ProjectMailer.delete_project_completed(model, user:, dependent_projects:).deliver_now
      else
        ProjectMailer.delete_project_failed(model, user:).deliver_now
      end
    end
  end
end
