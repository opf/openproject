#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
#++

module CustomFields
  module SharedActions
    extend ActiveSupport::Concern

    included do
      def index_path(custom_field, params = {})
        if custom_field.type == "ProjectCustomField"
          admin_settings_project_custom_fields_path(**params)
        else
          custom_fields_path(**params)
        end
      end

      def edit_path(custom_field, params = {})
        if custom_field.type == "ProjectCustomField"
          admin_settings_project_custom_field_path(**params)
        else
          edit_custom_field_path(**params)
        end
      end

      def create
        call = ::CustomFields::CreateService
          .new(user: current_user)
          .call(get_custom_field_params.merge(type: permitted_params.custom_field_type))

        if call.success?
          flash[:notice] = t(:notice_successful_create)
          call_hook(:controller_custom_fields_new_after_save, custom_field: call.result)
          redirect_to index_path(call.result, tab: call.result.class.name)
        else
          @custom_field = call.result || new_custom_field
          render action: "new"
        end
      end

      def update
        perform_update(get_custom_field_params)
      end

      def perform_update(custom_field_params)
        call = ::CustomFields::UpdateService
          .new(user: current_user, model: @custom_field)
          .call(custom_field_params)

        if call.success?
          flash[:notice] = t(:notice_successful_update)
          call_hook(:controller_custom_fields_edit_after_save, custom_field: @custom_field)
          redirect_back_or_default(edit_path(@custom_field, id: @custom_field.id))
        else
          render action: "edit"
        end
      end

      def reorder_alphabetical
        reordered_options = @custom_field
          .custom_options
          .sort_by(&:value)
          .each_with_index
          .map do |custom_option, index|
          { id: custom_option.id, position: index + 1 }
        end

        perform_update(custom_options_attributes: reordered_options)
      end

      def destroy
        begin
          @custom_field.destroy
        rescue StandardError
          flash[:error] = I18n.t(:error_can_not_delete_custom_field)
        end
        redirect_to index_path(@custom_field, tab: @custom_field.class.name)
      end

      def delete_option
        if @custom_option.destroy
          num_deleted = delete_custom_values! @custom_option

          flash[:notice] = I18n.t(
            :notice_custom_options_deleted, option_value: @custom_option.value, num_deleted:
          )
        else
          flash[:error] = @custom_option.errors.full_messages
        end

        redirect_to edit_path(@custom_field, id: @custom_field.id)
      end

      def new_custom_field
        ::CustomFields::CreateService.careful_new_custom_field(permitted_params.custom_field_type)
      end

      def get_custom_field_params
        permitted_params.custom_field
      end

      def find_custom_option
        @custom_option = CustomOption.find params[:option_id]
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def delete_custom_values!(custom_option)
        CustomValue
          .where(custom_field_id: custom_option.custom_field_id, value: custom_option.id)
          .delete_all
      end

      def prepare_custom_option_position
        return unless params[:custom_field][:custom_options_attributes]

        index = 0

        params[:custom_field][:custom_options_attributes].each do |_id, attributes|
          attributes[:position] = (index = index + 1)
        end
      end
    end
  end
end
