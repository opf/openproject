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

module CustomActions::Actions::Strategies::Date
  def values=(values)
    super(Array(values).map { |v| to_date_or_nil(v) }.uniq)
  end

  def type
    :date_property
  end

  def apply(work_package)
    accessor = :"#{self.class.key}="
    if work_package.respond_to? accessor
      work_package.send(accessor, date_to_apply)
    end
  end

  private

  def date_to_apply
    if values.first == '%CURRENT_DATE%'
      Date.today
    else
      values.first
    end
  end

  def to_date_or_nil(value)
    case value
    when nil, '%CURRENT_DATE%'
      value
    else
      value.to_date
    end
  rescue TypeError, ArgumentError
    nil
  end
end
