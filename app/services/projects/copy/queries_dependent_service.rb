#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Projects::Copy
  class QueriesDependentService < ::Copy::Dependency
    protected

    def perform(params:, state:)
      copy_queries(state[:work_packages_map])
    end

    # Copies queries from +project+
    # Only includes the queries visible in the wp table view.
    def copy_queries(work_packages_map)

      source.queries.non_hidden.includes(:query_menu_item).each do |query|
        new_query = duplicate_query(query)
        duplicate_query_menu_item(query, new_query)
        duplicate_query_order(query, new_query, work_packages_map) if query.manually_sorted?
      end
    end

    def duplicate_query(query)
      new_query = ::Query.new name: '_'
      new_query.attributes = query.attributes.dup.except('id', 'project_id', 'sort_criteria')
      new_query.sort_criteria = query.sort_criteria if query.sort_criteria
      new_query.set_context
      new_query.project = target
      target.queries << new_query
      new_query.set_context

      new_query
    end

    def duplicate_query_order(query, new_query, work_packages_map)
      query.ordered_work_packages.find_each do |ordered_wp|
        wp_id = work_packages_map[ordered_wp.work_package_id]
        # Nothing to do if the work package could not be copied for whatever reason
        next unless wp_id

        copied = ordered_wp.dup
        copied.query_id = new_query.id
        copied.work_package_id = wp_id
        copied.save
      end
    end

    def duplicate_query_menu_item(query, new_query)
      if query.query_menu_item && new_query.persisted?
        ::MenuItems::QueryMenuItem.create(
          navigatable_id: new_query.id,
          name: SecureRandom.uuid,
          title: query.query_menu_item.title
        )
      end
    end
  end
end
