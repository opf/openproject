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

module Accounts::AuthenticationStages
  def successful_authentication(user, reset_stages: true, just_registered: false)
    stages = authentication_stages after_activation: just_registered, reset: reset_stages

    if stages.empty?
      # setting params back_url to be used by redirect_after_login
      params[:back_url] = session.delete :back_url if session.include?(:back_url)

      if just_registered || session[:just_registered]
        finish_registration! user
      else
        login_user! user
      end
    else
      stage = stages.first

      session[:just_registered] = just_registered
      session[:authenticated_user_id] = user.id

      redirect_to stage.path
    end
  end

  def stage_success
    stage = session[:authentication_stages]&.first

    if stage && stage.to_s == params[:stage]
      if params[:secret] == stage_secrets[stage]
        session[:authentication_stages] = session[:authentication_stages].drop(1)

        successful_authentication User.find(session[:authenticated_user_id]), reset_stages: false
      else
        flash[:error] = I18n.t(:notice_auth_stage_verification_error, stage:)

        redirect_to signin_path
      end
    else
      flash[:error] = I18n.t(
        :notice_auth_stage_wrong_stage,
        expected: stage || "(none)",
        actual: params[:stage]
      )

      redirect_to signin_path
    end
  end

  def stage_failure
    flash[:error] = flash[:error] || I18n.t(:notice_auth_stage_error, stage: params[:stage])

    redirect_to signin_path
  end

  private

  def finish_registration!(user)
    session[:just_registered] = nil
    self.logged_user = user
    user.update last_login_on: Time.now

    flash[:notice] = I18n.t(:notice_account_registered_and_logged_in)
    redirect_after_login user
  end

  def authentication_stages(after_activation: false, reset: true)
    if OpenProject::Authentication::Stage.stages.select(&:active?).any?
      session.delete %i[authentication_stages stage_secrets back_url] if reset

      if session.include?(:authentication_stages)
        lookup_authentication_stages
      else
        init_authentication_stages after_activation:
      end
    else
      []
    end
  end

  def lookup_authentication_stages
    OpenProject::Authentication::Stage.find_all session[:authentication_stages]
  end

  def init_authentication_stages(after_activation:)
    stages = active_stages after_activation

    session[:authentication_stages] = stages.map(&:identifier)
    session[:stage_secrets] = new_stage_secrets

    # Remember back_url from params since we're redirecting
    # but don't use the referer
    session[:back_url] ||= params[:back_url]

    # Remember the autologin cookie decision
    session[:autologin_requested] = params[:autologin] == "1"

    stages
  end

  def active_stages(after_activation)
    OpenProject::Authentication::Stage
      .stages
      .select(&:active?)
      .select { |s| s.run_after_activation? || !after_activation }
  end

  def stage_secrets
    Hash(session[:stage_secrets])
  end

  def new_stage_secrets
    session[:authentication_stages]
      .index_with { |ident| stage_secret(ident) }
  end

  def stage_secret(_ident)
    SecureRandom.hex(16)
  end
end
