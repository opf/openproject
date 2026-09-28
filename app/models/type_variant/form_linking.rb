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

class TypeVariant
  module FormLinking
    def linked?(aspect)
      return super unless form?(aspect)

      !is_default_variant? && form_configuration_id == type.default_variant.form_configuration_id
    end

    def source_for(aspect)
      return super unless form?(aspect)

      type.default_variant if linked?(aspect)
    end

    def dependents_for(aspect)
      return super unless form?(aspect)
      return self.class.none unless is_default_variant?

      self.class.where(form_configuration_id:).where.not(id:).preload(:type).in_display_order
    end

    def link!(aspect)
      return super unless form?(aspect)
      return if linked?(aspect)

      update!(form_configuration: type.default_variant.form_configuration)
    end

    def unlink!(aspect)
      return super unless form?(aspect)

      own_form_configuration
      update!(form_configuration_excluded_elements: [])
    end

    def own_form_configuration
      return if form_configuration && form_configuration.type_variants.where.not(id:).none?

      self.form_configuration = FormConfiguration.new(name: FormConfiguration.implicit_name(composite_name))
    end

    private

    def form?(aspect) = aspect.to_s == TypeVariant::FORM_CONFIGURATION
  end
end
