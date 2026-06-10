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

Rails.application.reloader.to_prepare do
  # In test mode, enable rules and rack-attack using "with_rack_attack:" metadata
  Rack::Attack.enabled = !Rails.env.test?
  OpenProject::RateLimiting.set_defaults!

  if OpenProject::Configuration.blacklisted_routes.any?
    # Block logins from a bad user agent
    Rack::Attack.blocklist("block forbidden routes") do |req|
      regex = OpenProject::Configuration.blacklisted_routes.map! { |str| Regexp.new(str) }
      regex.any? { |i| i =~ req.path }
    end

    # Route blocklist returns 404.
    # All other blocklists (for example, login ban)
    # use the RateLimiting dispatcher set up by set_defaults!
    Rack::Attack.blocklisted_responder = lambda do |request|
      if request.env["rack.attack.matched"] == "block forbidden routes"
        [404, {}, ["Not found"]]
      else
        OpenProject::RateLimiting.blocklisted_response(request)
      end
    end
  end
end
