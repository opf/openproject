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

# puffing-billy is a gem that creates a middleman proxy between the browser controlled
# by capybara/selenium and the spec execution.
#
# This allows us to stub requests to external APIs to guarantee responses regardless of
# their availability.
#
# In order to use the proxied server, you need to use `driver: headless_firefox_billy` in your examples
#
# See https://github.com/oesmith/puffing-billy for more information
require 'billy/capybara/rspec'

require 'table_print' # Add this dependency to your gemfile

##
# To debug stubbed and proxied connections
# uncomment this line
#
# Billy.configure do |c|
#   c.record_requests = true
# end
#
# RSpec.configure do |config|
#   config.prepend_after(:example, type: :feature) do
#     puts "Requests received via Puffing Billy Proxy:"
#
#     puts TablePrint::Printer.table_print(Billy.proxy.requests, [
#       :status,
#       :handler,
#       :method,
#       { url: { width: 100 } },
#       :headers,
#       :body
#     ])
#   end
# end
