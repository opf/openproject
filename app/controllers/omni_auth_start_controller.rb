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

class OmniAuthStartController < ApplicationController
  include OmniauthHelper
  include Accounts::RedirectAfterLogin

  skip_before_action :check_if_login_required
  no_authorization_required! :show

  layout "no_menu"

  def show
    return redirect_after_login(User.current) if User.current.logged?

    provider_name = permitted_omniauth_provider_name(params[:provider])
    return render_404 if provider_name.blank?

    @omniauth_provider_name = provider_name
    @direct_login_origin = params[:back_url]
    append_omniauth_form_action(provider_name)
    render "account/omniauth_direct_login"
  end

  private

  def permitted_omniauth_provider_name(name)
    requested = name.to_s
    return requested if requested == direct_login_provider

    provider = OpenProject::Plugins::AuthPlugin.find_provider_by_name(requested)
    return provider[:name].to_s if provider.present?
    return requested if requested == "developer" && !Rails.env.production?

    nil
  end

  def append_omniauth_form_action(provider_name)
    origin = AuthProvider.find_by(slug: provider_name)&.csp_form_action_origin
    return if origin.blank?

    append_content_security_policy_directives(form_action: [origin])
  end
end
