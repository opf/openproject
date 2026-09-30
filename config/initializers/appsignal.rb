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

require "open_project/version"
require_relative "../../lib_static/open_project/appsignal"

if OpenProject::Appsignal.enabled?
  require "appsignal"

  Rails.application.configure do |app|
    app.middleware.insert_after(
      ActionDispatch::DebugExceptions,
      Appsignal::Rack::RailsInstrumentation
    )
  end

  Appsignal.configure do |config|
    config.active = true
    config.name = ENV.fetch("APPSIGNAL_NAME")
    config.push_api_key = ENV.fetch("APPSIGNAL_KEY")
    config.revision = OpenProject::VERSION.to_s

    if ENV["APPSIGNAL_DEBUG"] == "true"
      config.log = "stdout"
      config.log_level = "debug"
    end

    config.ignore_actions = [
      "OkComputer::OkComputerController#show",
      "OkComputer::OkComputerController#index",
      "GET::API::V3::Notifications::NotificationsAPI",
      "GET::API::V3::Notifications::NotificationsAPI#/:version/notifications"
    ]

    config.ignore_errors = [
      "Grape::Exceptions::MethodNotAllowed",
      "ActionController::UnknownFormat",
      "ActiveJob::DeserializationError",
      "Net::SMTPServerBusy"
    ]

    config.ignore_logs = [
      "GET /health_check"
    ]

    config.filter_session_data = %w[
      _csrf_token
      omniauth.oidc_access_token
      omniauth.oidc_sid
    ]
  end

  # Extend the core log delegator
  handler = OpenProject::Appsignal.method(:exception_handler)
  OpenProject::Logging::LogDelegator.register(:appsignal, handler)

  # Send our logs to appsignal
  if OpenProject::Appsignal.logging_enabled?
    appsignal_logger = Appsignal::Logger.new("rails")
    Rails.logger.broadcast_to(appsignal_logger)
  end

  Appsignal.start
end
