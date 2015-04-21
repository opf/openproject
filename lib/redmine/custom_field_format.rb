#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Redmine
  class CustomFieldFormat
    include Redmine::I18n

    cattr_accessor :available
    @@available = {}

    attr_accessor :name, :order, :label, :edit_as, :class_names

    def initialize(name, label:, order:, edit_as: name, only: nil)
      self.name = name
      self.label = label
      self.order = order
      self.edit_as = edit_as
      self.class_names = only
    end

    def format(value)
      send "format_as_#{name}", value
    end

    def format_as_date(value)
      format_date(value.to_date); rescue; value     end

    def format_as_bool(value)
      is_true = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
      l(is_true ? :general_text_Yes : :general_text_No)
    end

    ['string', 'text', 'int', 'float', 'list'].each do |name|
      define_method("format_as_#{name}") {|value|
        return value.to_s
      }
    end

    ['user', 'version'].each do |name|
      define_method("format_as_#{name}") {|value|
        return value.blank? ? '' : name.classify.constantize.find_by_id(value.to_i).to_s
      }
    end

    class << self
      def map(&_block)
        yield self
      end

      # Registers a custom field format
      def register(custom_field_format, _options = {})
        @@available[custom_field_format.name] = custom_field_format unless @@available.keys.include?(custom_field_format.name)
      end

      def available_formats
        @@available.keys
      end

      def find_by_name(name)
        @@available[name.to_s]
      end

      def label_for(name)
        format = @@available[name.to_s]
        format.label.is_a?(Proc) ? format.label.call : l(format.label) if format
      end

      # Return an array of custom field formats which can be used in select_tag
      def as_select(class_name = nil)
        fields = @@available.values
        fields = fields.select { |field| field.class_names.nil? || field.class_names.include?(class_name) }
        fields.sort {|a, b|
          a.order <=> b.order
        }.map {|custom_field_format|
          [label_for(custom_field_format.name), custom_field_format.name]
        }
      end

      def format_value(value, field_format)
        return '' unless value && !value.empty?

        if format_type = find_by_name(field_format)
          format_type.format(value)
        else
          value
        end
      end
    end
  end
end
