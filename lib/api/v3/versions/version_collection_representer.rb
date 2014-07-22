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

require 'roar/decorator'
require 'representable/json/collection'
require 'roar/representer/json/hal'

module API
  module V3
    module Versions
      class VersionCollectionRepresenter < Roar::Decorator
        include Roar::Representer::JSON::HAL
        include OpenProject::StaticRouting::UrlHelpers

        self.as_strategy = API::Utilities::CamelCasingStrategy.new

        attr_reader :project

        def initialize(model, options = {})
          @project = options.fetch(:project)
          super(model)
        end

        link :self do
          "#{root_url}api/v3/projects/#{project.id}/versions"
        end

        property :_type, exec_context: :decorator

        collection :versions, embedded: true, extend: VersionRepresenter, getter: ->(_) { self }

        def _type
          'Versions'
        end
      end
    end
  end
end
