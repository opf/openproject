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

module Settings
  class Available
    attr_accessor :name,
                  :format,
                  :default,
                  :api_name,
                  :serialized,
                  :api

    def initialize(name, format:, default:, api_name: name, serialized: false, api: true)
      self.name = name.to_s
      self.format = format.to_s
      self.default = default
      self.api_name = api_name
      self.serialized = serialized
      self.api = api
    end

    def serialized?
      !!serialized
    end

    def api?
      !!api
    end

    class << self
      def add(name, default:, format: :undefined, api_name: name, serialized: false, api: true)
        return if @by_name.present? && @by_name[name.to_s].present?

        @all ||= []
        @by_name = nil

        @all << new(name,
                    format: format,
                    default: default,
                    api_name: api_name,
                    serialized: serialized,
                    api: api)
      end

      def [](name)
        @by_name ||= all.group_by(&:name).transform_values(&:first)

        @by_name[name.to_s]
      end

      attr_reader :all
    end
  end
end
