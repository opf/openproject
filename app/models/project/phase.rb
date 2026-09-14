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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Project::Phase < ApplicationRecord
  include ::Scopes::Scoped

  belongs_to :project, optional: false, inverse_of: :available_phases
  belongs_to :definition,
             optional: false,
             class_name: "Project::PhaseDefinition"
  has_many :work_packages,
           through: :definition

  validate :validate_date_range

  delegate :name,
           :position,
           :start_gate_name,
           :finish_gate_name,
           :start_gate?,
           :finish_gate?,
           to: :definition

  attr_readonly :definition_id

  scope :active, -> { where(active: true) }
  scope :with_timeline_content, -> {
    joins(:definition).where(
      "(project_phases.start_date IS NOT NULL AND project_phases.finish_date IS NOT NULL) OR " \
      "(project_phase_definitions.start_gate = TRUE AND project_phases.start_date IS NOT NULL) OR " \
      "(project_phase_definitions.finish_gate = TRUE AND project_phases.finish_date IS NOT NULL)"
    )
  }
  scopes :order_by_position,
         :covering_dates_or_days_of_week

  class << self
    def visible(user = User.current)
      allowed_projects = Project.allowed_to(user, :view_project_phases)
      active.where(project: allowed_projects)
    end
  end

  def any_date_set?
    start_date? || finish_date?
  end

  def date_range_set?
    start_date? && finish_date?
  end

  def date_range_not_set?
    !date_range_set?
  end

  def validate_date_range
    if date_range_set? && (start_date > finish_date)
      if finish_date_changed?
        errors.add(:finish_date, :must_be_after_start_date)
      else
        errors.add(:start_date, :must_be_before_finish_date)
      end
    end
  end

  def calculate_duration
    return nil unless date_range_set?

    Day.working.from_range(from: start_date, to: finish_date).count
  end

  def default_start_date
    return @default_start_date if defined?(@default_start_date)

    previous_finish_date = previous_phase.finish_date if follows_previous_phase?
    @default_start_date = previous_finish_date && Day.next_working(from: previous_finish_date).date
  end

  def previous_phases
    @previous_phases ||= project.available_phases.select { it.position < position }
  end

  def previous_phase
    previous_phases.last
  end

  def follows_previous_phase?
    !!previous_phase&.date_range_set?
  end

  def following_phases
    @following_phases ||= project.available_phases.select { it.position > position }
  end

  def to_s; name end
end
