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
# frozen_string_literal: true

module TypeSchemes
  module DefaultScheme
    NAME = "Default Scheme"
    DEFAULT_TYPE_NAME = "task"

    module_function

    def current
      TypeScheme.active.includes(:items).find_by(is_default: true)
    end

    def ensure!
      TypeScheme.active.find_by(is_default: true) || create!
    end

    def task_type(types = Type.order(:position, :id).to_a)
      types.find { |type| type.name.to_s.casecmp?(DEFAULT_TYPE_NAME) } ||
        types.find { |type| !type.is_milestone } ||
        types.first
    end

    def add_type(type)
      scheme = TypeScheme.active.find_by(is_default: true)
      return if scheme.nil? || scheme.items.exists?(type_id: type.id)

      scheme.items.create!(type:, position: scheme.items.maximum(:position).to_i + 1, is_default: false)
    end

    def create!
      types = Type.order(:position, :id).to_a
      return if types.empty?

      default_type = task_type(types)
      items = types.each_with_index.map do |type, index|
        { type_id: type.id, position: index + 1, is_default: type == default_type }
      end
      result = SchemeService.create(name: unique_name, items:, is_default: true)
      return result.result if result.success?

      current || raise(ActiveRecord::RecordInvalid, result.result)
    rescue ActiveRecord::RecordNotUnique
      current
    end

    def unique_name
      return NAME unless TypeScheme.exists?(name: NAME)

      (2..).lazy.map { |n| "#{NAME} #{n}" }.find { |name| !TypeScheme.exists?(name:) }
    end
  end
end
