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

class CostRate < Rate
  belongs_to :cost_type

  validates_uniqueness_of :valid_from, scope: :cost_type_id
  validate :change_of_cost_type_only_on_first_creation

  def previous(reference_date = valid_from)
    # This might return a default rate
    cost_type.rate_at(reference_date - 1)
  end

  def next(reference_date = valid_from)
    CostRate
      .where(['cost_type_id = ? and valid_from > ?', cost_type_id, reference_date])
      .order(Arel.sql('valid_from ASC'))
      .first
  end

  private

  def change_of_cost_type_only_on_first_creation
    errors.add :cost_type_id, :invalid if cost_type_id_changed? && !self.new_record?
  end
end
