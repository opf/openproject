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

module Projects
  class ArchiveService < ::BaseServices::BaseContracted
    include Contracted
    prepend Projects::Concerns::UpdateDemoData

    def initialize(user:, model:, contract_class: Projects::ArchiveContract)
      super(user:, contract_class:)
      self.model = model
    end

    private

    def persist(service_call)
      archive_project(model) and model.active_subprojects.each do |subproject|
        archive_project(subproject)
      end

      service_call
    end

    def after_perform(service_call)
      OpenProject::Notifications.send(OpenProject::Events::PROJECT_ARCHIVED, project: model)
      service_call
    end

    def archive_project(project)
      # We do not care for validations but want the timestamps to be updated
      project.update_attribute(:active, false)
    end
  end
end
