#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

require 'work_packages/create_contract'
require 'concerns/user_invitation'

module Users
  class CreateService < ::BaseServices::Create
    private

    def persist(call)
      new_user = call.result

      return super(call) unless new_user.invited?

      # As we're basing on the user's mail, this parameter is required
      # before we're able to validate the contract or user
      return fail_with_missing_email(new_user) if new_user.mail.blank?

      invite_user!(new_user)
    end

    def fail_with_missing_email(new_user)
      ServiceResult.failure(result: new_user).tap do |result|
        result.errors.add :mail, :blank
      end
    end

    def invite_user!(new_user)
      invited = ::UserInvitation.invite_user! new_user
      new_user.errors.add :base, I18n.t(:error_can_not_invite_user) unless invited.is_a? User

      ServiceResult.new(success: new_user.errors.empty?, result: invited)
    end
  end
end
