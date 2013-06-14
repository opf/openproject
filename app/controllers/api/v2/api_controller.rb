#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module Api
  module V2

    module ApiController

      extend ::Api::V1::ApiController

      def api_version
        @@api_version ||= /api\/v2\//
      end

      def find_project_by_project_id(*args, &block)
        original_controller = params[:controller]
        params[:controller] = original_controller.gsub(api_version, "")
        result = super(*args, &block)
        params[:controller] = original_controller
        result
      end

      def authorize(*args, &block)
        original_controller = params[:controller]
        params[:controller] = original_controller.gsub(api_version, "")
        result = super(*args, &block)
        params[:controller] = original_controller
        result
      end

    end

  end
end
