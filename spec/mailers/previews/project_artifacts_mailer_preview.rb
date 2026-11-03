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

class ProjectArtifactsMailerPreview < ActionMailer::Preview
  # Preview emails at http://localhost:3000/rails/mailers/project_artifacts_mailer

  def creation_wizard_submitted
    project = FactoryBot.build_stubbed(:project)
    work_package = FactoryBot.build_stubbed(:work_package, project: project)
    project.project_creation_wizard_enabled = true
    project.project_creation_wizard_notification_text = <<~STR
      Hello,

      You submitted a project initiation request for **#{project.name}**. It is now awaiting review.
      Click the link below to access the work package with your request.
    STR
    user = FactoryBot.build_stubbed(:user)

    ProjectArtifactsMailer.creation_wizard_submitted(user, project, work_package)
  end
end
