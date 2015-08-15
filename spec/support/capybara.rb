#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'capybara/rails'

Capybara.javascript_driver = :webkit

Capybara::Webkit.configure do |config|
  # Enable debug mode. Prints a log of everything the driver is doing.
  # config.debug = true

  # By default, requests to outside domains (anything besides localhost) will
  # result in a warning. Several methods allow you to change this behavior.

  # Silently return an empty 200 response for any requests to unknown URLs.
  config.block_unknown_urls

  # Allow pages to make requests to any URL without issuing a warning.
  # config.allow_unknown_urls

  # Allow a specifc domain without issuing a warning.
  # config.allow_url("example.com")

  # Allow a specifc URL and path without issuing a warning.
  # config.allow_url("example.com/some/path")

  # Wildcards are allowed in URL expressions.
  # config.allow_url("*.example.com")

  # Silently return an empty 200 response for any requests to the given URL.
  # config.block_url("example.com")

  # Timeout if requests take longer than 5 seconds
  config.timeout = 2

  # Don't raise errors when SSL certificates can't be validated
  config.ignore_ssl_errors

  # Don't load images
  # config.skip_image_loading

  # Use a proxy
  # config.use_proxy(
  #   host: "example.com",
  #   port: 1234,
  #   user: "proxy",
  #   pass: "secret"
  # )
end
