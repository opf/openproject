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

module OmniauthHelper
  def omniauth_direct_login?
    direct_login_provider.is_a? String
  end

  ##
  # Per default the user may choose the usual password login as well as several omniauth providers
  # on the login page and in the login drop down menu.
  #
  # With his configuration option you can set a specific omniauth provider to be
  # used for direct login. Meaning that the login provider selection is skipped and
  # the configured provider is used directly instead.
  #
  # If this option is active /login will lead directly to the configured omniauth provider
  # and so will a click on 'Sign in' (as opposed to opening the drop down menu).
  def direct_login_provider
    OpenProject::Configuration['omniauth_direct_login_provider']
  end
end
