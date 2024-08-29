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

module CustomActions::Actions::Strategies::ValidateInRange
  def minimum
    nil
  end

  def maximum
    nil
  end

  def validate(errors)
    super
    validate_in_interval(errors)
  end

  private

  def validate_in_interval(errors)
    return unless values.compact.length == 1

    validate_greater_than_minimum(errors)
    validate_smaller_than_maximum(errors)
  end

  def validate_smaller_than_maximum(errors)
    if maximum && values[0] > maximum
      errors.add :actions,
                 :smaller_than_or_equal_to,
                 name: human_name,
                 count: maximum
    end
  end

  def validate_greater_than_minimum(errors)
    if minimum && values[0] < minimum
      errors.add :actions,
                 :greater_than_or_equal_to,
                 name: human_name,
                 count: minimum
    end
  end
end
