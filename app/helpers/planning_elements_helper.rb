#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module PlanningElementsHelper
  def render_planning_element(api, planning_element)
    api.planning_element(planning_element.destroyed? ? {:destroyed => true} : {}) do
      api.id(planning_element.id)

      api.project(:id => planning_element.project.id,
                  :identifier => planning_element.project.identifier,
                  :name => planning_element.project.name)

      api.name(planning_element.subject)

      api.description(planning_element.description)

      api.start_date(planning_element.start_date.to_formatted_s(:db)) unless planning_element.start_date.nil?
      api.end_date(planning_element.due_date.to_formatted_s(:db)) unless planning_element.due_date.nil?

      api.in_trash(!!planning_element.deleted_at)

      if planning_element.parent
        api.parent(:id => planning_element.parent_id, :name => planning_element.parent.subject)
      end

      if planning_element.children.present?
        api.array(:children, :size => planning_element.children.size) do
          planning_element.children.each do |child|
            api.child(:id => child.id, :name => child.subject)
          end
        end
      end

      if planning_element.responsible
        api.responsible(:id => planning_element.responsible.id, :name => planning_element.responsible.name)
      end

      if planning_element.type
        type = planning_element.type
        api.planning_element_type(:id => type.id, :name => type.name)
      end

      if planning_element.planning_element_status
        status = planning_element.planning_element_status
        api.planning_element_status(:id => status.id, :name => status.name)
      end

      api.planning_element_status_comment(planning_element.planning_element_status_comment)

      if include_journals?
        api.array :journals, :size => planning_element.journals.size do
          planning_element.journals.each do |journal|
            render(:partial => '/api/v2/planning_element_journals/journal.api',
                   :object  => journal)
          end
        end
      end

      api.created_at(planning_element.created_at.utc) if planning_element.created_at
      api.updated_at(planning_element.updated_at.utc) if planning_element.updated_at
    end
  end

  def user_friendly_change(journal, attribute)
    # unfortunately there is currently no public method for retreiving
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
