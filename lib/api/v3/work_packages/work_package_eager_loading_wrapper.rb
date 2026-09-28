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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module V3
    module WorkPackages
      class WorkPackageEagerLoadingWrapper < API::V3::Utilities::EagerLoading::EagerLoadingWrapper
        def wrapped?
          true
        end

        class << self
          attr_accessor :timestamps, :query

          def wrap(ids_in_order, current_user, timestamps: nil, query: nil)
            work_packages = add_eager_loading(WorkPackage.where(id: ids_in_order), current_user).to_a

            wrap_and_apply(work_packages, eager_loader_classes_all, timestamps:, query:)
              .sort_by { |wp| ids_in_order.index(wp.id) }
          end

          def wrap_one(work_package, _current_user, timestamps: nil, query: nil)
            return work_package if work_package.respond_to?(:wrapped?)

            wrap_and_apply([work_package], eager_loader_classes_all, timestamps:, query:)
              .first
          end

          def add_eager_loading_extension(name, &block)
            eager_loading_extensions[name] = block
          end

          private

          def eager_loading_extensions
            @eager_loading_extensions ||= {}
          end

          def wrap_and_apply(work_packages, container_classes, timestamps:, query:)
            containers = container_classes
                         .map { |klass| klass.new(work_packages, timestamps:, query:) }

            work_packages = work_packages.map do |work_package|
              new(work_package)
            end

            containers.each do |container|
              work_packages.each do |work_package|
                container.apply(work_package)
              end
            end

            work_packages
          end

          def eager_loader_classes_all
            [
              ::API::V3::WorkPackages::EagerLoading::Hierarchy,
              ::API::V3::WorkPackages::EagerLoading::Ancestor,
              ::API::V3::WorkPackages::EagerLoading::Project,
              ::API::V3::WorkPackages::EagerLoading::Principals,
              ::API::V3::WorkPackages::EagerLoading::Checksum,
              ::API::V3::WorkPackages::EagerLoading::CustomValue,
              ::API::V3::WorkPackages::EagerLoading::CustomAction,
              # Have the historic attributes last as they require the custom values
              # to be loaded first in order to create the diffs between the current
              # and the historic values without loading the custom fields (Acts::Journalized::Differ).
              ::API::V3::WorkPackages::EagerLoading::HistoricAttributes
            ]
          end

          def add_eager_loading(scope, current_user)
            # The eager loading on status is required for the readonly? check in the
            # work package schema
            eager_scope = scope
              .joins(derived_dates_subquery(scope).join_sources)
              .includes(WorkPackageRepresenter.to_eager_load)
              .includes(:status)
              .select("work_packages.*")
              .select("derived_dates.derived_start_date", "derived_dates.derived_due_date")
              .distinct

            apply_eager_loading_extensions(eager_scope, scope, current_user)
          end

          def apply_eager_loading_extensions(eager_scope, scope, current_user)
            eager_loading_extensions.values.inject(eager_scope) do |extended_scope, extension|
              extension.call(extended_scope, scope, current_user)
            end
          end

          def derived_dates_subquery(scope)
            dates_scope = scope
                            .dup
                            .include_derived_dates
                            .select(:id)

            wp_table = WorkPackage.arel_table

            wp_table
              .outer_join(dates_scope.arel.as("derived_dates"))
              .on(wp_table[:id].eq(dates_scope.arel_table.alias("derived_dates")[:id]))
          end
        end

        eager_loader_classes_all.each do |klass|
          include(klass.module)
        end
      end
    end
  end
end
