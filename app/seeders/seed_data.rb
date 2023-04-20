# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class SeedData
  def initialize(data)
    @data = data
  end

  def lookup(path)
    case sub_data = fetch(path)
    when Hash
      SeedData.new(sub_data)
    else
      sub_data
    end
  end

  def each(path, &)
    case sub_data = fetch(path)
    when nil
      nil
    when Enumerable
      sub_data.each(&)
    else
      raise ArgumentError, "expected an Enumerable at path #{path}, got #{sub_data.class}"
    end
  end

  def each_data(path)
    sub_data = fetch(path)
    return if sub_data.nil?

    sub_data.each_value do |item_data|
      yield SeedData.new(item_data)
    end
  end

  private

  def fetch(path)
    keys = path.to_s.split('.')
    @data.dig(*keys)
  end
end
