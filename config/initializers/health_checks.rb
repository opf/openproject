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
    OkComputer::Registry.register "worker", OpenProject::HealthChecks::GoodJobCheck.new
    OkComputer::Registry.register "worker_backed_up", OpenProject::HealthChecks::GoodJobBackedUpCheck.new

    OkComputer::Registry.register "puma", OpenProject::HealthChecks::PumaCheck.new

    # Make dj backed up optional due to bursts
    OkComputer.make_optional %w(worker_backed_up puma)

    # Register web worker check for web + database
    OkComputer::CheckCollection.new("web").tap do |collection|
      collection.register :default, OkComputer::Registry.fetch("default")
      collection.register :database, OkComputer::Registry.fetch("database")
      OkComputer::Registry.default_collection.register "web", collection
    end

    # Register full check for web + database + dj worker
    OkComputer::CheckCollection.new("full").tap do |collection|
      collection.register :default, OkComputer::Registry.fetch("default")
      collection.register :database, OkComputer::Registry.fetch("database")
      collection.register :mail, OpenProject::HealthChecks::SmtpCheck.new
      collection.register :worker, OkComputer::Registry.fetch("worker")
      collection.register :worker_backed_up, OkComputer::Registry.fetch("worker_backed_up")
      collection.register :puma, OkComputer::Registry.fetch("puma")
      OkComputer::Registry.default_collection.register "full", collection
    end

    # Check if authentication required
    authentication_password = OpenProject::Configuration.health_checks_authentication_password
    if authentication_password.present?
      OkComputer.require_authentication("health_checks", authentication_password)
    end
  end
end
