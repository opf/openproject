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

module OpenProject::Costs::Patches::UserPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      has_many :rates, class_name: 'HourlyRate'
      has_many :default_rates, class_name: 'DefaultHourlyRate'

      before_save :save_rates
    end
  end

  module InstanceMethods
    def allowed_to_condition_with_project_id(permission, projects = nil)
      scope = Project.allowed_to(self, permission)
      scope = scope.where(id: projects) if projects

      ids = scope.pluck(:id)

      ids.empty? ?
        '1=0' :
        "(#{Project.table_name}.id in (#{ids.join(', ')}))"
    end

    def current_rate(project = nil, include_default = true)
      rate_at(Date.today, project, include_default)
    end

    # kept for backwards compatibility
    def rate_at(date, project = nil, include_default = true)
      ::HourlyRate.at_date_for_user_in_project(date, id, project, include_default)
    end

    def current_default_rate
      ::DefaultHourlyRate.at_for_user(Date.today, id)
    end

    # kept for backwards compatibility
    def default_rate_at(date)
      ::DefaultHourlyRate.at_for_user(date, id)
    end

    def add_rates(project, rate_attributes)
      # set project to nil to set the default rates

      return unless rate_attributes

      rate_attributes.each do |_index, attributes|
        attributes[:rate] = Rate.parse_number_string(attributes[:rate])

        if project.nil?
          default_rates.build(attributes)
        else
          attributes[:project] = project
          rates.build(attributes)
        end
      end
    end

    def set_existing_rates(project, rates_attributes)
      if project.nil?
        default_rates.reject(&:new_record?).each do |rate|
          update_rate(rate, rates_attributes[rate.id.to_s], false)
        end
      else
        rates.reject { |r| r.new_record? || r.project_id != project.id }.each do |rate|
          update_rate(rate, rates_attributes[rate.id.to_s], true)
        end
      end
    end

    def save_rates
      (default_rates + rates).each do |rate|
        throw :abort if !rate.save
      end
    end

    private

    def update_rate(rate, attributes, project_rate = true)
      if attributes && attributes[:rate].present?
        attributes[:rate] = Rate.parse_number_string(attributes[:rate])
        rate.attributes = attributes
      else
        # TODO: this is surprising
        #       as it actually deletes the rate right away
        #       as opposed to the behaviour when changing the attributes
        project_rate ? rates.delete(rate) : default_rates.delete(rate)
      end
    end
  end
end
