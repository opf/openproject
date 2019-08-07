#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2019 the OpenProject Foundation (OPF)
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

# Root class of the API v3
# This is the place for all API v3 wide configuration, helper methods, exceptions
# rescuing, mounting of different API versions etc.

module API
  module Formats
    module HalJsonFormat
      class Formatter
        def call(object, _env)
          object.respond_to?(:to_json) ? object.to_json : MultiJson.dump(object)
        end
      end

      class Parser
        def call(object, _env)
          MultiJson.load(object)
        rescue MultiJson::ParseError => e
          error = ::API::Errors::ParseError.new(details: e.message)
          representer = ::API::V3::Errors::ErrorRepresenter.new(error)

          throw :error, status: 400, message: representer.to_json
        end
      end

      def self.included(base)
        base.class_exec do
          content_type 'hal+json', 'application/hal+json; charset=utf-8'
          content_type :json,      'application/json; charset=utf-8'

          format 'hal+json'
          formatter 'hal+json', Formatter.new

          parser :json, Parser.new
        end
      end
    end
  end
end
