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

class WorkPackageMailer < ApplicationMailer
  helper :mail_notification

  def mentioned(recipient, journal)
    @user = recipient
    @work_package = journal.journable
    @journal = journal

    author = journal.user

    User.execute_as author do
      set_work_package_headers(@work_package)

      message_id journal, recipient
      references journal

      send_localized_mail(recipient) do
        I18n.t(:"mail.mention.subject",
               user_name: author.name,
               id: @work_package.id,
               subject: @work_package.subject)
      end
    end
  end

  def watcher_changed(work_package, user, watcher_changer, action)
    User.execute_as user do
      @work_package = work_package
      @watcher_changer = watcher_changer
      @action = action

      set_work_package_headers(work_package)
      message_id work_package, user
      references work_package

      send_localized_mail(user) do
        subject_for_work_package(work_package)
      end
    end
  end

  private

  def subject_for_work_package(work_package)
    "#{work_package.project.name} - #{work_package.status.name} #{work_package.type.name} " +
      "##{work_package.id}: #{work_package.subject}"
  end

  def set_work_package_headers(work_package)
    open_project_headers "Project" => work_package.project.identifier,
                         "WorkPackage-Id" => work_package.id,
                         "WorkPackage-Author" => work_package.author.login,
                         "Type" => "WorkPackage"

    if work_package.assigned_to
      open_project_headers "WorkPackage-Assignee" => work_package.assigned_to.login
    end
  end
end
