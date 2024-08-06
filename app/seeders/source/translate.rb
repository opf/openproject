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

module Source::Translate
  I18N_PREFIX = "seeds"
  TRANSLATABLE_PREFIX = "t_"
  TRANSLATABLE_PREFIX_PATTERN = /^#{TRANSLATABLE_PREFIX}/

  def translate(hash, i18n_key)
    translate_translatable_keys(hash, i18n_key)
    translate_nested_enumerations(hash, i18n_key)
    hash
  end

  def translatable?(key)
    key.start_with?(TRANSLATABLE_PREFIX)
  end
  module_function :translatable?

  def remove_translatable_prefix(key)
    key.gsub(TRANSLATABLE_PREFIX_PATTERN, "")
  end
  module_function :remove_translatable_prefix

  def array_key(index)
    "item_#{index}"
  end
  module_function :array_key

  private

  def translate_translatable_keys(hash, i18n_key)
    translatable_keys(hash).each do |key|
      value = hash.delete("#{TRANSLATABLE_PREFIX}#{key}")
      hash[key] = translate_value(value, "#{i18n_key}.#{key}")
    end
  end

  def translatable_keys(hash)
    hash.keys
      .filter { translatable?(_1) }
      .map { remove_translatable_prefix(_1) }
  end

  def translate_value(value, i18n_key)
    case value
    when String
      I18n.t(i18n_key, locale:, fallback: false, default: value)
    when Array
      value.map.with_index { |v, i| translate_value(v, "#{i18n_key}.#{array_key(i)}") }
    end
  end

  def translate_nested_enumerations(hash, i18n_key)
    hash.each do |key, value|
      case value
      when Hash
        translate(value, "#{i18n_key}.#{key}")
      when Array
        value
          .filter { |v| v.is_a?(Hash) }
          .each_with_index { |h, i| translate(h, "#{i18n_key}.#{key}.#{array_key(i)}") }
      end
    end
  end
end
