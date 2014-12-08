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
require 'roar/json/hal'

module API
  module V3
    module WorkPackages
      module Form
        class WorkPackagePayloadRepresenter < Roar::Decorator
          include Roar::JSON::HAL
          include Roar::Hypermedia

          self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

          def initialize(represented, options={})
            if options[:enforce_lock_version_validation]
              # enforces availibility validation of lock_version
              represented.lock_version = nil
            end

            super(represented)
          end

          property :_type, exec_context: :decorator, writeable: false

          property :linked_resources,
                   as: :_links,
                   exec_context: :decorator,
                   getter: -> (*) {
                     work_package_attribute_links_representer represented
                   },
                   setter: -> (value, *) {
                     representer = work_package_attribute_links_representer represented
                     representer.from_json(value.to_json)
                   }

          property :lock_version
          property :subject, render_nil: true
          property :raw_description,
                   getter: -> (*) { description },
                   setter: -> (value, *) { self.description = value },
                   render_nil: true
          property :parent_id, writeable: true

          property :project_id,
                   getter: -> (*) { nil },
                   render_nil: false
          property :start_date,
                   getter: -> (*) { nil },
                   render_nil: false
          property :due_date,
                   getter: -> (*) { nil },
                   render_nil: false
          property :version_id,
                   getter: -> (*) { nil },
                   setter: -> (value, *) { self.fixed_version_id = value },
                   render_nil: false
          property :created_at,
                   getter: -> (*) { nil }, render_nil: false
          property :updated_at,
                   getter: -> (*) { nil }, render_nil: false

          def _type
            'WorkPackage'
          end

          private

          def work_package_attribute_links_representer(represented)
            ::API::V3::WorkPackages::Form::WorkPackageAttributeLinksRepresenter.new represented
          end
        end
      end
    end
  end
end
