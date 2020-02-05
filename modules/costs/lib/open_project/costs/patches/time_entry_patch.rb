#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

# Patches Redmine's Users dynamically.
module OpenProject::Costs::Patches::TimeEntryPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      belongs_to :rate, -> { where(type: ['HourlyRate', 'DefaultHourlyRate']) }, class_name: 'Rate'

      before_save :update_costs

      extend ::TimeEntry::TimeEntryScopes
    end
  end

  module ClassMethods
    def update_all(updates, conditions = nil, options = {})
      # instead of a update_all, perform an individual update during work_package#move
      # to trigger the update of the costs based on new rates
      if conditions.respond_to?(:keys) && conditions.keys == [:work_package_id] && updates =~ /^project_id = ([\d]+)$/
        project_id = $1
        time_entries = TimeEntry.where(conditions)
        time_entries.each do |entry|
          entry.project_id = project_id
          entry.save!
        end
      else
        super
      end
    end
  end

  module InstanceMethods
    def real_costs
      # This methods returns the actual assigned costs of the entry
      overridden_costs || costs || calculated_costs
    end

    def calculated_costs(rate_attr = nil)
      rate_attr ||= current_rate
      hours * rate_attr.rate
    rescue
      0.0
    end

    def update_costs(rate_attr = nil)
      rate_attr ||= current_rate
      if rate_attr.nil?
        self.costs = 0.0
        self.rate = nil
        return
      end

      self.costs = calculated_costs(rate_attr)
      self.rate = rate_attr
    end

    def update_costs!(rate_attr = nil)
      update_costs(rate_attr)
      self.save!
    end

    def current_rate
      user.rate_at(spent_on, project_id)
    end

    def visible_by?(usr)
      usr.allowed_to?(:view_time_entries, project) ||
        (user_id == usr.id && usr.allowed_to?(:view_own_time_entries, project))
    end

    def costs_visible_by?(usr)
      usr.allowed_to?(:view_hourly_rates, project) ||
        (user_id == usr.id && usr.allowed_to?(:view_own_hourly_rate, project))
    end
  end
end
