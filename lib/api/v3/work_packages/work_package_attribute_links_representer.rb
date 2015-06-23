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
      class WorkPackageAttributeLinksRepresenter < Roar::Decorator
        include Roar::JSON::HAL
        include Roar::Hypermedia
        include API::V3::Utilities::PathHelper

        class << self
          def create_class(work_package)
            injector_class = ::API::V3::Utilities::CustomFieldInjector
            injector_class.create_value_representer_for_link_patching(
              work_package,
              WorkPackageAttributeLinksRepresenter)
          end

          def create(work_package)
            create_class(work_package).new(work_package)
          end
        end

        self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

        def self.linked_property(property,
                                 namespace: property.to_s.pluralize,
                                 association: "#{property}_id",
                                 path: property,
                                 show_if: true)

          property property,
                   exec_context: :decorator,
                   getter: -> (*) {
                     ::API::Decorators::LinkObject.new(represented,
                                                       property_name: property,
                                                       path: path,
                                                       namespace: namespace,
                                                       getter: association)
                   },
                   setter: -> (value, *) {
                     link = ::API::Decorators::LinkObject.new(represented,
                                                              property_name: property,
                                                              path: path,
                                                              namespace: namespace,
                                                              getter: association)
                     link.from_hash(value)
                   },
                   if: show_if
        end

        linked_property :type
        linked_property :status
        linked_property :assignee,
                        namespace: :users,
                        association: :assigned_to_id,
                        path: :user
        linked_property :responsible,
                        namespace: :users,
                        association: :responsible_id,
                        path: :user
        linked_property :category
        linked_property :version,
                        association: :fixed_version_id
        linked_property :priority
      end
    end
  end
end
