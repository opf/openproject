#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module WorkPackage::Ancestors
  extend ActiveSupport::Concern

  included do
    attr_accessor :work_package_ancestors

    ##
    # Retrieve stored eager loaded ancestors
    # or use awesome_nested_set#ancestors reduced by visibility
    def visible_ancestors(user)
      if work_package_ancestors.nil?
        self.class.aggregate_ancestors(id, user)[id]
      else
        work_package_ancestors
      end
    end
  end

  class_methods do
    def aggregate_ancestors(work_package_ids, user)
      ::WorkPackage::Ancestors::Aggregator.new(work_package_ids, user).results
    end
  end

  ##
  # Aggregate ancestor data for the given work package IDs.
  # Ancestors visible to the given user are returned, grouped by each input ID.
  class Aggregator
    attr_accessor :user, :ids

    def initialize(work_package_ids, user)
      @user = user
      @ids = work_package_ids
    end

    def results
      default = Hash.new do |hash, id|
        hash[id] = []
      end

      results = ancestors_by_work_package

      default.merge(results)
    end

    private

    def ancestors_by_work_package
      WorkPackageHierarchy
        .where(descendant_id: @ids)
        .includes(:ancestor)
        .where(ancestor: { project_id: Project.allowed_to(user, :view_work_packages) })
        .where('generations > 0')
        .order(generations: :desc)
        .group_by(&:descendant_id)
        .transform_values { |hierarchies| hierarchies.map(&:ancestor) }
    end
  end
end
