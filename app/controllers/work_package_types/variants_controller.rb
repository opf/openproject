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
    administration_only! :index, :make_default, :remove_default

    current_menu_item do
      :types
    end

    # The filter input drives the list's turbo frame, so a frame request only needs the list
    # component: Turbo picks the frame out of it and drops the rest.
    def index
      return unless turbo_frame_request?

      render VariantsListComponent.new(type: @type, query: params[:query]), layout: false
    end

    def menu
      render Types::VariantActionsComponent.new(variant: named_variant, back_url: params[:back_url]),
             layout: false
    end

    def destroy
      service_call = DeleteVariantService.new(user: current_user, model: named_variant).call

      if service_call.success?
        flash[:notice] = t(:notice_successful_delete)
      else
        flash[:error] = service_call.errors.full_messages.to_sentence
      end

      redirect_back_or_default(helpers.variant_scope_types_path, status: :see_other)
    end

    def make_default
      apply_default_service(MakeDefaultService, "types.index.make_default_notice")
    end

    def remove_default
      apply_default_service(RemoveDefaultService, "types.index.remove_default_notice")
    end

    private

    def find_variant; end

    # Unlike the actions above, either variant of a type can be the one new projects start
    # with, so the base one is addressable here too.
    def any_variant
      @type.variants.find(params.expect(:id))
    end

    def apply_default_service(service, notice_key)
      variant = any_variant
      service_call = service.new(variant:, user: current_user).call

      if service_call.success?
        flash[:notice] = t(notice_key, name: variant.composite_name)
      else
        flash[:error] = service_call.errors.full_messages
      end

      redirect_back_or_default(types_path, status: :see_other)
    end

    # A project reaches only the variants it owns, so another project's is absent rather than
    # refused after the fact.
    def named_variant
      addressable = @type.variants.non_default_variants
      addressable = addressable.owned_by(variant_scope_project) if variant_scope_project

      addressable.find(params.expect(:id))
    end
  end
end
