#-- encoding: UTF-8

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

module Queries::Filters::Strategies
  class Relation < BaseStrategy
    delegate :allowed_values_subset,
             to: :filter

    self.supported_operators = ::Relation::TYPES.keys + %w(parent children)
    self.default_operator = ::Relation::TYPE_RELATES

    def validate
      unique_values = values.uniq
      allowed_and_desired_values = allowed_values_subset & unique_values

      if allowed_and_desired_values.sort != unique_values.sort
        errors.add(:values, :inclusion)
      end
      if too_many_values
        errors.add(:values, "only one value allowed")
      end
    end

    def valid_values!
      filter.values &= allowed_values.map(&:last).map(&:to_s)
    end

    private

    def too_many_values
      values.reject(&:blank?).length > 1
    end
  end
end
