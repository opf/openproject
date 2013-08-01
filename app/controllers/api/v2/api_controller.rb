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

      include ::Api::V1::ApiController
      extend ::Api::V1::ApiController::ClassMethods

      def api_version
        /api\/v2\//
      end

      permeate_permissions :apply_at_timestamp,
                           :determine_base,
                           :find_all_projects_by_project_id,
                           :find_project_by_project_id,
                           :jump_to_project_menu_item,
                           :find_optional_project_and_raise_error

    end
  end
end
