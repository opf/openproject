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

module Api
  module V2
    module ApiController
      module ClassMethods
        def included(base)
          base.class_eval do
            if (respond_to? :skip_before_filter) && (respond_to? :prepend_before_filter)
              skip_before_filter :disable_api
              prepend_before_filter :disable_everything_except_api
            end
          end
        end

        def permeate_permissions(*filter_names)
          filter_names.each do |filter_name|
            define_method filter_name do |*args, &block|
              begin
                original_controller = params[:controller]
                params[:controller] = original_controller.gsub(api_version, '')
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
        /api\/v2\//
      end

      permeate_permissions :authorize,
                           :authorize_for_user,
                           :check_if_deletion_allowed,
                           :find_optional_project,
                           :find_project,
                           :find_time_entry,
                           :apply_at_timestamp,
                           :determine_base,
                           :find_all_projects_by_project_id,
                           :find_project_by_project_id,
                           :jump_to_project_menu_item,
                           :find_optional_project_and_raise_error
    end
  end
end
