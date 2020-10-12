#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

module Bim
  module IfcModels
    class IfcViewerController < BaseController
      helper_method :gon

      before_action :find_project_by_project_id
      before_action :authorize
      before_action :find_all_ifc_models
      before_action :set_default_models
      before_action :parse_showing_models

      menu_item :ifc_models


      def show; end

      private

      def parse_showing_models
        @shown_model_ids =
          if params[:models]
            JSON.parse(params[:models])
          else
            []
          end

        @shown_ifc_models = @ifc_models.select { |model| @shown_model_ids.include?(model.id) }
      end

      def find_all_ifc_models
        @ifc_models = @project
          .ifc_models
          .includes(:attachments)
          .order('created_at ASC')
      end

      def set_default_models
        @default_ifc_models = @ifc_models.where(is_default: true)
      end
    end
  end
end
