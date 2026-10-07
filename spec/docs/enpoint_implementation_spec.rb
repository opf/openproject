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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Endpoints" do
  # rubocop:disable-next RSpec/LeakyLocalVariable
  specification_routes = API::OpenAPI.assemble_spec(Rails.root.join("docs/api/apiv3/openapi-spec.yml"))
                                     .fetch("paths")
                                     .map { |path, methods| methods.keys.map { |method| { method:, path: } } }
                                     .flatten

  # rubocop:disable-next RSpec/LeakyLocalVariable
  implementation_routes = API::V3::Root.routes.map do |route|
    { method: route.request_method, path: "/api/v3#{route.namespace}" }
  end

  specification_routes.each do |route|
    it "must have an implementation for #{route[:method].upcase} #{route[:path]}" do
      expect(implementation_routes).to include_route_definition(route)
    end
  end

  implementation_routes.each do |route|
    it "must have a specification for #{route[:method].upcase} #{route[:path]}" do
      expect(specification_routes).to include_route_definition(route)
    end
  end
end
