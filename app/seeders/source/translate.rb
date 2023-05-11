# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

  def translate(hash, i18n_key = "#{I18N_PREFIX}.#{seed_file_name}")
    translate_translatable_keys(hash, i18n_key)
    translate_nested_enumerations(hash, i18n_key)
    hash
  end

  private

  def translate_translatable_keys(hash, i18n_key)
    translatable_keys(hash).each do |key|
      value = hash.delete("t_#{key}")
      hash[key] = translate_value(value, "#{i18n_key}.#{key}")
    end
  end

  def translatable_keys(hash)
    hash.keys
      .filter { _1.start_with?('t_') }
      .map { _1.gsub(/^t_/, '') }
  end

  def translate_value(value, i18n_key)
    case value
    when String
      I18n.t(i18n_key, locale:, default: value)
    when Array
      value.map.with_index { |v, i| translate_value(v, "#{i18n_key}.item_#{i}") }
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
          .each_with_index { |h, i| translate(h, "#{i18n_key}.#{key}.item_#{i}") }
      end
    end
  end
end
