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

module OAuth
  class ApplicationsController < ::ApplicationController
    before_action :require_admin
    before_action :find_app, only: %i[edit update show toggle destroy]
    before_action :prevent_builtin_edits, only: %i[edit update destroy]

    layout "admin"
    menu_item :oauth_applications

    def index
      @applications = ::Doorkeeper::Application.without_integration.includes(:owner).all
    end

    def show
      @reveal_secret = flash[:reveal_secret]
      flash.delete :reveal_secret
    end

    def new
      @application = ::Doorkeeper::Application.new
    end

    def edit; end

    def create
      call = ::OAuth::Applications::CreateService.new(user: current_user)
                                                 .call(permitted_params.oauth_application)
      result = call.result

      if call.success?
        flash[:notice] = t(:notice_successful_create)
        flash[:_application_secret] = result.plaintext_secret
        redirect_to action: :show, id: result.id
      else
        @application = result
        render action: :new, status: :unprocessable_entity
      end
    end

    def toggle
      @application.toggle!(:enabled)
      redirect_to action: :index
    end

    def update
      call = ::OAuth::Applications::UpdateService.new(model: @application, user: current_user)
                                                 .call(permitted_params.oauth_application)

      if call.success?
        flash[:notice] = t(:notice_successful_update)
        redirect_to action: :index
      else
        flash[:error] = call.errors.full_messages.join('\n')
        render action: :edit, status: :unprocessable_entity
      end
    end

    def destroy
      call = OAuth::Applications::DeleteService
        .new(model: @application, user: current_user)
        .call

      if call.success?
        flash[:notice] = t(:notice_successful_delete)
      else
        flash[:error] = t(:error_can_not_delete_entry)
      end

      redirect_to action: :index
    end

    protected

    def default_breadcrumb; end

    def show_local_breadcrumb
      false
    end

    private

    def prevent_builtin_edits
      if @application.builtin?
        render_403
      end
    end

    def find_app
      @application = ::Doorkeeper::Application.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end
end
