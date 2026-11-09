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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Projects::CreationWizardStatusComponent < ApplicationComponent
  include ApplicationHelper
  include ProjectsHelper

  attr_reader :project, :current_user,
              :artefact_id, :artefact_work_package

  def initialize(project:, current_user: User.current)
    super

    @project = project
    @current_user = current_user
    @artefact_id = project.project_creation_wizard_artifact_work_package_id.presence
    @artefact_work_package = find_artefact if artefact_id.present?
  end

  def before_render
    @status_text = set_status_text
    @status_explanation = set_status_explanation
  end

  def render?
    return false unless project.project_creation_wizard_enabled

    if artefact_id
      current_user.allowed_in_project?(:view_work_packages, project)
    else
      current_user.allowed_in_project?(:edit_project_attributes, project)
    end
  end

  private

  def set_status_text
    if artefact_id
      t("settings.project_initiation_request.status.submitted",
        wizard_name: project_creation_wizard_name(project))
    else
      t("settings.project_initiation_request.status.not_completed",
        wizard_name: project_creation_wizard_name(project))
    end
  end

  def set_status_explanation
    if artefact_work_package
      t("settings.project_initiation_request.status.submitted_description")
    elsif !artefact_id
      t("settings.project_initiation_request.status.not_completed_description")
    end
  end

  def find_artefact
    WorkPackage.visible.find_by(id: artefact_id)
  end
end
