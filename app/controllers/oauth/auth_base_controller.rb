#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

module OAuth
  ##
  # Base controller for doorkeeper to skip the login check
  # because it needs to set a specific return URL
  # See config/initializers/doorkeeper.rb
  class AuthBaseController < ::ApplicationController
    skip_before_action :check_if_login_required
    after_action :extend_content_security_policy
    layout 'only_logo'

    def extend_content_security_policy
      use_content_security_policy_named_append(:oauth)
    end

    def allowed_forms
      allowed_redirect_urls = pre_auth&.client&.application&.redirect_uri
      urls = allowed_redirect_urls.to_s.split
      urls.map { |url| URI.join(url, '/') }.map(&:to_s)
    end
  end
end
