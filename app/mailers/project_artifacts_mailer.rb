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

class ProjectArtifactsMailer < ApplicationMailer
  include ProjectsHelper
  include Exports::PDF::Common::Macro

  def creation_wizard_submitted(user, project, artifact_work_package)
    @project = project
    @work_package = artifact_work_package
    @notification_text = apply_markdown_field_macros(project.project_creation_wizard_notification_text, { project:, user: })

    open_project_headers "Project" => project.identifier

    message_id project, user

    send_localized_mail(user) do
      I18n.t("settings.project_initiation_request.status.submitted",
             wizard_name: project_creation_wizard_name(project))
    end
  end
end
