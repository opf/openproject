# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
# ++

module Admin
  module Settings
    class EnumerationsControllerBase < ApplicationController
      include OpTurbo::ComponentStream

      before_action :require_admin
      before_action :find_enumeration, only: %i[edit update destroy move reassign]
      layout "admin"

      helper_method :index_component_class

      def index
        @enumerations = enumeration_class.all
      end

      def new
        @enumeration = enumeration_class.new
      end

      def edit; end

      def create
        @enumeration = enumeration_class.new(enumeration_permitted_params)

        if @enumeration.save
          flash[:notice] = I18n.t(:notice_successful_update)
          redirect_to(action: :index)
        else
          render action: :new, status: :unprocessable_entity
        end
      end

      def update
        if @enumeration.update(enumeration_permitted_params)
          flash[:notice] = I18n.t(:notice_successful_update)
          redirect_to(action: :index)
        else
          render action: :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @enumeration.in_use?
          handle_reassignment_on_deletion
        elsif @enumeration.destroy
          flash[:notice] = I18n.t(:notice_successful_delete)
          redirect_to(action: :index, status: :see_other)
        else
          flash.now[:error] = I18n.t(:error_can_not_delete_entry)
          redirect_to(action: :index, status: :see_other)
        end
      end

      def move
        if @enumeration.update(move_params)
          render_success_flash_message_via_turbo_stream(
            message: I18n.t(:enumeration_caption_order_changed)
          )
        else
          render_error_flash_message_via_turbo_stream(
            message: I18n.t(:enumeration_could_not_be_moved)
          )
        end

        replace_via_turbo_stream(
          component: index_component_class.new(enumerations: enumeration_class.all)
        )

        respond_with_turbo_streams
      end

      def reassign
        @other_enumerations = enumeration_class.all - [@enumeration]
      end

      private

      def move_params
        move_to = params[:move_to]
        position = Integer(params[:position], exception: false)

        if move_to.in? %w(highest higher lower lowest)
          { move_to: move_to }
        elsif position
          { position: position }
        else
          {}
        end
      end

      def handle_reassignment_on_deletion
        reassign_to_id = params.dig(:enumeration, :reassign_to_id)

        if reassign_to_id.present?
          reassign_to = enumeration_class.find_by(id: reassign_to_id)
          @enumeration.destroy(reassign_to)
          flash[:notice] = I18n.t(:notice_successful_delete)
          redirect_to(action: :index)
        else
          redirect_to(action: :reassign, id: @enumeration.id)
        end
      end

      def find_enumeration
        @enumeration = enumeration_class.find(params[:id])
      end

      def enumeration_class
        raise SubclassResponsibilityError
      end

      def enumeration_permitted_params
        permitted_params.enumerations
      end

      def index_component_class
        ::Admin::Enumerations::IndexComponent
      end
    end
  end
end
