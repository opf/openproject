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
      .where(["cost_type_id = ? and valid_from > ?", cost_type_id, reference_date])
      .order(Arel.sql("valid_from ASC"))
      .first
  end

  private

  def change_of_cost_type_only_on_first_creation
    errors.add :cost_type_id, :invalid if cost_type_id_changed? && !new_record?
  end
end
