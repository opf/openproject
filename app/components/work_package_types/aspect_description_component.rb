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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  class AspectDescriptionComponent < ApplicationComponent
    def initialize(variant:, aspect:, form_mode: :existing)
      super()
      @variant = variant
      @aspect = aspect
      @form_mode = form_mode
    end

    def call
      render(Primer::Beta::Text.new(tag: :p, color: :muted, mb: 3, test_selector: "aspect-description")) { text }
    end

    private

    def text
      translation = I18n.t("types.aspect_descriptions.#{translation_key}")
      translation.is_a?(Hash) ? translation.fetch(kind) : translation
    end

    def translation_key
      @aspect == :form_configuration ? "form_configuration.#{@form_mode}" : @aspect
    end

    def kind = named_variant? ? :variant : :type

    def named_variant? = @variant.is_a?(TypeVariant) && !@variant.is_default_variant?
  end
end
