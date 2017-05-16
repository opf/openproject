#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

module OpenProject
  class CustomFieldFormat
    include Redmine::I18n

    cattr_accessor :available
    @@available = {}

    attr_accessor :name, :order, :label, :edit_as, :class_names, :formatter

    def initialize(name, label:, order:, edit_as: name, only: nil, formatter: 'CustomValue::StringStrategy')
      self.name = name
      self.label = label
      self.order = order
      self.edit_as = edit_as
      self.class_names = only
      self.formatter = formatter
    end

    def formatter
      # avoid using stale definitions in dev mode
      Kernel.const_get(@formatter)
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

      def all_for_field(custom_field)
        class_name = custom_field.class.customized_class.name

        available
          .values
          .select { |field| field.class_names.nil? || field.class_names.include?(class_name) }
      end
    end
  end
end
