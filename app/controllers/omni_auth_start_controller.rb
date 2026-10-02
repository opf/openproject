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

    provider = permitted_omniauth_provider(params[:provider])
    return render_404 if provider.nil?

    @omniauth_provider_name = provider[:name].to_s
    @direct_login_origin = params[:back_url]

    # If we want to redirect to the provider, we need to
    # extend the form-action to the provider's host.
    #
    # Should we fail to find a valid origin, we show an error to the user
    # as they will no longer be able to continue
    ensure_form_action_appended!(provider)
  end

  private

  def ensure_form_action_appended!(provider)
    form_action_origins = Array(provider[:form_action_urls]).filter_map { |url| origin_from_url(url) }

    if form_action_origins.empty?
      render_incomplete_provider(provider)
    else
      append_content_security_policy_directives(form_action: form_action_origins)
    end
  end

  def permitted_omniauth_provider(name)
    OpenProject::Plugins::AuthPlugin.find_provider_by_name(name) ||
      developer_provider(name)
  end

  def developer_provider(name)
    return if name.to_s != "developer" || Rails.env.production?

    { name: "developer", form_action_urls: [root_url] }
  end

  def render_incomplete_provider(provider)
    render_error(
      status: 500,
      message: I18n.t(:error_omniauth_provider_incomplete, provider: provider[:display_name].presence || provider[:name]),
      exception: "OmniAuth provider #{provider[:name].inspect} has no valid :form_action_urls"
    )
  end

  def origin_from_url(url)
    return if url.blank?

    uri = URI.parse(url.to_s)
    return unless uri.scheme.in?(%w[http https]) && uri.host.present?

    URI.join(uri, "/").to_s
  rescue URI::InvalidURIError, ArgumentError
    nil
  end
end
