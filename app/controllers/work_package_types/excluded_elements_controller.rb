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
  class ExcludedElementsController < BaseTabController
    include TypeVariantsFeature

    before_action :require_type_variants_feature
    before_action :require_valid_aspect

    current_menu_item do
      :types
    end

    # For clarification: If we toggle the element on, it means we remove the exclusion from the array.
    def toggle
      call = toggle_service
        .new(user: current_user, variant: @variant)
        .call(aspect:, elements: [element])

      render json: {}, status: call.success? ? :ok : :unprocessable_entity
    end

    private

    def aspect = params[:aspect]

    def element = params.require(:element)

    def toggle_service
      if inherit?
        ExcludedElements::RemoveService
      else
        ExcludedElements::AddService
      end
    end

    def inherit?
      ActiveRecord::Type::Boolean.new.cast(params.permit(:value)[:value])
    end

    def require_valid_aspect
      render_404 unless TypeVariant::ASPECTS.include?(aspect)
    end
  end
end
