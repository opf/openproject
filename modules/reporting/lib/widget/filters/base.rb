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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Widget::Filters::Base < Widget::Base
  attr_reader :filter, :filter_class

  def initialize(filter)
    if filter.instance_of?(Class)
      @filter_class = filter
      @filter = filter.new
    else
      @filter = filter
      @filter_class = filter.class
    end
    @engine = filter.engine
  end

  def expand_comma_separated_values!
    # In case the filter values are all written in a single string (e.g. ["12, 33"])
    if filter.values.length === 1 && filter.values[0].instance_of?(String)
      filter.values = filter.values[0].split(",").map(&:strip)
    end
  end
end
