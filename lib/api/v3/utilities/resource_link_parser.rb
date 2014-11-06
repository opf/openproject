#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

module API
  module V3
    module Utilities
      class ResourceLinkParser
        def parse(resource_link)
          matching_resources = API::V3::Root.routes.map do |route|
            route_options = route.instance_variable_get(:@options)
            match = route_options[:compiled].match(resource_link)

            if match
              {
                ns: /\/(?<ns>\w+)\//.match(route_options[:namespace])[:ns],
                id: match[:id]
              }
            end
          end

          matching_resources.compact!.uniq! { |c| c[:ns] }

          unless matching_resources.empty?
            { ns: matching_resources[0][:ns], id: matching_resources[0][:id] }
          end
        end
      end
    end
  end
end
