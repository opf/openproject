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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

Rails.application.config.to_prepare do
  # rubocop:disable Layout/LineLength
  mapper = WorkPackageTypes::Patterns::TokenPropertyMapper
  mapper.add_static_attribute(:id, :work_package, -> { WorkPackage.human_attribute_name(:id) }, ->(wp) { wp.id })
  mapper.add_static_attribute(:accountable, :work_package, -> { WorkPackage.human_attribute_name(:responsible) }, ->(wp) { wp.responsible })
  mapper.add_static_attribute(:assignee, :work_package, -> { WorkPackage.human_attribute_name(:assigned_to) }, ->(wp) { wp.assigned_to })
  mapper.add_static_attribute(:author, :work_package, -> { WorkPackage.human_attribute_name(:author) }, ->(wp) { wp.author })
  mapper.add_static_attribute(:category, :work_package, -> { WorkPackage.human_attribute_name(:category) }, ->(wp) { wp.category })
  mapper.add_static_attribute(:creation_date, :work_package, -> { WorkPackage.human_attribute_name(:created_at) }, ->(wp) { wp.created_at }, mapper::DATE)
  mapper.add_static_attribute(:estimated_time, :work_package, -> { WorkPackage.human_attribute_name(:estimated_hours) }, ->(wp) { wp.estimated_hours }, mapper::DURATION)
  mapper.add_static_attribute(:remaining_time, :work_package, -> { WorkPackage.human_attribute_name(:remaining_hours) }, ->(wp) { wp.remaining_hours }, mapper::DURATION)
  mapper.add_static_attribute(:finish_date, :work_package, -> { WorkPackage.human_attribute_name(:due_date) }, ->(wp) { wp.due_date }, mapper::DATE)
  mapper.add_static_attribute(:observed_in_versions, :work_package, -> { WorkPackage.human_attribute_name(:observed_in_versions) }, ->(wp) { wp.observed_in_versions }, mapper::ARRAY)
  mapper.add_static_attribute(:priority, :work_package, -> { WorkPackage.human_attribute_name(:priority) }, ->(wp) { wp.priority })
  mapper.add_static_attribute(:start_date, :work_package, -> { WorkPackage.human_attribute_name(:start_date) }, ->(wp) { wp.start_date }, mapper::DATE)
  mapper.add_static_attribute(:status, :work_package, -> { WorkPackage.human_attribute_name(:status) }, ->(wp) { wp.status })
  mapper.add_static_attribute(:type, :work_package, -> { WorkPackage.human_attribute_name(:type) }, ->(wp) { wp.type })
  mapper.add_static_attribute(:version, :work_package, -> { Setting::WorkPackageMultipleVersions.active? ? WorkPackage.human_attribute_name(:target_versions) : WorkPackage.human_attribute_name(:version) }, ->(wp) { wp.target_versions }, mapper::ARRAY)

  mapper.add_static_attribute(:parent_id, :parent, -> { WorkPackage.human_attribute_name(:id) }, ->(parent) { parent.id })
  mapper.add_static_attribute(:parent_assignee, :parent, -> { WorkPackage.human_attribute_name(:assigned_to) }, ->(parent) { parent.assigned_to })
  mapper.add_static_attribute(:parent_author, :parent, -> { WorkPackage.human_attribute_name(:author) }, ->(parent) { parent.author })
  mapper.add_static_attribute(:parent_category, :parent, -> { WorkPackage.human_attribute_name(:category) }, ->(parent) { parent.category })
  mapper.add_static_attribute(:parent_creation_date, :parent, -> { WorkPackage.human_attribute_name(:created_at) }, ->(parent) { parent.created_at }, mapper::DATE)
  mapper.add_static_attribute(:parent_estimated_time, :parent, -> { WorkPackage.human_attribute_name(:estimated_hours) }, ->(parent) { parent.estimated_hours }, mapper::DURATION)
  mapper.add_static_attribute(:parent_remaining_time, :parent, -> { WorkPackage.human_attribute_name(:remaining_hours) }, ->(parent) { parent.remaining_hours }, mapper::DURATION)
  mapper.add_static_attribute(:parent_finish_date, :parent, -> { WorkPackage.human_attribute_name(:due_date) }, ->(parent) { parent.due_date }, mapper::DATE)
  mapper.add_static_attribute(:parent_observed_in_versions, :parent, -> { WorkPackage.human_attribute_name(:observed_in_versions) }, ->(parent) { parent.observed_in_versions }, mapper::ARRAY)
  mapper.add_static_attribute(:parent_priority, :parent, -> { WorkPackage.human_attribute_name(:priority) }, ->(parent) { parent.priority })
  mapper.add_static_attribute(:parent_subject, :parent, -> { WorkPackage.human_attribute_name(:subject) }, ->(parent) { parent.subject })
  mapper.add_static_attribute(:parent_status, :parent, -> { WorkPackage.human_attribute_name(:status) }, ->(parent) { parent.status })
  mapper.add_static_attribute(:parent_type, :parent, -> { WorkPackage.human_attribute_name(:type) }, ->(parent) { parent.type })
  mapper.add_static_attribute(:parent_version, :parent, -> { Setting::WorkPackageMultipleVersions.active? ? WorkPackage.human_attribute_name(:target_versions) : WorkPackage.human_attribute_name(:version) }, ->(parent) { parent.target_versions }, mapper::ARRAY)

  mapper.add_static_attribute(:project_id, :project, -> { Project.human_attribute_name(:id) }, ->(project) { project.id })
  mapper.add_static_attribute(:project_active, :project, -> { Project.human_attribute_name(:active) }, ->(project) { project.active? })
  mapper.add_static_attribute(:project_name, :project, -> { Project.human_attribute_name(:name) }, ->(project) { project })
  mapper.add_static_attribute(:project_status, :project, -> { Project.human_attribute_name(:status_code) }, ->(project) { project.status_code && I18n.t("activerecord.attributes.project.status_codes.#{project.status_code}") })
  mapper.add_static_attribute(:project_parent, :project, -> { Project.human_attribute_name(:parent) }, ->(project) { project.parent_id })
  mapper.add_static_attribute(:project_public, :project, -> { Project.human_attribute_name(:public) }, ->(project) { project.public? })
  # rubocop:enable Layout/LineLength

  mapper.add_custom_fields(->(variant) {
    all_wp_cfs = WorkPackageCustomField.where.not(field_format: %w[text link empty]).order(:name)
    if variant
      all_wp_cfs.merge(variant.custom_fields)
    else
      all_wp_cfs
    end
  }, :work_package)

  mapper.add_custom_fields(->(_) {
    ProjectCustomField.where.not(field_format: %w[text link empty]).where(admin_only: false, multi_value: false).order(:name)
  }, :project, "project_")

  mapper.add_custom_fields(
    ->(_) { WorkPackageCustomField.where.not(field_format: %w[text link empty]).order(:name) }, :parent, "parent_"
  )
end
