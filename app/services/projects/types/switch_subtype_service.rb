# frozen_string_literal: true

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

module Projects
  module Types
    # Migrates a project from one subtype to another type of the same family
    # (a sibling subtype or the shared parent). All work packages of the old
    # subtype are switched to the target type before the old subtype is removed
    # and the target type enabled, all within a single transaction.
    class SwitchSubtypeService < BaseService
      private

      def persist(service_call)
        source = params[:source]
        target = params[:target]

        if !source.subtype?
          return failure(:switch_source_not_a_subtype)
        elsif source == target
          return failure(:switch_target_identical)
        elsif source.root != target.root
          return failure(:switch_target_not_in_family)
        end

        switch(service_call, source, target)
      end

      def switch(service_call, source, target)
        add_type(target)
        reassign_work_packages(source, target).each { |wp_result| service_call.add_dependent!(wp_result) }
        return service_call if service_call.failure?

        model.types.delete(source)

        service_call
      end

      def add_type(target)
        model.types << target unless model.types.include?(target)
        enable_work_package_custom_fields(target)
      end

      def reassign_work_packages(source, target)
        WorkPackage.where(project: model, type: source).map do |work_package|
          WorkPackages::UpdateService
            .new(user:, model: work_package)
            .call(type: target)
        end
      end
    end
  end
end
