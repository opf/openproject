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

class Rate < ApplicationRecord
  validates_numericality_of :rate, allow_nil: false
  validate :validate_date_is_a_date

  before_save :convert_valid_from_to_date

  after_destroy :update_costs
  after_update :rate_updated
  after_create :rate_created

  belongs_to :user
  include ::Costs::DeletedUserFallback
  belongs_to :project

  include ActiveModel::ForbiddenAttributesProtection

  extend Costs::NumberHelper

  private

  def convert_valid_from_to_date
    self.valid_from &&= valid_from.to_date
  end

  def validate_date_is_a_date
    valid_from.to_date
  rescue Exception
    errors.add :valid_from, :not_a_date
  end

  def update_costs
    entry_class = is_a?(HourlyRate) ? TimeEntry : CostEntry
    entry_class.where(rate_id: id).each(&:update_costs!)
  end

  def rate_created
    o = Methods.new(self)

    next_rate = self.next
    # get entries from the current project
    entries = o.find_entries(valid_from, next_rate&.valid_from)

    # and entries from subprojects that need updating (only applies to hourly_rates)
    entries += o.orphaned_child_entries(valid_from, next_rate&.valid_from)

    o.update_entries(entries)
  end

  def rate_updated
    o = Methods.new(self)

    unless saved_change_to_valid_from?
      # We have not moved a rate, maybe just changed the rate value

      return unless saved_change_to_rate?

      # Only the rate value was changed so just update the currently assigned entries
      return rate_created
    end

    # We have definitely moved the rate
    if o.count_rates(valid_from_before_last_save, valid_from) > 0
      # We have passed the boundary of another rate
      # We do essantially the same as deleting the old rate and adding a new one

      # So first assign all entries from the old a new rate
      update_costs

      # Now update the newly assigned entries
      rate_created
    else
      # We have only moved the rate without passing other rates
      # So we have to either assign some entries to our previous rate (if moved forwards)
      # or assign some entries to self (if moved backwards)

      # get entries from the current project
      entries = o.find_entries(valid_from_was, valid_from)
      # and entries from subprojects that need updating (only applies to hourly_rates)
      entries += o.child_entries(valid_from_was, valid_from)

      o.update_entries(entries, valid_from_was < valid_from ? previous : self)
    end
  end

  class Methods
    def initialize(changed_rate)
      @rate = changed_rate
    end

    # order the dates
    def order_dates(*dates)
      dates.compact!
      dates.size == 1 ? dates.first : dates.sort
    end

    def conditions_after(date, date_column = :spent_on)
      if @rate.is_a?(HourlyRate)
        [
          "#{date_column} >= ? AND user_id = ? and project_id = ?",
          date, @rate.user_id, @rate.project_id
        ]
      else
        [
          "#{date_column} >= ? AND cost_type_id = ?",
          date, @rate.cost_type_id
        ]
      end
    end

    def conditions_between(date1, date2 = nil, date_column = :spent_on)
      # if the second date is not given, return all entries
      # with a spent_on after the given date
      return conditions_after(date1 || date2, date_column) if date1.nil? || date2.nil?

      (date1, date2) = order_dates(date1, date2)

      # return conditions for all entries between date1 and date2 - 1 day
      if @rate.is_a?(HourlyRate)
        { date_column => date1..(date2 - 1),
          user_id: @rate.user_id,
          project_id: @rate.project_id }
      else
        { date_column => date1..(date2 - 1),
          cost_type_id: @rate.cost_type_id }
      end
    end

    def find_entries(date1, date2 = nil)
      if @rate.is_a?(HourlyRate)
        TimeEntry.includes(:rate).where(conditions_between(date1, date2))
      else
        CostEntry.includes(:rate).where(conditions_between(date1, date2))
      end
    end

    def update_entries(entries, rate = @rate)
      # This methods updates the given array of time or cost entries with the given rate
      entries = [entries] unless entries.is_a?(Array)
      ActiveRecord::Base.cache do
        entries.each do |entry|
          entry.update_costs!(rate)
        end
      end
    end

    def count_rates(date1, date2 = nil)
      @rate.class.where(conditions_between(date1, date2, :valid_from)).count
    end

    def orphaned_child_entries(date1, date2 = nil)
      # This method returns all entries in child projects without an explicit
      # rate or with a rate id of rate_id between date1 and date2
      # i.e. the ones with an assigned default rate or without a rate
      return [] unless @rate.is_a?(HourlyRate)

      (date1, date2) = order_dates(date1, date2)

      # This gets an array of all the ids of the DefaultHourlyRates
      default_rates = DefaultHourlyRate.pluck(:id)

      conditions = if date1.nil? || date2.nil?
                     # we have only one date, query >=
                     [
                       "user_id = ? AND project_id IN (?) AND (rate_id IN (?) OR rate_id IS NULL) AND spent_on >= ?",
                       @rate.user_id, @rate.project.descendants.to_a, default_rates, date1 || date2
                     ]
                   else
                     # we have two dates, query between
                     [
                       "user_id = ? AND project_id IN (?) AND (rate_id IN (?) OR rate_id IS NULL) AND spent_on BETWEEN ? AND ?",
                       @rate.user_id, @rate.project.descendants.to_a, default_rates, date1, date2
                     ]
                   end

      TimeEntry.includes(:rate).where(conditions)
    end

    def child_entries(date1, date2 = nil)
      # This method returns all entries in child projects without an explicit
      # rate or with a rate id of rate_id between date1 and date2
      # i.e. the ones with an assigned default rate or without a rate
      return [] unless @rate.is_a?(HourlyRate)

      (date1, date2) = order_dates(date1, date2)

      conditions = if date1.nil? || date2.nil?
                     # we have only one date, query >=
                     [
                       "user_id = ? AND project_id IN (?) AND rate_id = ? AND spent_on >= ?",
                       @rate.user_id, @rate.project.descendants.to_a, @rate.id, date1 || date2
                     ]
                   else
                     # we have two dates, query between
                     [
                       "user_id = ? AND project_id IN (?) AND rate_id  = ? AND spent_on BETWEEN ? AND ?",
                       @rate.user_id, @rate.project.descendants.to_a, @rate.id, date1, date2
                     ]
                   end

      TimeEntry.includes(:rate).where(conditions)
    end
  end
end
