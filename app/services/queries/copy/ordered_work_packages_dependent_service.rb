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

module Queries::Copy
  class OrderedWorkPackagesDependentService < ::Copy::Dependency
    protected

    def copy_dependency(params:)
      return unless source.manually_sorted?

      duplicate_query_order(source, target)
    end

    def duplicate_query_order(query, new_query)
      query.ordered_work_packages.find_each do |ordered_wp|
        copied = ordered_wp.dup
        copied.query_id = new_query.id
        copied.work_package_id = lookup_work_package_id(ordered_wp.work_package_id)
        copied.save
      end
    end

    ##
    # Tries to lookup the work package id if
    # we're in a mapped condition (e.g., copying a project)
    def lookup_work_package_id(id)
      if state.work_package_id_lookup
        state.work_package_id_lookup[id] || id
      else
        id
      end
    end
  end
end
