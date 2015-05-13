#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module Utilities
    module GrapeHelper
      ##
      # We need this to be able to use `Grape::Middleware::Error#error_response`
      # outside of the Grape context. We use it outside of the Grape context because
      # OpenProject authentication happens in a middleware upstream of Grape.
      class GrapeError < Grape::Middleware::Error
        def initialize(env)
          @env = env
          @options = {}
        end
      end

      def grape_error_for(env)
        GrapeError.new env
      end

      def error_response(rescue_from, error = nil, rescue_subclasses: nil, headers: {})
        rescue_from rescue_from, rescue_subclasses: rescue_subclasses do |e|
          error ||= e
          representer = ::API::V3::Errors::ErrorRepresenter.new error
          env['api.format'] = 'hal+json'

          error_response status: error.code, message: representer.to_json, headers: headers
        end
      end
    end
  end
end
