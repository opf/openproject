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
require 'roar/json'
require 'roar/json/collection'
require 'roar/json/hal'

module API
  module V3
    module WorkPackages
      class WorkPackageCollectionRepresenter < ::API::Decorators::OffsetPaginatedCollection
        element_decorator ::API::V3::WorkPackages::WorkPackageRepresenter

        def initialize(models,
                       self_link,
                       query: {},
                       groups:,
                       total_sums:,
                       page: nil,
                       per_page: nil,
                       current_user:)
          @groups = groups
          @total_sums = total_sums

          super(models,
                self_link,
                query: query,
                page: page,
                per_page: per_page,
                current_user: current_user)
        end

        link :sumsSchema do
          {
            href: api_v3_paths.work_package_sums_schema,
          } if total_sums || groups && groups.any?(&:has_sums?)
        end

        link :createWorkPackage do
          {
            href: api_v3_paths.create_work_package_form,
            method: :post
          } if current_user.allowed_to?(:add_work_packages, nil, global: true)
        end

        link :createWorkPackageImmediate do
          {
            href: api_v3_paths.work_packages,
            method: :post
          } if current_user.allowed_to?(:add_work_packages, nil, global: true)
        end

        collection :elements,
                   getter: -> (*) {
                     work_packages = eager_loaded_work_packages

                     generated_classes = ::Hash.new do |hash, work_package|
                       hit = hash.values.find { |klass|
                         klass.customizable.type_id == work_package.type_id &&
                         klass.customizable.project_id == work_package.project_id
                       }

                       hash[work_package] = hit || element_decorator.create_class(work_package)
                     end

                     work_packages.map { |model|
                       generated_classes[model].new(model, current_user: current_user)
                     }
                   },
                   exec_context: :decorator,
                   embedded: true

        property :groups,
                 exec_context: :decorator,
                 render_nil: false

        property :total_sums,
                 exec_context: :decorator,
                 render_nil: false

        # Eager load elements used in the representer later
        # to avoid n+1 queries triggered from each representer.
        def eager_loaded_work_packages
          ids_in_order = represented.map(&:id)

          work_packages = WorkPackage
                          .include_spent_hours(current_user)
                          .preload(element_decorator.to_eager_load)
                          .where(id: ids_in_order)
                          .select('work_packages.*')
                          .to_a

          work_packages.sort_by { |wp| ids_in_order.index(wp.id) }
        end

        private

        attr_reader :groups,
                    :total_sums
      end
    end
  end
end
