# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class WorkPackage::Exports::StatusReportJson
  def initialize(work_package, current_user:)
    @work_package = work_package
    @current_user = current_user
    @data = WorkPackage::Exports::StatusReportData.new(work_package, current_user:)
  end

  def filename = "status-report-#{work_package.id}.json"

  def export
    {
      format: "openreport",
      formatVersion: "0.1",
      source: { system: "OpenProject", namespace: "urn:uuid:#{Setting.installation_uuid}" },
      project: project_data,
      report: report_data,
      sections: sections
    }
  end

  private

  attr_reader :work_package, :current_user, :data

  delegate :project, to: :work_package

  def project_data
    {
      id: project.id.to_s,
      identifier: project.identifier,
      name: project.name,
      description: project.description,
      status: project.status_code,
      progressPercent: project.progress_percent,
      attributes: project_attributes
    }
  end

  def project_attributes
    return [] unless current_user.allowed_in_project?(:view_project_attributes, project)

    fields = project.available_custom_fields_for_variant(work_package.type_variant.id)
    custom_attributes(project, fields)
  end

  def report_data
    {
      id: work_package.id.to_s,
      identifier: work_package.display_id.to_s,
      title: work_package.subject,
      period: period,
      workflowStatus: reference(work_package.status),
      summary: work_package.description,
      attributes: custom_attributes(work_package, report_fields)
    }
  end

  def period
    { start: work_package.start_date&.iso8601, end: work_package.due_date&.iso8601 }
  end

  def report_fields
    keys = work_package.type_variant.attribute_groups.grep(Type::AttributeGroup)
                       .flat_map { |group| group.active_members(project) }
    custom_field_ids = keys.filter_map do |key|
      CustomField.id_from_attribute_name(key) if CustomField.custom_field_attribute?(key)
    end
    work_package.available_custom_fields.select { |field| custom_field_ids.include?(field.id) }
  end

  def sections
    data.query_groups.map do |group|
      {
        id: group.key.to_s,
        name: group.title,
        items: data.related_work_packages(group).map { |item| related_item(item, group.query) }
      }
    end
  end

  def related_item(item, query)
    {
      id: item.id.to_s,
      identifier: item.display_id.to_s,
      title: item.subject,
      type: reference(item.type),
      workflowStatus: reference(item.status),
      startDate: item.start_date&.iso8601,
      dueDate: item.due_date&.iso8601,
      attributes: custom_attributes(item, related_fields(item, query))
    }
  end

  def related_fields(item, query)
    columns = query.columns.map { |column| column.name.to_s }
    item.available_custom_fields.select { |field| columns.include?(field.column_name) }
  end

  def custom_attributes(object, fields)
    fields.filter_map do |field|
      value = encode_value(object.typed_custom_value_for(field))
      next if value.nil? || value == []

      { id: field.id.to_s, name: field.name, fieldType: field.field_format, value: }
    end
  end

  def encode_value(value)
    case value
    when Array then value.filter_map { |entry| encode_value(entry) }
    when Group then reference(value).merge(kind: "group")
    when User then reference(value).merge(kind: "person")
    when Version then reference(value).merge(kind: "version")
    when CustomField::Hierarchy::Item then { id: value.id.to_s, name: value.label, kind: "hierarchyItem" }
    when Date, Time, ActiveSupport::TimeWithZone then value.iso8601
    when String, Numeric, true, false then value
    end
  end

  def reference(record)
    { id: record.id.to_s, name: record.name }
  end
end
