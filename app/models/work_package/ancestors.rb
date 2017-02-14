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

module WorkPackage::Ancestors
  extend ActiveSupport::Concern

  included do
    attr_accessor :work_package_ancestors

    ##
    # Retrieve stored eager loaded ancestors
    # or use awesome_nested_set#ancestors reduced by visibility
    def visible_ancestors(user)
      if work_package_ancestors.nil?
        WorkPackage.visible(user).merge(ancestors)
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
      with_work_package_ancestors.group_by(&:leaf_id)
    end

    private

    def with_work_package_ancestors
      query = join_ancestors(wp_table)

      WorkPackage.joins(query.join_sources)
                 .select("#{wp_table.name}.id AS leaf_id")
                 .select('ancestors.*')
                 .order('ancestors.lft ASC')
    end

    def join_ancestors(select)
      select
        .join(wp_ancestors)
        .on(ancestors_condition)
    end

    def ancestors_condition
      nested_set_root_condition
        .and(allowed_to_view_work_packages)
        .and(nested_set_lft_condition)
        .and(nested_set_rgt_condition)
        .and(in_given_work_packages)
    end

    def in_given_work_packages
      wp_table[:id].in(ids)
    end

    def allowed_to_view_work_packages
      wp_ancestors[:project_id].in(
        Project.allowed_to(user, :view_work_packages).select(:id).arel
      )
    end

    def nested_set_root_condition
      wp_ancestors[:root_id].eq(wp_table[:root_id])
    end

    def nested_set_lft_condition
      wp_ancestors[:lft].lt(wp_table[:lft])
    end

    def nested_set_rgt_condition
      wp_ancestors[:rgt].gt(wp_table[:rgt])
    end

    def wp_table
      @wp_table ||= WorkPackage.arel_table
    end

    def wp_ancestors
      @wp_ancestors ||= wp_table.alias('ancestors')
    end
  end
end
