# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Source::FilterTranslatables
  def filter_translatables(hash)
    filter_translatables_in_hash(hash) || {}
  end

  private

  def filter_translatables_in_object(object, translatable: false)
    case object
    when Hash
      filter_translatables_in_hash(object)
    when Array
      filter_translatables_in_array(object, translatable:)
    else
      object if translatable
    end
  end

  def filter_translatables_in_hash(hash)
    hash
      .to_h do |key, value|
        new_key = Source::Translate.remove_translatable_prefix(key)
        filtered_value = filter_translatables_in_object(value, translatable: Source::Translate.translatable?(key))
        [new_key, filtered_value]
      end
      .compact
      .presence
  end

  def filter_translatables_in_array(array, translatable: false)
    array.map.with_index.to_h do |value, i|
      key = Source::Translate.array_key(i)
      if value.is_a?(Hash)
        [key, filter_translatables_in_object(value)]
      elsif translatable
        [key, value]
      else
        [key, nil]
      end
    end
    .compact
    .presence
  end
end
