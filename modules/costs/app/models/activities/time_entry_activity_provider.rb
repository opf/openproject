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

class Activities::TimeEntryActivityProvider < Activities::BaseActivityProvider
  activity_provider_for type: "time_entries",
                        permission: :view_time_entries

  def extend_event_query(query)
    query.outer_join(work_packages_table).on(work_package_join_condition)
    query.outer_join(meetings_table).on(meeting_join_condition)
    query.outer_join(types_table).on(work_packages_table[:type_id].eq(types_table[:id]))
  end

  def event_query_projection
    [
      activity_journal_projection_statement(:hours, "time_entry_hours"),
      activity_journal_projection_statement(:comments, "time_entry_comments"),
      activity_journal_projection_statement(:project_id, "project_id"),
      activity_journal_projection_statement(:entity_type, "entity_type"),
      activity_journal_projection_statement(:entity_id, "entity_id"),
      projection_statement(projects_table, :name, "project_name"),
      projection_statement(work_packages_table, :subject, "work_package_subject"),
      projection_statement(work_packages_table, :identifier, "work_package_identifier"),
      projection_statement(meetings_table, :title, "meeting_title"),
      projection_statement(types_table, :name, "type_name")
    ]
  end

  protected

  def work_package_join_condition
    activity_journals_table[:entity_type].eq("WorkPackage").and(
      activity_journals_table[:entity_id].eq(work_packages_table[:id])
    )
  end

  def meeting_join_condition
    activity_journals_table[:entity_type].eq("Meeting").and(
      activity_journals_table[:entity_id].eq(meetings_table[:id])
    )
  end

  def event_title(event)
    event["entity_id"].blank? ? event["project_name"] : entity_title(event)
  end

  def event_type(_event)
    "time-entry"
  end

  def entity_title(event)
    if event["entity_type"] == "WorkPackage"
      Activities::WorkPackageActivityProvider.work_package_title(event["entity_id"],
                                                                 event["work_package_subject"],
                                                                 event["type_name"],
                                                                 event["work_package_identifier"])
    elsif event["entity_type"] == "Meeting"
      event["meeting_title"]
    end
  end

  def event_description(event)
    event["time_entry_description"]
  end

  def event_path(event)
    case event["entity_type"]
    when "WorkPackage" then "/work_packages/#{event['entity_id']}"
    when "Meeting" then "/meetings/#{event['entity_id']}"
    end
  end

  def event_url(event)
    event_location(event, only_path: false)
  end

  def types_table
    @types_table = Type.arel_table
  end

  def work_packages_table
    @work_packages_table ||= WorkPackage.arel_table
  end

  def meetings_table
    @meetings_table ||= Meeting.arel_table
  end

  def event_location(event, only_path: true)
    filter_params = if event["entity_type"] == "WorkPackage"
                      work_package_id_filter(event["entity_id"])
                      # TODO: Add meeting here?
                    else
                      project_id_filter(event["project_id"])
                    end

    url_helpers.cost_reports_url(event["project_id"], only_path:, **filter_params)
  end

  def project_id_filter(project_id)
    { "fields[]": "ProjectId", "operators[ProjectId]": "=", "values[ProjectId]": project_id, set_filter: 1 }
  end

  def work_package_id_filter(work_package_id)
    { "fields[]": "WorkPackageId", "operators[WorkPackageId]": "=", "values[WorkPackageId]": work_package_id, set_filter: 1 }
  end
end
