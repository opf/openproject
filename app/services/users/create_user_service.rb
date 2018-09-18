#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'work_packages/create_contract'
require 'concerns/user_invitation'

module Users
  class CreateUserService
    include Concerns::Contracted

    attr_reader :current_user

    def initialize(current_user:)
      @current_user = current_user
      self.contract_class = Users::CreateContract
    end

    def call(new_user)
      User.execute_as current_user do
        create(new_user)
      end
    end

    private

    def create(new_user)
      return create_regular(new_user) unless new_user.invited?

      # As we're basing on the user's mail, this parameter is required
      # before we're able to validate the contract or user
      if new_user.mail.blank?
        contract = instantiate_contract(new_user, current_user)
        contract.errors.add :mail, :blank
        build_result(new_user, contract.errors)
      else
        create_invited(new_user)
      end
    end

    def build_result(result, errors)
      success = result.is_a?(User) && errors.empty?
      ServiceResult.new(success: success, errors: errors, result: result)
    end

    ##
    # Create regular user
    def create_regular(new_user)
      result, errors = validate_and_save(new_user, current_user)
      ServiceResult.new(success: result, errors: errors, result: new_user)
    end

    ##
    # User creation flow for users that are invited.
    # Re-uses UserInvitation and thus avoids +validate_and_save+
    def create_invited(new_user)
      # Assign values other than mail to new_user
      ::UserInvitation.assign_user_attributes new_user

      # Check contract validity before moving to UserInvitation
      if !validate(new_user, current_user)
        build_result(new_user, contract.errors)
      end

      invite_user! new_user
    end

    def invite_user!(new_user)
      invited = ::UserInvitation.invite_user! new_user
      new_user.errors.add :base, I18n.t(:error_can_not_invite_user) unless invited.is_a? User

      build_result(invited, new_user.errors)
    end
  end
end
