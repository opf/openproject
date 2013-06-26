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

    class PlanningElementStatusesController < PlanningElementStatusesController
      unloadable
      helper :timelines

      include ::Api::V2::ApiController

      accept_key_auth :index, :show

      def index
        @planning_element_statuses = PlanningElementStatus.active
        respond_to do |format|
          format.api
        end
      end

      def show
        @planning_element_status = PlanningElementStatus.active.find(params[:id])
        respond_to do |format|
          format.api
        end
      end
    end

  end
end

