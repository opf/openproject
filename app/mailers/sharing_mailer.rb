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

class SharingMailer < ApplicationMailer
  include MailNotificationHelper
  helper :mail_notification

  def shared_work_package(sharer, membership, group = nil) # rubocop:disable Metrics/AbcSize
    @sharer = sharer
    @shared_with_user = membership.principal
    @invitation_token = @shared_with_user.invited? ? @shared_with_user.invitation_token : nil
    @group = group
    @work_package = membership.entity

    role = membership.roles.first
    @url = optionally_activated_url(work_package_url(@work_package), @invitation_token)

    set_open_project_headers(@work_package)
    message_id(membership, sharer)

    send_localized_mail(@shared_with_user) do
      @role_rights = derive_role_rights(role)
      @allowed_work_package_actions = derive_allowed_work_package_actions(role)
      I18n.t("mail.sharing.work_packages.subject", id: @work_package.formatted_id)
    end
  end

  private

  def optionally_activated_url(back_url, invitation_token)
    return back_url unless invitation_token

    url_for(controller: "/account",
            action: :activate,
            token: invitation_token.value,
            back_url:)
  end

  def derive_role_rights(role)
    case role.builtin
    when Role::BUILTIN_WORK_PACKAGE_EDITOR
      I18n.t("work_package.permissions.edit")
    when Role::BUILTIN_WORK_PACKAGE_COMMENTER
      I18n.t("work_package.permissions.comment")
    when Role::BUILTIN_WORK_PACKAGE_VIEWER
      I18n.t("work_package.permissions.view")
    end
  end

  def derive_allowed_work_package_actions(role)
    allowed_actions =
      case role.builtin
      when Role::BUILTIN_WORK_PACKAGE_EDITOR
        [I18n.t("work_package.permissions.view_verb"),
         I18n.t("work_package.permissions.comment_verb"),
         I18n.t("work_package.permissions.edit_verb")]
      when Role::BUILTIN_WORK_PACKAGE_COMMENTER
        [I18n.t("work_package.permissions.view_verb"),
         I18n.t("work_package.permissions.comment_verb")]
      when Role::BUILTIN_WORK_PACKAGE_VIEWER
        [I18n.t("work_package.permissions.view_verb")]
      end

    allowed_actions.map(&:downcase)
  end

  def set_open_project_headers(work_package)
    open_project_headers "Project" => work_package.project.identifier,
                         "WorkPackage-Id" => work_package.id,
                         "Type" => "WorkPackage"
  end
end
