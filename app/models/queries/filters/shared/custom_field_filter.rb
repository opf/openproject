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

module Queries::Filters::Shared::CustomFieldFilter
  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval do
      class_attribute :custom_field_context
    end
  end

  module ClassMethods
    def key
      /cf_(\d+)/
    end

    def all_for(context = nil)
      custom_field_context.custom_fields(context).filter_map do |cf|
        create!(name: cf.column_name, custom_field: cf, context:)
      rescue ::Queries::Filters::InvalidError
        Rails.logger.error "Failed to map custom field filter for #{cf.column_name} (CF##{cf.id})."
        nil
      end
    end

    ##
    # Find the given custom field by its accessor, should it exist.
    def find_by_accessor(name)
      match = name.match /cf_(\d+)/

      if match.present? && match[1].to_i > 0
        all_custom_fields.detect { |cf| cf.id == match[1].to_i }
      end
    end

    ##
    # Create a filter instance for the given custom field accessor
    def create!(name:, **)
      custom_field = find_by_accessor(name)
      raise ::Queries::Filters::InvalidError if custom_field.nil?

      from_custom_field!(custom_field:, **)
    end

    ##
    # Create a filter instance for the given custom field
    def from_custom_field!(custom_field:, **)
      constant_name = subfilter_module(custom_field)
      clazz = "::Queries::Filters::Shared::CustomFields::#{constant_name}".constantize
      clazz.create!(custom_field:, custom_field_context:, **)
    rescue NameError => e
      Rails.logger.error "Failed to constantize custom field filter for #{name}. #{e}"
      raise ::Queries::Filters::InvalidError
    end

    ##
    # Get the subfilter class name for the given custom field
    def subfilter_module(custom_field)
      case custom_field.field_format
      when "user"
        :User
      when "list", "version"
        :ListOptional
      when "bool"
        :Bool
      else
        :Base
      end
    end

    def all_custom_fields
      key = ["Queries::Filters::Shared::CustomFieldFilter",
             custom_field_context.custom_field_class,
             "all_custom_fields"]

      RequestStore.fetch(key.join("/")) do
        custom_field_context.custom_field_class.all.to_a
      end
    end
  end
end
