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
  # Named variants of a type. A new one starts out Linked to the type's base variant for every
  # aspect, which is what makes it a variation of that configuration rather than an empty one.
  class VariantsController < BaseTabController
    include TypeVariantsFeature

    before_action :require_type_variants_feature

    current_menu_item do
      :types
    end

    def create
      variant = build_named_variant

      if variant.save
        redirect_to edit_type_form_configuration_path(type_id: @type.id, variant_id: variant.id),
                    notice: t(:notice_successful_create)
      else
        redirect_to types_path, alert: variant.errors.full_messages.to_sentence
      end
    end

    def destroy
      variant = @type.variants.named.find(params.expect(:id))

      if variant.destroy
        redirect_to types_path, notice: t(:notice_successful_delete), status: :see_other
      else
        redirect_to types_path, alert: variant.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    # The variant is found through the type, so BaseTabController's lookup would resolve the
    # one being created or deleted.
    def find_variant; end

    def build_named_variant
      @type.variants.new(variant_params).tap do |variant|
        TypeVariant::ASPECTS.each { |aspect| variant.public_send(:"#{aspect}_source=", @type.default_variant) }
      end
    end

    def variant_params
      params.expect(type_variant: [:variant_name])
    end
  end
end
