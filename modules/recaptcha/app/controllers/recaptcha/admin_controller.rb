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

module ::Recaptcha
  class AdminController < ApplicationController
    include ::RecaptchaHelper

    before_action :require_admin
    before_action :validate_settings, only: :update
    layout "admin"

    menu_item :plugin_recaptcha

    def show; end

    def update
      Setting.plugin_openproject_recaptcha = @settings
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to action: :show
    end

    private

    def validate_settings
      new_params = permitted_params
      allowed_options = recaptcha_available_options.map(&:last)

      unless allowed_options.include? new_params[:recaptcha_type]
        flash[:error] = I18n.t(:error_code, code: "400")
        redirect_to action: :show
        return
      end

      @settings = new_params.to_h.symbolize_keys
    end

    def permitted_params
      params.permit(:recaptcha_type, :website_key, :secret_key, :response_limit)
    end
  end
end
