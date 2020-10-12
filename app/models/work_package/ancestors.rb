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

      results = with_work_package_ancestors
                .map { |wp| [wp.id, wp.ancestors] }
                .to_h

      default.merge(results)
    end

    private

    def with_work_package_ancestors
      WorkPackage
        .where(id: @ids)
        .includes(:ancestors)
        .where(ancestors_work_packages: { project_id: Project.allowed_to(user, :view_work_packages) })
        .order(Arel.sql('relations.hierarchy DESC'))
    end
  end
end
