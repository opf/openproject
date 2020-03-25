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

require Rails.root.join('config/constants/project_activity')

module Projects::Activity
  def self.included(base)
    base.send :extend, ActivityScopes
  end

  module ActivityScopes
    def register_latest_project_activity(on:, chain: [], attribute:)
      Constants::ProjectActivity.register(on: on,
                                          chain: chain,
                                          attribute: attribute)
    end

    def latest_project_activity
      @latest_project_activity ||=
        Constants::ProjectActivity.registered.map do |params|
          build_latest_project_activity_for(on: params[:on].constantize,
                                            chain: Array(params[:chain]).map(&:constantize),
                                            attribute: params[:attribute])
        end
    end

    def with_latest_activity
      Project
        .select('projects.*')
        .select('activity.latest_activity_at')
        .joins("LEFT JOIN (#{latest_activity_sql}) activity ON projects.id = activity.project_id")
    end

    def latest_activity_sql
      <<-SQL
        SELECT project_id, MAX(updated_at) latest_activity_at
        FROM (#{all_activity_provider_union_sql}) activity
        GROUP BY project_id
      SQL
    end

    def all_activity_provider_union_sql
      latest_project_activity.join(' UNION ALL ')
    end

    def build_latest_project_activity_for(on:, chain:, attribute:)
      join_chain = Array(chain).dup.push(on)
      from = join_chain.first

      joins = build_joins_from_chain(join_chain)

      <<-SQL
        SELECT project_id, MAX(#{on.table_name}.#{attribute}) updated_at
        FROM #{from.table_name}
        #{joins.join(' ')}
        WHERE #{on.table_name}.#{attribute} IS NOT NULL
        GROUP BY project_id
      SQL
    end

    def build_joins_from_chain(join_chain)
      joins = []

      (0..join_chain.length - 2).each do |i|
        joins << build_join(join_chain[i + 1],
                            join_chain[i])
      end

      joins
    end

    def build_join(right, left)
      associations = right.reflect_on_all_associations
      association = associations.detect { |a| a.class_name == left.to_s }

      <<-SQL
        LEFT OUTER JOIN #{right.table_name}
        ON #{left.table_name}.id =
           #{right.table_name}.#{association.foreign_key}
      SQL
    end
  end
end
