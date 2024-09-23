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

class CostQuery::Operator < Report::Operator
  # Operators from Redmine
  new "c", arity: 0, label: :label_closed do
    def modify(query, field, *_values)
      raise "wrong field" if field.to_s.split(".").last != "status_id"

      query.where "(#{Status.table_name}.is_closed = #{quoted_true})"
      query
    end
  end

  new "o", arity: 0, label: :label_open do
    def modify(query, field, *_values)
      raise "wrong field" if field.to_s.split(".").last != "status_id"

      query.where "(#{Status.table_name}.is_closed = #{quoted_false})"
      query
    end
  end

  new "=_child_projects", validate: :integers, label: :label_is_project_with_subprojects do
    def modify(query, field, *values)
      p_ids = []
      values.each do |value|
        p_ids += ([value] << Project.find(value).descendants.map(&:id))
      end
      "=".to_operator.modify query, field, p_ids
    rescue ActiveRecord::RecordNotFound
      query
    end
  end

  new "!_child_projects", validate: :integers, label: :label_is_not_project_with_subprojects do
    def modify(query, field, *values)
      p_ids = []
      values.each do |value|
        value.to_s.split(",").each do |id|
          p_ids += ([id] << Project.find(id).descendants.map(&:id))
        end
      end
      "!".to_operator.modify query, field, p_ids
    rescue ActiveRecord::RecordNotFound
      query
    end
  end
end
