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
  class VariantsController < BaseTabController
    include TypeVariantsFeature

    before_action :require_type_variants_feature

    current_menu_item do
      :types
    end

    def menu
      render Types::VariantActionsComponent.new(variant: named_variant), layout: false
    end

    def destroy
      service_call = DeleteVariantService.new(user: current_user, model: named_variant).call

      if service_call.success?
        redirect_to types_path, notice: t(:notice_successful_delete), status: :see_other
      else
        redirect_to types_path, alert: service_call.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    def find_variant; end

    def named_variant
      @type.variants.non_default_variants.find(params.expect(:id))
    end
  end
end
