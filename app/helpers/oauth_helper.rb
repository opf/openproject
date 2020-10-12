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

module OAuthHelper
  ##
  # Output the translated scope names for the given application
  def oauth_scope_translations(application)
    strings = application.scopes.to_a

    if strings.empty?
      I18n.t("oauth.scopes.api_v3")
    else
      safe_join(strings.map { |scope| I18n.t("oauth.scopes.#{scope}", default: scope) }, '</br>'.html_safe)
    end
  end

  ##
  # Get granted applications for the given user
  def granted_applications(user = current_user)
    tokens = ::Doorkeeper::AccessToken.active_for(user).includes(:application)
    tokens.group_by(&:application)
  end
end
