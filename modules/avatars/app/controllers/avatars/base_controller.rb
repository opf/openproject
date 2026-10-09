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

module ::Avatars
  class BaseController < ::ApplicationController
    before_action :ensure_enabled

    def update
      if request.put?
        result = service_request(type: :update)
        if result.success?
          flash[:notice] = result.result
          render plain: result.result, status: :ok
        else
          render plain: result.errors.full_messages.join(", "), status: :bad_request
        end
      else
        head :method_not_allowed
      end
    end

    def destroy
      if request.delete?
        result = service_request(type: :destroy)

        # Regular flash (not flash.now): the turbo_stream "reload" response below
        # triggers a full page reload, so the message must survive to that request.
        # rubocop:disable Rails/ActionControllerFlashBeforeRender
        if result.success?
          flash[:notice] = result.result
        else
          flash[:error] = result.errors.full_messages.join(", ")
        end
        # rubocop:enable Rails/ActionControllerFlashBeforeRender

        # A full reload (not a Turbo visit) is needed so the browser refetches the
        # cached avatar image; the turbo_power "reload" action does just that.
        render turbo_stream: turbo_stream.reload
      else
        head :method_not_allowed
      end
    end

    private

    def redirect_path
      raise SubclassResponsibilityError
    end

    def ensure_enabled
      unless ::OpenProject::Avatars::AvatarManager.avatars_enabled?
        render_404
      end
    end

    def service_request(type:)
      service = ::Avatars::UpdateService.new @user

      if type == :update
        service.replace params[:file]
      elsif type == :destroy
        service.destroy
      end
    end
  end
end
