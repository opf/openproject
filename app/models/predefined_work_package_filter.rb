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

class PredefinedWorkPackageFilter < ApplicationRecord
  include Lists::MoveAfterAnchor

  SORTABLE_LIST_TYPE = "predefined-work-package-filter"
  enum :placement, {
    project_overview: "project_overview",
    work_packages: "work_packages",
    gantt: "gantt"
  }, validate: { allow_nil: true }, scopes: false

  has_many :project_settings,
           class_name: "PredefinedWorkPackageFilterProject",
           inverse_of: :filter,
           foreign_key: :filter_id,
           dependent: :delete_all

  acts_as_list scope: [:deleted_at]

  validates :name, presence: true, unless: :builtin?
  validates :name, length: { maximum: 255 }
  validate :validate_query_properties

  scope :available, -> { where(deleted_at: nil) }
  scope :ordered, -> { order(:position, :id) }
  scope :at, ->(placement) { placements.key?(placement) ? where(placement:) : none }

  def self.active_in(project)
    ids = PredefinedWorkPackageFilterProject.where(project:).select(:filter_id)
    active = PredefinedWorkPackageFilterProject.where(project:, active: true).select(:filter_id)

    available.where(id: active).or(available.where.not(builtin_key: nil).where.not(id: ids))
  end

  def self.seed_builtin_filters!
    work_package_keys = WorkPackages::DefaultQueryGeneratorService::QUERY_OPTIONS
    gantt_keys = Gantt::DefaultQueryGeneratorService::QUERY_OPTIONS
    missing_keys = (work_package_keys | gantt_keys) - existing_builtin_keys
    return if missing_keys.empty?

    position = available.maximum(:position).to_i
    rows = missing_keys.map.with_index(position + 1) do |key, index|
      { builtin_key: key.to_s, position: index, placement: work_package_keys.include?(key) ? :work_packages : :gantt }
    end
    insert_all(rows, unique_by: :builtin_key)
  end

  def self.existing_builtin_keys
    where.not(builtin_key: nil).pluck(:builtin_key).map(&:to_sym)
  end
  private_class_method :existing_builtin_keys

  def remove!
    if builtin?
      update!(deleted_at: Time.current)
    else
      destroy!
    end
  end

  def builtin?
    builtin_key.present?
  end

  def display_name
    name.presence || (I18n.t("js.work_packages.default_queries.#{builtin_key}") if builtin?)
  end

  def active_in?(project)
    return false if deleted_at?

    setting = project_settings.find_by(project:)
    setting ? setting.active? : builtin?
  end

  def active_projects
    active = Project.active.where(id: project_settings.where(active: true).select(:project_id))
    return active unless builtin?

    active.or(Project.active.where.not(id: project_settings.select(:project_id)))
  end

  def set_active_in!(project, active:)
    PredefinedWorkPackageFilterProject.upsert(
      { filter_id: id, project_id: project.id, active: },
      unique_by: %i[filter_id project_id]
    )
  end

  private

  def validate_query_properties
    errors.add(:query_properties, :invalid) unless query_properties.is_a?(Hash)
  end
end
