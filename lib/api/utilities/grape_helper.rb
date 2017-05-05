#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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

      def grape_error_for(env, api)
        GrapeError.new(env).tap do |e|
          e.options[:content_types] = api.content_types
          e.options[:format] = 'hal+json'
        end
      end

      def error_response(rescued_error, error = nil, rescue_subclasses: nil, headers: ->() { {} }, log: true)
        error_response_lambda = default_error_response(headers, log)

        response =
          if error.nil?
            error_response_lambda
          else
            lambda { instance_exec error, &error_response_lambda }
          end

        # We do this lambda business because #rescue_from behaves differently
        # depending on the number of parameters the passed block accepts.
        rescue_from rescued_error, rescue_subclasses: rescue_subclasses, &response
      end

      def default_error_response(headers, log)
        lambda { |e|
          representer = ::API::V3::Errors::ErrorRepresenter.new e
          resp_headers = instance_exec &headers
          env['api.format'] = 'hal+json'

          if log
            message = <<-MESSAGE
  Grape rescuing from error: #{e}

  Original error: #{$!.inspect}

  Stacktrace:
            MESSAGE

            $@.each do |line|
              message << "\n    #{line}"
            end

            Rails.logger.error message
          end

          error_response status: e.code, message: representer.to_json, headers: resp_headers
        }
      end
    end
  end
end
