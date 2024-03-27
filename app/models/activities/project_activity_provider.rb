#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Activities::ProjectActivityProvider < Activities::BaseActivityProvider
  activity_provider_for type: "project_attributes",
                        permission: :view_project

  def event_query_projection
    [
      projection_statement(journals_table, :journable_id, "project_id"),
      projection_statement(projects_table, :identifier, "project_identifier"),
      projection_statement(projects_table, :name, "project_name")
    ]
  end

  protected

  # rubocop:disable Metrics/AbcSize
  def extend_event_query(query)
    enabled_custom_fields = ProjectCustomFieldProjectMapping
      .where(custom_field_mapping_table[:project_id].eq(projects_table[:id]))
      .select(:custom_field_id)
      .arel

    enabled_customizable_journals = Journal::CustomizableJournal
      .where(
        customizable_journals_table[:journal_id].eq(journals_table[:id])
        .and(customizable_journals_table[:custom_field_id].in(enabled_custom_fields))
      )
      .arel
      .exists

    no_customizable_journals = Journal::CustomizableJournal
      .where(customizable_journals_table[:journal_id].eq(journals_table[:id]))
      .arel
      .exists.not

    # Filter out the journals that contain only disabled custom field changes,
    # journals with no custom fields or with enabled custom fields changes are returned.
    # This filtering is necessary for 2 reasons:
    #   1. The disabled fields will be filtered out in the ActivityEagerLoadingWrapper, which can
    #      lead to displaying empty journals, if only a disabled custom field change is journaled.
    #   2. The empty journals cannot be dropped in the ActivityEagerLoadingWrapper, because
    #      that would lead to not respecting the limit parameter. For example, if the results
    #      are limited to 10 journals and 1 empty journal is dropped, then the number of
    #      returned journals would be 9 instead of 10.
    #      To avoid this issue, the journals that have only disabled custom field changes
    #      should be excluded from the query.
    #
    # TODO: Handle the case when the project title is changed alongside a disabled custom field.
    query.where(enabled_customizable_journals.or(no_customizable_journals))
  end
  # rubocop:enable Metrics/AbcSize

  def projects_reference_table
    journals_table
  end

  def project_id_reference_field
    "journable_id"
  end

  def event_title(event)
    I18n.t("events.title.project", name: event["project_name"])
  end

  def event_path(event)
    url_helpers.project_path(event["project_identifier"])
  end

  def event_url(event)
    url_helpers.project_url(event["project_identifier"])
  end

  def customizable_journals_table
    @customizable_journals_table ||= Journal::CustomizableJournal.arel_table
  end

  def custom_field_mapping_table
    @custom_field_mapping_table ||= ProjectCustomFieldProjectMapping.arel_table
  end
end
