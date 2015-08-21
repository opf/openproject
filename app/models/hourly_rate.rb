#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

class HourlyRate < Rate
  validates_uniqueness_of :valid_from, scope: [:user_id, :project_id]
  validates_presence_of :user_id, :project_id, :valid_from
  validate :change_of_user_only_on_first_creation

  def previous(reference_date = valid_from)
    # This might return a default rate
    user.rate_at(reference_date - 1, project)
  end

  def next(reference_date = valid_from)
    HourlyRate.find(
      :first,
      conditions: ['user_id = ? and project_id = ? and valid_from > ?',
                   user_id, project_id, reference_date],
      order: 'valid_from ASC'
    )
  end

  def self.history_for_user(usr, check_permissions = true)
    rates = Hash.new
    Project.has_module(:costs_module).active.visible.each do |project|
      next if check_permissions && !User.current.allowed_to?(:view_hourly_rates, project, for_user: usr)

      rates[project] = HourlyRate
                       .where(user_id: usr, project_id: project)
                       .order("#{HourlyRate.table_name}.valid_from desc")
    end

    # FIXME: What permissions to apply here?
    rates[nil] = DefaultHourlyRate
                 .where(user_id: usr)
                 .order("#{DefaultHourlyRate.table_name}.valid_from desc")

    rates
  end

  def self.at_date_for_user_in_project(date, user_id, project = nil, include_default = true)
    user_id = user_id.id if user_id.is_a?(User)

    unless project.nil?
      rate = where(['user_id = ? and project_id = ? and valid_from <= ?', user_id, project, date])
             .order('valid_from DESC')
             .first
      if rate.nil?
        project = Project.find(project) unless project.is_a?(Project)
        rate = where(['user_id = ? and project_id in (?) and valid_from <= ?',
                      user_id,
                      project.ancestors.to_a,
                      date])
               .includes(:project)
               .order('projects.lft DESC, valid_from DESC')
               .first
      end
    end
    rate ||= DefaultHourlyRate.at_for_user(date, user_id) if include_default
    rate
  end

  private

  def change_of_user_only_on_first_creation
    # Only allow change of project and user on first creation
    return if self.new_record?

    errors.add :project_id, :invalid if project_id_changed?
    errors.add :user_id, :invalid if user_id_changed?
  end
end
