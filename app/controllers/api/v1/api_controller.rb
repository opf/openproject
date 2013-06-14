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
  module V1

    module ApiController

      def self.included(base)
        base.class_eval do
          skip_before_filter    :disable_api
          prepend_before_filter :disable_everything_except_api
        end
      end

      def api_version
        @@api_version ||= /api\/v1\//
      end

      def check_if_deletion_allowed(*args, &block)
        original_controller = params[:controller]
        params[:controller] = original_controller.gsub(api_version, "")
        result = super(*args, &block)
        params[:controller] = original_controller
        result
      end

      def find_project(*args, &block)
        original_controller = params[:controller]
        params[:controller] = original_controller.gsub(api_version, "")
        result = super(*args, &block)
        params[:controller] = original_controller
        result
      end

      def find_time_entry(*args, &block)
        original_controller = params[:controller]
        params[:controller] = original_controller.gsub(api_version, "")
        result = super(*args, &block)
        params[:controller] = original_controller
        result
      end

      def find_optional_project(*args, &block)
        original_controller = params[:controller]
        params[:controller] = original_controller.gsub(api_version, "")
        result = super(*args, &block)
        params[:controller] = original_controller
        result
      end

      def authorize_for_user(*args, &block)
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
