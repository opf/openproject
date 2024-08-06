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

class TimeEntryActivity < Enumeration
  include ::Scopes::Scoped

  has_many :time_entries, foreign_key: "activity_id"
  has_many :time_entry_activities_projects, foreign_key: "activity_id", dependent: :delete_all

  validates :parent, absence: true

  OptionName = :enumeration_activities

  scopes :active_in_project

  def option_name
    OptionName
  end

  def objects_count
    time_entries.count
  end

  def transfer_relations(to)
    time_entries.update_all(activity_id: to.id)
  end

  def active_in_project?(project)
    teap = if time_entry_activities_projects.loaded?
             detect_project_time_entry_activity_active_state(project)
           else
             pluck_project_time_entry_activity_active_state(project)
           end

    (!teap.nil? && teap) || (teap.nil? && active?)
  end

  def activated_projects
    Project.activated_time_activity(self)
  end

  private

  def detect_project_time_entry_activity_active_state(project)
    time_entry_activities_projects.detect { |t| t.project_id == project.id }&.active?
  end

  def pluck_project_time_entry_activity_active_state(project)
    time_entry_activities_projects
      .where(project_id: project.id)
      .pluck(:active)
      .first
  end
end
