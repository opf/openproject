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

class DefaultHourlyRate < Rate
  validates_uniqueness_of :valid_from, scope: :user_id
  validates_presence_of :user_id, :valid_from
  validate :change_of_user_only_on_first_creation
  before_save :convert_valid_from_to_date

  def next(reference_date = valid_from)
    DefaultHourlyRate
      .where(['user_id = ? and valid_from > ?', user_id, reference_date])
      .order('valid_from ASC')
      .first
  end

  def previous(reference_date = valid_from)
    user.default_rate_at(reference_date - 1)
  end

  def self.at_for_user(date, user_id)
    user_id = user_id.id if user_id.is_a?(User)

    where(['user_id = ? and valid_from <= ?', user_id, date]).order('valid_from DESC').first
  end

  private

  def convert_valid_from_to_date
    self.valid_from &&= valid_from.to_date
  end

  def change_of_user_only_on_first_creation
    # Only allow change of user on first creation
    errors.add :user_id, :invalid if !self.new_record? and user_id_changed?
    begin
      valid_from.to_date
    rescue Exception
      errors.add :valid_from, :invalid
    end
  end
end
