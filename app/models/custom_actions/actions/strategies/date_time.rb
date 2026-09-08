# frozen_string_literal: true

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

module CustomActions::Actions::Strategies::DateTime
  CURRENT_FLAG = "%CURRENT_DATETIME%"
  # Followed by an offset in seconds, e.g. "%RELATIVE_DATETIME%3600".
  RELATIVE_FLAG = "%RELATIVE_DATETIME%"

  def values=(values)
    super(Array(values).map { |v| to_datetime_or_nil(v) }.uniq)
  end

  def type
    :datetime_property
  end

  def apply(work_package)
    accessor = :"#{self.class.key}="
    if work_package.respond_to? accessor
      work_package.send(accessor, datetime_to_apply)
    end
  end

  private

  def datetime_to_apply
    value = values.first

    if value == CURRENT_FLAG
      ::DateTime.current
    elsif relative?(value)
      ::DateTime.current + relative_offset(value).seconds
    else
      value
    end
  end

  def relative?(value)
    value.to_s.start_with?(RELATIVE_FLAG)
  end

  def relative_offset(value)
    value.to_s[RELATIVE_FLAG.size..].to_i
  end

  def to_datetime_or_nil(value)
    return value if value.nil? || value == CURRENT_FLAG || relative?(value)

    value.to_datetime
  rescue TypeError, ArgumentError
    nil
  end
end
