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
  mapper = WorkPackageTypes::Patterns::TokenPropertyMapper
  mapper.configure_static_attributes(context: :work_package, label_model: WorkPackage) do
    add(:id, ->(wp) { wp.id }, label: :id)
    add(:accountable, ->(wp) { wp.responsible }, label: :responsible)
    add(:assignee, ->(wp) { wp.assigned_to }, label: :assigned_to)
    add(:author, ->(wp) { wp.author }, label: :author)
    add(:category, ->(wp) { wp.category }, label: :category)
    add(:creation_date, ->(wp) { wp.created_at }, mapper::DATE, label: :created_at)
    add(:estimated_time, ->(wp) { wp.estimated_hours }, mapper::DURATION, label: :estimated_hours)
    add(:remaining_time, ->(wp) { wp.remaining_hours }, mapper::DURATION, label: :remaining_hours)
    add(:finish_date, ->(wp) { wp.due_date }, mapper::DATE, label: :due_date)
    add(:observed_in_versions, ->(wp) { wp.observed_in_versions }, mapper::ARRAY, label: :observed_in_versions)
    add(:priority, ->(wp) { wp.priority }, label: :priority)
    add(:start_date, ->(wp) { wp.start_date }, mapper::DATE, label: :start_date)
    add(:status, ->(wp) { wp.status }, label: :status)
    add(:type, ->(wp) { wp.type }, label: :type)
    add(:version, ->(wp) { wp.target_versions }, mapper::ARRAY, label: -> { Setting::WorkPackageMultipleVersions.active? ? WorkPackage.human_attribute_name(:target_versions) : WorkPackage.human_attribute_name(:version) }) # rubocop:disable Metrics/LineLength
  end

  mapper.configure_static_attributes(context: :parent, label_model: WorkPackage) do
    add(:parent_id, ->(parent) { parent.id }, label: :id)
    add(:parent_assignee, ->(parent) { parent.assigned_to }, label: :assigned_to)
    add(:parent_author, ->(parent) { parent.author }, label: :author)
    add(:parent_category, ->(parent) { parent.category }, label: :category)
    add(:parent_creation_date, ->(parent) { parent.created_at }, mapper::DATE, label: :created_at)
    add(:parent_estimated_time, ->(parent) { parent.estimated_hours }, mapper::DURATION, label: :estimated_hours)
    add(:parent_remaining_time, ->(parent) { parent.remaining_hours }, mapper::DURATION, label: :remaining_hours)
    add(:parent_finish_date, ->(parent) { parent.due_date }, mapper::DATE, label: :due_date)
    add(:parent_observed_in_versions, ->(parent) { parent.observed_in_versions }, mapper::ARRAY, label: :observed_in_versions)
    add(:parent_priority, ->(parent) { parent.priority }, label: :priority)
    add(:parent_subject, ->(parent) { parent.subject }, label: :subject)
    add(:parent_status, ->(parent) { parent.status }, label: :status)
    add(:parent_type, ->(parent) { parent.type }, label: :type)
    add(:parent_version, ->(parent) { parent.target_versions }, mapper::ARRAY, label: -> { Setting::WorkPackageMultipleVersions.active? ? WorkPackage.human_attribute_name(:target_versions) : WorkPackage.human_attribute_name(:version) }) # rubocop:disable Metrics/LineLength
  end

  mapper.configure_static_attributes(context: :project, label_model: Project) do
    add(:project_id, ->(project) { project.id }, label: :id)
    add(:project_active, ->(project) { project.active? }, label: :active)
    add(:project_name, ->(project) { project }, label: :name)
    add(
      :project_status,
      ->(project) { project.status_code && I18n.t("activerecord.attributes.project.status_codes.#{project.status_code}") },
      label: :status_code
    )
    add(:project_parent, ->(project) { project.parent_id }, label: :parent)
    add(:project_public, ->(project) { project.public? }, label: :public)
  end

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
