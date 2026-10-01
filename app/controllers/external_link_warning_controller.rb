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

class ExternalLinkWarningController < ApplicationController
  layout "only_logo"

  skip_before_action :check_if_login_required
  no_authorization_required! :show

  before_action :parse_external_url
  before_action :verify_capture_enabled
  before_action :optional_require_login

  def show; end

  private

  def login_back_url_params
    params.permit(:url)
  end

  def verify_capture_enabled
    unless capture_enabled?
      redirect_to @external_url, allow_other_host: true, status: :see_other
    end
  end

  def optional_require_login
    return unless Setting.capture_external_links?
    return unless Setting.capture_external_links_require_login?

    require_login
  end

  def capture_enabled?
    Setting.capture_external_links? && EnterpriseToken.allows_to?(:capture_external_links)
  end

  def parse_external_url
    external_url = params[:url]
    @external_url = parse_url(CGI.unescape(external_url)) if external_url.present?

    if @external_url.nil?
      redirect_to home_path, status: :see_other
    end
  end

  def parse_url(url)
    return nil if url.blank?

    uri = Addressable::URI.parse(url)
    return url if %w[http https].include?(uri.scheme&.downcase)

    nil
  rescue Addressable::URI::InvalidURIError
    nil
  end
end
