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

class JsonSchemaLoader
  def initialize(base_path: "docs/api/apiv3/components/schemas")
    @base_path = base_path
  end

  def load(schema_name)
    load_file("#{@base_path}/#{schema_name}.yml")
  end

  private

  def load_file(file_name)
    return schema_cache.fetch(file_name) if schema_cache.key?(file_name)

    schema = YAML.load_file(file_name).deep_symbolize_keys
    schema = resolve_references(schema, file_name)
    schema_cache[file_name] = schema
  end

  def resolve_references(schema, file_name)
    if schema.key?(:$ref)
      ref_file = File.join(File.dirname(file_name), schema.fetch(:$ref))
      return load_file(ref_file)
    end

    schema.to_h do |key, value|
      next [key, resolve_references(value, file_name)] if value.is_a?(Hash)

      if value.is_a?(Array)
        next [
          key,
          value.map { |v| v.is_a?(Hash) ? resolve_references(v, file_name) : v }
        ]
      end

      [key, value]
    end
  end

  def schema_cache
    @schema_cache ||= {}
  end
end
