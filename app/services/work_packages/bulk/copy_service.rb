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

module WorkPackages
  module Bulk
    class CopyService < BulkedService
      attr_reader :wp_map

      def initialize(user:, work_packages:)
        super

        @wp_map = {}

        self.work_packages = remove_hierarchy_duplicates(work_packages)
      end

      private

      def bulk(params)
        result = ServiceResult.success result: true

        work_packages.each do |work_package|
          # As updating one work package might have already saved another one,
          # e.g. by changing the start/due date or the version
          # we need to reload the work packages to avoid running into stale object errors.
          work_package.reload

          call_move_hook(work_package, params)
          wp_copy = alter_work_package(work_package, params)

          result.add_dependent!(wp_copy)

          wp_map.store(work_package.id, wp_copy.result.id)
        end

        result.on_success do
          copy_relations
        end

        result.result = false if result.failure?

        result
      end

      def copy_relations
        relations = Relation.where(to_id: wp_map.keys, from_id: wp_map.keys)

        relations.each do |relation|
          new_relation = relation.dup
          new_relation.from_id = wp_map[relation.from_id]
          new_relation.to_id = wp_map[relation.to_id]
          new_relation.save!
        end
      end

      def alter_work_package(work_package, attributes)
        ancestors = {}
        result = copy_with_updated_parent_id(work_package, attributes, ancestors)

        work_package
          .descendants
          .order_by_ancestors("asc")
          .each do |wp|
          copied = copy_with_updated_parent_id(wp, attributes, ancestors)

          wp_map.store(wp.id, copied.result.id)

          result.add_dependent!(copied)
        end

        result
      end

      def call_move_hook(work_package, params)
        return if OpenProject::Hook.hook_listeners(:controller_work_packages_move_before_save).empty?

        call_hook(:controller_work_packages_move_before_save,
                  params:,
                  work_package:,
                  target_project: params[:project_id] ? Project.find_by(id: params[:project_id]) : nil,
                  copy: true)
      end

      def copy_with_updated_parent_id(work_package, attributes, ancestors)
        with_updated_parent_id(work_package, attributes, ancestors) do |overridden_attributes|
          WorkPackages::CopyService
            .new(user:,
                 work_package:)
            .call(**overridden_attributes.symbolize_keys)
        end
      end

      def with_updated_parent_id(work_package, attributes, ancestors)
        # avoid modifying attributes which could carry over
        # to the next work_package
        overridden_attributes = attributes.dup

        overridden_attributes[:parent_id] = ancestors[work_package.parent_id] || work_package.parent_id if work_package.parent_id

        copied = yield overridden_attributes

        ancestors[work_package.id] = copied.result.id

        copied
      end

      # Check if a parent work package is also selected for copying
      def remove_hierarchy_duplicates(work_packages)
        # Get all ancestors of the work_packages to copy
        selected_ids = work_packages.pluck(:id)

        work_packages.reject do |wp|
          wp.ancestors.exists?(id: selected_ids)
        end
      end
    end
  end
end
