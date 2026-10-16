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

module IndividualPrincipals
  module MembershipControllerMethods
    extend ActiveSupport::Concern

    included do
      before_action :find_membership, only: %i[update destroy]
    end

    def create
      membership_params = permitted_params.membership.merge(principal: @individual_principal)
      call = ::Members::CreateService
        .new(user: current_user)
        .call(membership_params)

      respond_with_service_call call, message: :notice_successful_create
    end

    def update
      call = ::Members::UpdateService
        .new(model: @membership, user: current_user)
        .call(permitted_params.membership)

      respond_with_service_call call, message: :notice_successful_update
    end

    def destroy
      call = ::Members::DeleteService
        .new(model: @membership, user: current_user)
        .call

      respond_with_service_call call, message: :notice_successful_delete
    end

    private

    def find_membership
      @membership = Member.visible(current_user).find(params[:id])
    end

    def respond_with_service_call(call, message:)
      if call.success?
        flash[:notice] = I18n.t(message)
      else
        flash[:error] = call.errors.full_messages.join("\n")
      end

      redirect_to edit_polymorphic_path(@individual_principal, tab: redirected_to_tab(call.result)),
                  status: :see_other
    end
  end
end
