#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

require 'model_contract'

module Grids
  class BaseContract < ::ModelContract
    # TODO: validate widgets are in array of allowed widgets
    attribute :row_count do
      validate_positive_integer(:row_count)
    end

    attribute :column_count do
      validate_positive_integer(:column_count)
    end

    attribute :widgets

    def self.model
      Grid
    end

    private

    def validate_positive_integer(attribute)
      value = model.send(attribute)

      if !value
        errors.add(attribute, :blank)
      elsif value < 1
        errors.add(attribute, :greater_than, count: 0)
      end
    end
  end
end
