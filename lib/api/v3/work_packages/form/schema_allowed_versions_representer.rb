#-- encoding: UTF-8
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

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module WorkPackages
      module Form
        class SchemaAllowedVersionsRepresenter < Roar::Decorator
          include Roar::JSON::HAL

          self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

          property :links_to_allowed_versions,
                   as: :_links,
                   getter: -> (*) { self } do
            include API::V3::Utilities::PathHelper

            self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

            property :allowed_values, exec_context: :decorator

            def allowed_values
              represented[:versions].map do |version|
                { href: api_v3_paths.version(version.id), title: version.name }
              end
            end
          end

          property :type, getter: -> (*) { 'Version' }

          collection :allowed_values,
                     embedded: true,
                     getter: -> (*) {
                       self[:versions].map do |version|
                         Versions::VersionRepresenter.new(version, current_user: self[:current_user])
                       end
                     }
        end
      end
    end
  end
end
