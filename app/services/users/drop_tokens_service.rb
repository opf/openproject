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

module Users
  ##
  # Remove all recovery and invitation tokens for the user
  class DropTokensService
    attr_accessor :user

    def initialize(current_user:)
      @user = current_user
    end

    def call!(clear_invitation_tokens: true)
      invalidate_recovery_tokens
      invalidate_invitation_tokens if clear_invitation_tokens
    end

    private

    def invalidate_recovery_tokens
      Token::Recovery.where(user:).delete_all
    end

    def invalidate_invitation_tokens
      Token::Invitation.where(user:).delete_all
    end
  end
end
