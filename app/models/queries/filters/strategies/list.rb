#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Queries::Filters::Strategies
  class List < BaseStrategy
    delegate :allowed_values,
             to: :filter

    supported_operator_list ['=', '!']

    def validate
      # TODO: the -1 is a special value that exists for historical reasons
      # so one can send the operator '=' and the values ['-1']
      # which results in a IS NULL check in the DB.
      # Remove once timelines is removed.
      if non_valid_values?
        errors.add(:values, :inclusion)
      end
    end

    def valid_values!
      filter.values &= (allowed_values.map(&:last).map(&:to_s) + ['-1'])
    end

    def non_valid_values?
      (values.reject(&:blank?) & (allowed_values.map(&:last).map(&:to_s) + ['-1'])) != values.reject(&:blank?)
    end
  end
end
