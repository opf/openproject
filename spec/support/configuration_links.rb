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

module ConfigurationLinkHelpers
  def link_configuration(variant, aspect:, excluded: [])
    v = variant_of(variant)
    if aspect == TypeVariant::FORM_CONFIGURATION
      v.update!(form_configuration: v.type.default_variant.form_configuration)
    else
      v.link!(aspect)
    end
    v.update!("#{aspect}_excluded_elements" => excluded) if excluded.any? && TypeVariant::EXCLUDABLE_ASPECTS.include?(aspect)
  end

  def unlink_configuration(variant, aspect:)
    v = variant_of(variant)
    return v.unlink!(aspect) unless aspect == TypeVariant::FORM_CONFIGURATION

    v.update!(form_configuration: create(:form_configuration), form_configuration_excluded_elements: [])
  end

  def exclude_configuration_elements(variant, aspect:, elements:)
    variant_of(variant).update!("#{aspect}_excluded_elements": elements)
  end

  def excluded_configuration_elements(variant, aspect:)
    return [] unless TypeVariant::EXCLUDABLE_ASPECTS.include?(aspect)

    variant_of(variant).reload.public_send(:"#{aspect}_excluded_elements")
  end

  def variant_of(record)
    record.is_a?(TypeVariant) ? record : record.default_variant
  end
end

RSpec.configure do |config|
  config.include ConfigurationLinkHelpers
end
