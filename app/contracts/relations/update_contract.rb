#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Relations
  class UpdateContract < BaseContract
    validate :from_immutable
    validate :to_immutable

    private

    def from_immutable
      errors.add :from, :error_readonly if from_id_changed_and_not_swapped?
    end

    def to_immutable
      errors.add :to, :error_readonly if to_id_changed_and_not_swapped?
    end

    def from_id_changed_and_not_swapped?
      model.from_id_changed? && !from_and_to_swapped?
    end

    def to_id_changed_and_not_swapped?
      model.to_id_changed? && !from_and_to_swapped?
    end

    def from_and_to_swapped?
      model.to_id == model.from_id_was && model.from_id == model.to_id_was
    end
  end
end
