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

module Costs
  module HasRates
    extend ActiveSupport::Concern

    included do
      # Rates deliberately outlive the principal: they are kept so already
      # booked costs stay explainable, and read back as the deleted user.
      # rubocop:disable Rails/HasManyOrHasOneDependent
      has_many :rates, class_name: "HourlyRate", foreign_key: :user_id, inverse_of: :principal
      has_many :default_rates, class_name: "DefaultHourlyRate", foreign_key: :user_id, inverse_of: :principal
      # rubocop:enable Rails/HasManyOrHasOneDependent

      before_save :save_rates
    end

    def current_rate(project = nil, include_default: true)
      rate_at(Time.zone.today, project, include_default:)
    end

    # kept for backwards compatibility
    def rate_at(date, project = nil, include_default: true)
      ::HourlyRate.at_date_for_user_in_project(date, id, project, include_default:)
    end

    def current_default_rate
      ::DefaultHourlyRate.at_for_user(Time.zone.today, id)
    end

    # kept for backwards compatibility
    def default_rate_at(date)
      ::DefaultHourlyRate.at_for_user(date, id)
    end

    def add_rates(project, rate_attributes)
      # set project to nil to set the default rates

      return unless rate_attributes

      rate_attributes.each_value do |attributes|
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
      persisted_rates_for(project).each do |rate|
        update_rate(rate, rates_attributes[rate.id.to_s], project_rate: project.present?)
      end
    end

    def save_rates
      (default_rates + rates).each do |rate|
        throw :abort if !rate.save
      end
    end

    private

    def persisted_rates_for(project)
      if project.nil?
        default_rates.reject(&:new_record?)
      else
        rates.reject { |rate| rate.new_record? || rate.project_id != project.id }
      end
    end

    def update_rate(rate, attributes, project_rate: true)
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
