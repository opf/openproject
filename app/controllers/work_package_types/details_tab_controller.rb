# frozen_string_literal: true

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

module WorkPackageTypes
  class DetailsTabController < BaseTabController
    current_menu_item %i[edit update] do
      :types
    end

    before_action :set_editable

    def edit; end

    def update
      return update_variant if named_variant?

      result = UpdateService.new(user: current_user, model: @type, contract_class: UpdateDetailsContract)
                            .call(permitted_details_params)

      if result.success?
        redirect_to edit_type_details_path(type_id: @type.id), notice: I18n.t(:notice_successful_update)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_editable
      @editable = named_variant? ? @variant : @type
    end

    def named_variant? = @variant.present? && !@variant.is_default_variant?

    def update_variant
      if @variant.update(permitted_variant_params)
        redirect_to edit_type_details_path(type_id: @type.id, variant_id: @variant.id),
                    notice: I18n.t(:notice_successful_update)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def permitted_details_params
      params.expect(type: %i[name color_id is_milestone is_in_roadmap])
    end

    def permitted_variant_params
      params.expect(type_variant: [:variant_name])
    end
  end
end
