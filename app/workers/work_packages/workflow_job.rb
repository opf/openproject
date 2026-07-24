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

module WorkPackages
  class WorkflowJob < ApplicationJob
    def perform(journal, changes)
      work_package = journal.journable
      return if journal.initial?

      services = applicable_services(work_package, changes)
      return if services.empty?

      # The job runs with a clean request store, so User.current would be
      # Anonymous here. Act as the user who caused the journalized change so the
      # generated artefacts (attachment and its journal entry) are attributed to them.
      User.execute_as(journal.user) do
        services.each do |service|
          service.new(current_user: journal.user, work_package:).call!(changes:)
        end
      end
    end

    private

    def applicable_services(work_package, changes)
      [
        Projects::CreationWizard::ReuploadArtifactOnStatusChangesService,
        WorkPackages::TypeArtefactExport::ExportOnStatusChangeService
      ].select { |service| service.applicable?(work_package:, changes:) }
    end
  end
end
