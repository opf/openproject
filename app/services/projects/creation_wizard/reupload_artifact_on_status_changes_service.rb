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

module Projects::CreationWizard
  class ReuploadArtifactOnStatusChangesService
    prepend Projects::Concerns::UpdateDemoData

    attr_reader :current_user, :artifact_work_package

    delegate :project, to: :artifact_work_package

    def initialize(current_user:, work_package:)
      @current_user = current_user
      @artifact_work_package = work_package
    end

    def call!(changes:)
      return if changes["status_id"].blank?
      return unless update_is_artifact_work_package?

      User.execute_as_admin(current_user) do
        update_artifact
      end
    end

    def update_is_artifact_work_package?
      project.project_creation_wizard_artifact_work_package_id.to_s == artifact_work_package.id.to_s
    end

    private

    def update_artifact
      call = UploadArtifactService
        .new(user: current_user, project:, work_package: artifact_work_package)
        .call

      if call.success?
        Rails.logger.debug { "Updated artifact for creation wizard in ##{artifact_work_package.id}" }
      else
        Rails.logger.error("Failed to process artifact change for ##{artifact_work_package.id}: ##{call.message}")
      end
    end
  end
end
