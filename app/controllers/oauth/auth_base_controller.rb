#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
  ##
  # Base controller for doorkeeper to skip the login check
  # because it needs to set a specific return URL
  # See config/initializers/doorkeeper.rb
  class AuthBaseController < ::ApplicationController
    # Ensure we prepend the CSP extension
    # before any other action is being performed
    prepend_before_action :extend_content_security_policy

    skip_before_action :check_if_login_required
    layout 'only_logo'

    def extend_content_security_policy
      return unless pre_auth&.authorizable?

      additional_form_actions = application_redirect_uris
      return if additional_form_actions.empty?

      flash[:_csp_appends] = { form_action: additional_form_actions }
      append_content_security_policy_directives flash[:_csp_appends]
    end

    def application_redirect_uris
      pre_auth&.client&.application&.redirect_uri
        .to_s
        .split
        .select { |url| url.start_with?('http') }
        .map { |url| URI.join(url, '/').to_s }
    end
  end
end
