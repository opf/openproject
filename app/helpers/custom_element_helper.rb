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

module CustomElementHelper
  PASS_THROUGH_KEYS = %i[class data aria].freeze

  class TagBuilder
    def initialize(view)
      @view = view
    end

    def method_missing(name, content = nil, **attributes, &)
      return super if name.end_with?("?", "!", "=")

      @view.tag.public_send(name.to_s.dasherize, content, **serialize(attributes), &)
    end

    def respond_to_missing?(name, include_private = false)
      !name.end_with?("?", "!", "=") || super
    end

    private

    def serialize(attributes)
      attributes.each_with_object({}) do |(key, value), result|
        if PASS_THROUGH_KEYS.include?(key.to_sym)
          result[key] = value
        else
          serialize_attribute(result, key, value)
        end
      end
    end

    def serialize_attribute(result, key, value)
      name = key.to_s.dasherize
      boolean_attribute = ActionView::Helpers::TagHelper::BOOLEAN_ATTRIBUTES.include?(name)

      case value
      when nil then nil
      when true then result[name] = boolean_attribute ? name : ""
      when false then result[name] = "false" unless boolean_attribute
      when Array, Hash then result[name] = value.to_json
      else result[name] = value.to_s
      end
    end
  end

  def custom_element_tag
    TagBuilder.new(self)
  end
end
