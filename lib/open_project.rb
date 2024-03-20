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

require 'redmine/menu_manager'
require 'redmine/search'
require 'open_project/custom_field_format'
require 'open_project/logging'
require 'open_project/patches'
require 'open_project/mime_type'
require 'open_project/custom_styles/design'
require 'open_project/httpx_appsignal'
require 'redmine/plugin'

require 'csv'

module OpenProject
  ##
  # Shortcut to the OpenProject log delegator, which extends
  # default Rails error handling with other error handlers such as appsignal.
  def self.logger
    ::OpenProject::Logging::LogDelegator
  end

  def self.httpx
    # It is essential to reuse HTTPX session if persistent connections are enabled.
    # Otherwise for every request there will be a new connections.
    # And old connections will not be closed properly which could lead to EMFILE error.
    Thread.current[:httpx_session] ||= begin
      session = HTTPX
        .plugin(:persistent) # persistent plugin enables retries plugin under the hood
        .plugin(:oauth)
        .plugin(:basic_auth)
        .plugin(:webdav)
        .with(
          timeout: {
            connect_timeout: OpenProject::Configuration.httpx_connect_timeout,
            write_timeout: OpenProject::Configuration.httpx_write_timeout,
            read_timeout: OpenProject::Configuration.httpx_read_timeout,
            keep_alive_timeout: OpenProject::Configuration.httpx_keep_alive_timeout
          }
        )
      OpenProject::Appsignal.enabled? ? session.plugin(HttpxAppsignal) : session
    end
  end
end
