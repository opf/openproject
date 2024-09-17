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
    query.join(work_packages_table).on(activity_journals_table[:work_package_id].eq(work_packages_table[:id]))
    query.join(types_table).on(work_packages_table[:type_id].eq(types_table[:id]))
  end

  def event_query_projection
    [
      activity_journal_projection_statement(:hours, "time_entry_hours"),
      activity_journal_projection_statement(:comments, "time_entry_comments"),
      activity_journal_projection_statement(:project_id, "project_id"),
      activity_journal_projection_statement(:work_package_id, "work_package_id"),
      projection_statement(projects_table, :name, "project_name"),
      projection_statement(work_packages_table, :subject, "work_package_subject"),
      projection_statement(types_table, :name, "type_name")
    ]
  end

  protected

  def event_title(event)
    time_entry_object_name = event["work_package_id"].blank? ? event["project_name"] : work_package_title(event)
  end

  def event_type(_event)
    "time-entry"
  end

  def work_package_title(event)
    Activities::WorkPackageActivityProvider.work_package_title(event["work_package_id"],
                                                               event["work_package_subject"],
                                                               event["type_name"])
  end

  def event_description(event)
    event["time_entry_description"]
  end

  def event_path(event)
    "/work_packages/#{event['work_package_id']}"
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

  def event_location(event, only_path: true)
    filter_params = if event["work_package_id"].present?
                      work_package_id_filter(event["work_package_id"])
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
