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

      module ClassMethods

        def included(base)
          base.class_eval do
            if ((respond_to? :skip_before_filter) &&
                (respond_to? :prepend_before_filter))
              skip_before_filter    :disable_api
              prepend_before_filter :disable_everything_except_api
            end
          end
        end

        def permeate_permissions(*filter_names)
          filter_names.each do |filter_name|
            define_method filter_name do |*args, &block|
              begin
                original_controller = params[:controller]
                params[:controller] = original_controller.gsub(api_version, "")
                result = super(*args, &block)
              ensure
                params[:controller] = original_controller
              end
              result
            end
          end
        end
      end

      extend ClassMethods

      def api_version
        /api\/v1\//
      end

      permeate_permissions :authorize
      permeate_permissions :authorize_for_user
      permeate_permissions :check_if_deletion_allowed
      permeate_permissions :find_optional_project
      permeate_permissions :find_project
      permeate_permissions :find_time_entry

    end
  end
end
