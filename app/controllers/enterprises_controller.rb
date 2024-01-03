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
class EnterprisesController < ApplicationController
  include EnterpriseTrialHelper

  layout 'admin'
  menu_item :enterprise

  before_action :chargebee_content_security_policy
  before_action :youtube_content_security_policy
  before_action :require_admin
  before_action :check_user_limit, only: [:show]
  before_action :check_domain, only: [:show]
  before_action :render_gon

  def show
    @current_token = EnterpriseToken.current
    @token = @current_token || EnterpriseToken.new

    if !@current_token.present?
      helpers.write_trial_key_to_gon
    end
  end

  def create
    @token = EnterpriseToken.current || EnterpriseToken.new
    saved_encoded_token = @token.encoded_token
    @token.encoded_token = params[:enterprise_token][:encoded_token]
    if @token.save
      flash[:notice] = t(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to action: :show }
        format.json { head :no_content }
      end
    else
      # restore the old token
      if saved_encoded_token
        @token.encoded_token = saved_encoded_token
        @current_token = @token || EnterpriseToken.new
      end
      respond_to do |format|
        format.html { render action: :show }
        format.json { render json: { description: @token.errors.full_messages.join(", ") }, status: :bad_request }
      end
    end
  end

  def destroy
    token = EnterpriseToken.current
    if token
      token.destroy
      flash[:notice] = t(:notice_successful_delete)

      delete_trial_key

      redirect_to action: :show
    else
      render_404
    end
  end

  def save_trial_key
    Token::EnterpriseTrialKey.create(user_id: User.system.id, value: params[:trial_key])
  end

  def delete_trial_key
    Token::EnterpriseTrialKey.where(user_id: User.system.id).delete_all
  end

  private

  def render_gon
    helpers.write_augur_to_gon
  end

  def default_breadcrumb
    t(:label_enterprise_edition)
  end

  def show_local_breadcrumb
    true
  end

  def check_user_limit
    if OpenProject::Enterprise.user_limit_reached?
      flash.now[:warning] = I18n.t(
        "warning_user_limit_reached_instructions",
        current: OpenProject::Enterprise.active_user_count,
        max: OpenProject::Enterprise.user_limit
      )
    end
  end

  def check_domain
    if OpenProject::Enterprise.token.try(:invalid_domain?)
      flash.now[:error] = I18n.t(
        "error_enterprise_token_invalid_domain",
        expected: Setting.host_name,
        actual: OpenProject::Enterprise.token.domain
      )
    end
  end
end
