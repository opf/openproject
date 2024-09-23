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

# Sends mails for updates to memberships. There can be three cases we have to cover:
# * user is added to a project
# * existing project membership is altered
# * global roles are altered
#
# There is no creation of a global membership as far as the user is concerned. Hence, all
# global cases can be covered by one method.
#
# The mailer does not fan out in case a group is provided. The individual members of a group
# need to be mailed to individually.

class MemberMailer < ApplicationMailer
  include OpenProject::StaticRouting::UrlHelpers
  include OpenProject::TextFormatting

  def added_project(current_user, member, message)
    alter_project(current_user,
                  member,
                  in_member_locale(member) { I18n.t(:"mail_member_added_project.subject", project: member.project.name) },
                  message)
  end

  def updated_project(current_user, member, message)
    alter_project(current_user,
                  member,
                  in_member_locale(member) { I18n.t(:"mail_member_updated_project.subject", project: member.project.name) },
                  message)
  end

  def updated_global(current_user, member, message)
    send_mail(current_user,
              member,
              in_member_locale(member) { I18n.t(:"mail_member_updated_global.subject") },
              message)
  end

  private

  def alter_project(current_user, member, subject, message)
    send_mail(current_user,
              member,
              subject,
              message) do
      open_project_headers Project: member.project.identifier

      @project = member.project
    end
  end

  def send_mail(current_user, member, subject, message)
    User.execute_as(current_user) do
      in_member_locale(member) do
        message_id member, current_user

        @roles = member.roles
        @principal = member.principal
        @message = message

        yield if block_given?

        mail to: member.principal,
             subject:
      end
    end
  end

  def in_member_locale(member, &)
    raise ArgumentError unless member.principal.is_a?(User)

    with_locale_for(member.principal, &)
  end
end
