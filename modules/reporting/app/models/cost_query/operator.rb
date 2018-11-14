#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

class CostQuery::Operator < Report::Operator
  # Operators from Redmine
  new "c", arity: 0, label: :label_closed do
    def modify(query, field, *values)
      raise "wrong field" if field.to_s.split('.').last != "status_id"
      query.where "(#{Status.table_name}.is_closed = #{quoted_true})"
      query
    end
  end

  new "o", arity: 0, label: :label_open do
    def modify(query, field, *values)
      raise "wrong field" if field.to_s.split('.').last != "status_id"
      query.where "(#{Status.table_name}.is_closed = #{quoted_false})"
      query
    end
  end

  new "=_child_projects", validate: :integers, label:  :label_is_project_with_subprojects do
    def modify(query, field, *values)
      p_ids = []
      values.each do |value|
        p_ids += ([value] << Project.find(value).descendants.map{ |p| p.id })
      end
      "=".to_operator.modify query, field, p_ids
    rescue ActiveRecord::RecordNotFound
      query
    end
  end

  new "!_child_projects", validate: :integers, label:  :label_is_not_project_with_subprojects do
    def modify(query, field, *values)
      p_ids = []
      values.each do |value|
        p_ids += ([value] << Project.find(value).descendants.map{ |p| p.id })
      end
      "!".to_operator.modify query, field, p_ids
    rescue ActiveRecord::RecordNotFound
      query
    end
  end
end
