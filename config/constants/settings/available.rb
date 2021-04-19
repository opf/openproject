#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Settings::Available
  attr_accessor :name,
                :format,
                :default,
                :api_name,
                :serialized

  def initialize(name, format:, default:, api_name: name, serialized: false)
    self.name = name
    self.format = format
    self.default = default
    self.api_name = api_name
    self.serialized = serialized
  end

  def serialized?
    !!serialized
  end

  class << self
    def add(name, format:, default:, api_name: name, serialized: false)
      @all ||= []

      @all << Settings::Available.new(name,
                                      format: format,
                                      default: default,
                                      api_name: api_name,
                                      serialized: serialized)
    end

    attr_reader :all
  end
end
