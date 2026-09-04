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

module ConfigurationLinkHelpers
  def link_configuration(variant, source:, aspect:, excluded: [])
    variant_of(variant).update!({ "#{aspect}_source": variant_of(source) }.merge(exclusions(aspect, excluded)))
  end

  def unlink_configuration(variant, aspect:)
    variant_of(variant).update!({ "#{aspect}_source": nil }.merge(exclusions(aspect, [])))
  end

  def exclude_configuration_elements(variant, aspect:, elements:)
    variant_of(variant).update!("#{aspect}_excluded_elements": elements)
  end

  def excluded_configuration_elements(variant, aspect:)
    return [] unless TypeVariant::EXCLUDABLE_ASPECTS.include?(aspect)

    variant_of(variant).reload.public_send(:"#{aspect}_excluded_elements")
  end

  def link_configuration_without_validation(variant, source:, aspect:, excluded: [])
    variant_of(variant).update_columns({ "#{aspect}_source_id": variant_of(source).id }
                                         .merge(exclusions(aspect, excluded)))
  end

  def exclusions(aspect, elements)
    return {} unless TypeVariant::EXCLUDABLE_ASPECTS.include?(aspect)

    { "#{aspect}_excluded_elements": elements }
  end

  def variant_of(record)
    record.is_a?(TypeVariant) ? record : record.default_variant
  end
end

RSpec.configure do |config|
  config.include ConfigurationLinkHelpers
end
