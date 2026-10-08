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

      query.where "(#{Status.table_name}.category = 'closed')"
      query
    end
  end

  new "o", arity: 0, label: :label_open do
    def modify(query, field, *_values)
      raise "wrong field" if field.to_s.split(".").last != "status_id"

      query.where "(#{Status.table_name}.category != 'closed')"
      query
    end
  end

  new "=_child_projects", validate: :integers, label: :label_is_project_with_subprojects do
    def modify(query, field, *values)
      p_ids = []
      values.each do |value|
        project = Project.visible.find(value)
        next unless project

        p_ids << project.id
        p_ids += project.descendants.pluck(:id)
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
          project = Project.visible.find(id)
          next unless project

          p_ids << project.id
          p_ids += project.descendants.pluck(:id)
        end
      end

      "!".to_operator.modify query, field, p_ids
    rescue ActiveRecord::RecordNotFound
      query
    end
  end

  new "=_child_work_packages", validate: :integers, label: :label_is_work_package_with_descendants do
    def modify(query, field, *values)
      wp_ids = []
      values.each do |value|
        work_package = WorkPackage.visible.find(value)
        next unless work_package

        wp_ids << work_package.id
        wp_ids += work_package.descendants.pluck(:id)
      end

      "=".to_operator.modify query, field, wp_ids
    rescue ActiveRecord::RecordNotFound
      query
    end
  end

  new "!_child_work_packages", validate: :integers, label: :label_is_not_work_package_with_descendants do
    def modify(query, field, *values)
      wp_ids = []
      values.each do |value|
        value.to_s.split(",").each do |id|
          work_package = WorkPackage.visible.find(id)
          next unless work_package

          wp_ids << work_package.id
          wp_ids += work_package.descendants.pluck(:id)
        end
      end

      "!".to_operator.modify query, field, wp_ids
    rescue ActiveRecord::RecordNotFound
      query
    end
  end
end
