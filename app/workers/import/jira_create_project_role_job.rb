# frozen_string_literal: true

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

module Import
  class JiraCreateProjectRoleJob < ApplicationJob
    include Import::JiraOpenProjectReferenceCreation

    def text
      "Create 'JiraMember' project role"
    end

    def perform(jira_import_id)
      jira_import = Import::JiraImport.find(jira_import_id)
      service_call = Roles::CreateService.new(user: User.system).call(
        name: "JiraMember",
        permissions: %i[add_work_packages
                        view_work_packages
                        add_work_package_comments
                        add_work_package_attachments
                        work_package_assigned]
      )
      if service_call.success?
        create_reference!(op_leg: service_call.result,
                          jira_leg: nil,
                          jira_import:,
                          uses_existing: false)
      elsif service_call.errors.find { |error| error.type == :taken }.blank?
        raise service_call.message
      end
    end
  end
end
