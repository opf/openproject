# Redmine - project management software
# Copyright (C) 2006-2009  Jean-Philippe Lang
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

module Redmine
  class CustomFieldFormat
    include Redmine::I18n

    cattr_accessor :available
    @@available = {}

    attr_accessor :name, :order, :label

    def initialize(name, options={})
      self.name = name
      self.label = options[:label]
      self.order = options[:order]
    end

    class << self
      def map(&block)
        yield self
      end
      
      # Registers a custom field format
      def register(custom_field_format, options={})
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
        format.label if format
      end

      # Return an array of custom field formats which can be used in select_tag
      def as_select
        @@available.values.sort {|a,b|
          a.order <=> b.order
        }.collect {|custom_field_format|
          [ l(custom_field_format.label), custom_field_format.name ]
        }
      end
    end
  end 
end
