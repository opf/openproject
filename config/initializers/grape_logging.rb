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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

Rails.application.configure do
  config.after_initialize do
    ActiveSupport::Notifications.subscribe("openproject_grape_logger") do |_, _, _, _, payload|
      # Have attributes somewhat in the same order as lograge does with
      # processed controller action to ease later grok parsing.
      # See `Lograge::LogSubscribers::ActionController#initial_data`
      attributes = {
        method: payload[:method],
        path: payload[:path],
        duration: payload[:time][:total],
        db: payload[:time][:db],
        view: payload[:time][:view],
        **payload.except(:method, :path, :time)
      }

      extended = OpenProject::Logging.extend_payload!(attributes, {})
      Rails.logger.info OpenProject::Logging.formatter.call(extended)
    end
  end
end
