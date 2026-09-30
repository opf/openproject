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

class ProjectMailer < ApplicationMailer
  include Exports::PDF::Common::Macro

  def delete_project_completed(project, user:, dependent_projects: [])
    open_project_headers Project: project.identifier,
                         Author: user.login

    message_id project, user
    @project = project
    @dependent_projects = dependent_projects

    send_localized_mail(user) do
      I18n.t("projects.delete.completed", name: project.name)
    end
  end

  def delete_project_failed(project, user:)
    open_project_headers Project: project.identifier,
                         Author: user.login

    message_id project, user
    @project = project

    send_localized_mail(user) do
      I18n.t("projects.delete.failed", name: project.name)
    end
  end

  def copy_project_failed(user, source_project, target_project_name, errors)
    @source_project = source_project
    @target_project_name = target_project_name
    @errors = errors

    open_project_headers "Source-Project" => source_project.identifier,
                         "Author" => user.login

    message_id source_project, user

    send_localized_mail(user) do
      I18n.t("copy_project.failed", source_project_name: source_project.name)
    end
  end

  def copy_project_succeeded(user, source_project, target_project, errors)
    @source_project = source_project
    @target_project = target_project
    @errors = errors

    open_project_headers "Source-Project" => source_project.identifier,
                         "Target-Project" => target_project.identifier,
                         "Author" => user.login

    message_id target_project, user

    send_localized_mail(user) do
      I18n.t("copy_project.succeeded", target_project_name: target_project.name)
    end
  end

  def project_created(project, user:)
    open_project_headers Project: project.identifier,
                         Author: user.login

    message_id project, user
    @project = project
    @user = user
    notification_text = Setting.new_project_notification_text.presence ||
                        I18n.t("admin.settings.new_project.notification_text_default")
    @notification_text = apply_markdown_field_macros(notification_text, { project:, user: })

    send_localized_mail(user) do
      I18n.t("projects.create.notification_email_subject", project_name: project.name)
    end
  end
end
