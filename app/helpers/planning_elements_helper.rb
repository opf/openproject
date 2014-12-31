#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module PlanningElementsHelper
  def render_planning_element(api, planning_element)
    api.planning_element(planning_element.destroyed? ? { destroyed: true } : {}) do
      api.id(planning_element.id)

      api.project(id: planning_element.project.id,
                  identifier: planning_element.project.identifier,
                  name: planning_element.project.name)

      api.subject(planning_element.subject)

      api.description(planning_element.description)

      api.start_date(planning_element.start_date.to_formatted_s(:db)) unless planning_element.start_date.nil?
      api.due_date(planning_element.due_date.to_formatted_s(:db)) unless planning_element.due_date.nil?

      if planning_element.parent
        api.parent(id: planning_element.parent_id, subject: planning_element.parent.subject)
      end

      if planning_element.children.present?
        api.array(:children, size: planning_element.children.size) do
          planning_element.children.each do |child|
            api.child(id: child.id, subject: child.subject)
          end
        end
      end

      if planning_element.responsible
        api.responsible(id: planning_element.responsible.id, name: planning_element.responsible.name)
      end

      if planning_element.type && !planning_element.type.is_standard?
        type = planning_element.type
        api.planning_element_type(id: type.id, name: type.name)
      end

      if planning_element.status
        status = planning_element.status
        api.planning_element_status(id: status.id, name: status.name)
      end

      if include_journals?
        api.array :journals, size: planning_element.journals.size do
          planning_element.journals.each do |journal|
            render(partial: '/api/v2/planning_element_journals/journal.api',
                   object:  journal)
          end
        end
      end

      api.created_at(planning_element.created_at.utc) if planning_element.created_at
      api.updated_at(planning_element.updated_at.utc) if planning_element.updated_at

      render partial: '/api/v2/custom_fields/deprecated_values.api',
             locals: { values: planning_element.custom_field_values }
    end
  end

  def user_friendly_change(journal, attribute)
    # unfortunately there is currently no public method for retrieving
    # human friendly:
    # + label
    # + old value
    # + new value
    # hence we hack our way in

    formatter = journal.formatter_instance(attribute)

    formatter.send(:format_details,
                   attribute,
                   journal.changed_data[attribute])
  end
end
