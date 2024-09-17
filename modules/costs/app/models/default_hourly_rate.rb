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

class DefaultHourlyRate < Rate
  validates_uniqueness_of :valid_from, scope: :user_id
  validates_presence_of :user_id, :valid_from
  validate :change_of_user_only_on_first_creation
  before_save :convert_valid_from_to_date

  def next(reference_date = valid_from)
    DefaultHourlyRate
      .where(["user_id = ? and valid_from > ?", user_id, reference_date])
      .order(Arel.sql("valid_from ASC"))
      .first
  end

  def previous(reference_date = valid_from)
    user.default_rate_at(reference_date - 1)
  end

  def self.at_for_user(date, user_id)
    user_id = user_id.id if user_id.is_a?(User)

    where(["user_id = ? and valid_from <= ?", user_id, date]).order(Arel.sql("valid_from DESC")).first
  end

  private

  def convert_valid_from_to_date
    self.valid_from &&= valid_from.to_date
  end

  def change_of_user_only_on_first_creation
    # Only allow change of user on first creation
    errors.add :user_id, :invalid if !new_record? and user_id_changed?
    begin
      valid_from.to_date
    rescue Exception
      errors.add :valid_from, :invalid
    end
  end

  def rate_created
    o = Methods.new(self)

    next_rate = self.next
    # and entries from all projects that need updating
    entries = o.orphaned_child_entries(valid_from, (next_rate.valid_from if next_rate))

    o.update_entries(entries)
  end

  def rate_updated
    # FIXME: This might be extremely slow. Consider using an implementation like in HourlyRateObserver
    unless valid_from_changed?
      # We have not moved a rate, maybe just changed the rate value

      return unless rate_changed?

      # Only the rate value was changed so just update the currently assigned entries
      return rate_created
    end

    update_costs
    rate_created
  end

  def update_costs
    o = Methods.new(self)

    o.update_entries(TimeEntry.where(rate_id: id))
  end

  class Methods
    def initialize(changed_rate)
      @rate = changed_rate
    end

    def order_dates(date1, date2)
      # order the dates
      return date1 || date2 if date1.nil? || date2.nil?

      if date2 < date1
        date_tmp = date2
        date2 = date1
        date1 = date_tmp
      end
      [date1, date2]
    end

    def orphaned_child_entries(date1, date2 = nil)
      # This method returns all entries in all projects without an explicit rate
      # between date1 and date2
      # i.e. the ones with an assigned default rate or without a rate

      (date1, date2) = order_dates(date1, date2)

      # This gets an array of all the ids of the DefaultHourlyRates
      default_rates = DefaultHourlyRate.pluck(:id)

      conditions = if date1.nil? || date2.nil?
                     # we have only one date, query >=
                     [
                       "user_id = ? AND (rate_id IN (?) OR rate_id IS NULL) AND spent_on >= ?",
                       @rate.user_id, default_rates, date1 || date2
                     ]
                   else
                     # we have two dates, query between
                     [
                       "user_id = ? AND (rate_id IN (?) OR rate_id IS NULL) AND spent_on BETWEEN ? AND ?",
                       @rate.user_id, default_rates, date1, date2 - 1
                     ]
                   end

      TimeEntry.includes(:rate).where(conditions)
    end

    def update_entries(entries, rate = @rate)
      # This methods updates the given array of time or cost entries with the given rate
      entries = [entries] unless entries.respond_to?(:each)
      ActiveRecord::Base.cache do
        entries.each do |entry|
          entry.update_costs!(rate)
        end
      end
    end
  end
end
