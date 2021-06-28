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
# See docs/COPYRIGHT.rdoc for more details.
#++

namespace :api do
  desc 'Print all api routes'
  task routes: [:environment] do
    puts <<~HEADER

      Method     Route

    HEADER

    API::Root
      .routes
      .sort_by { |route| route.path + route.request_method }
      .each do |api|
      method = api.request_method.ljust(10)
      path = api.path.gsub(/\A\/:version/, "/api/v3").gsub(/\(\/?\.:format\)/, '')

      puts "#{method} #{path}"
    end
  end

  desc 'Saves the API spec (OAS3.0) to ./docs/api/openproject-apiv3-<branch>.yml'
  task :update_spec, [:branch] => [:environment] do |task, args|
    branch = (args[:branch] || "stable").to_sym
    spec = API::OpenAPI::BlueprintImport.convert version: branch, single_file: false

    File.open(Rails.application.root.join("docs/api/apiv3/openapi-spec.yml"), "w") do |f|
      f.write spec.to_yaml
    end
  end

  desc 'Saves the API spec (OAS3.0) to ./docs/api/openproject-apiv3-single.yml'
  task :assemble_spec, [:branch] => [:environment] do |task, args|
    branch = (args[:branch] || "stable").to_sym
    spec = API::OpenAPI.spec

    File.open(Rails.application.root.join("docs/api/apiv3/openapi-spec-single.yml"), "w") do |f|
      f.write spec.to_yaml
    end
  end
end
