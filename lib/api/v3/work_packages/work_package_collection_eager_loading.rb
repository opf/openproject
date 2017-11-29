#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module WorkPackages
      module WorkPackageCollectionEagerLoading
        def full_work_packages(ids_in_order)
          wps = add_eager_loading(WorkPackage.where(id: ids_in_order), current_user).to_a

          eager_load_ancestry(wps, ids_in_order)
          eager_load_user_custom_values(wps)
          eager_load_version_custom_values(wps)
          eager_load_list_custom_values(wps)

          wps.sort_by { |wp| ids_in_order.index(wp.id) }
        end

        def add_eager_loading(scope, current_user)
          scope
            .includes(element_decorator.to_eager_load)
            .include_spent_hours(current_user)
            .select('work_packages.*')
            .distinct
        end

        def eager_load_ancestry(work_packages, ids_in_order)
          grouped = WorkPackage.aggregate_ancestors(ids_in_order, current_user)

          work_packages.each do |wp|
            wp.work_package_ancestors = grouped[wp.id] || []
          end
        end

        def eager_load_user_custom_values(work_packages)
          eager_load_custom_values work_packages, 'user', User.includes(:preference)
        end

        def eager_load_version_custom_values(work_packages)
          eager_load_custom_values work_packages, 'version', Version
        end

        def eager_load_list_custom_values(work_packages)
          eager_load_custom_values work_packages, 'list', CustomOption
        end

        def eager_load_custom_values(work_packages, field_format, scope)
          cvs = custom_values_of(work_packages, field_format)

          ids_of_values = cvs.map(&:value).select { |v| v =~ /\A\d+\z/ }

          values_by_id = scope.where(id: ids_of_values).group_by(&:id)

          cvs.each do |cv|
            next unless values_by_id[cv.value.to_i]
            cv.value = values_by_id[cv.value.to_i].first
          end
        end

        def custom_values_of(work_packages, field_format)
          cvs = []

          work_packages.each do |wp|
            wp.custom_values.each do |cv|
              cvs << cv if cv.custom_field.field_format == field_format && cv.value.present?
            end
          end

          cvs
        end
      end
    end
  end
end
