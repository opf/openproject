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
  attr_reader :path

  def initialize(path, data)
    @path = path
    @data = data.deep_stringify_keys
  end

  def key
    @key ||= path.split('.').last
  end

  def lookup(path)
    keys = path.to_s.split('.')
    case result = @data.dig(*keys)
    when Hash
      result_path = [self.path, path].join('.')
      SeedData.new(result_path, result)
    else
      result
    end
  end

  def each(path, &block)
    keys = path.to_s.split('.')
    result = @data.dig(*keys)

    case result
    when Array
      result.each(&block)
    when Hash
      result.each do |item_key, item_data|
        item_path = [self.path, path, item_key].join('.')
        block.(SeedData.new(item_path, item_data))
      end
    end
  end

  def each_data(path)
    keys = path.to_s.split('.')
    result = @data.dig(*keys)
    return if result.nil?

    result.each do |item_key, item_data|
      item_path = [self.path, path, item_key].join('.')
      yield SeedData.new(item_path, item_data)
    end
  end

  def exists?(key)
    lookup(key).present?
  end
end
