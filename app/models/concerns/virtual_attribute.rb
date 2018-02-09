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

module Concerns
  module VirtualAttribute
    extend ActiveSupport::Concern

    class_methods do
      def virtual_attribute(attribute, cast_type: nil, &block)
        attribute attribute, cast_type
        define_attribute_method attribute

        include InstanceMethods

        define_method "#{attribute}=" do |value|
          set_virtual_attribute(attribute, value) if send(attribute) != value
          instance_variable_set(:"@#{attribute}", value)
        end

        if block_given?
          define_method attribute do
            if instance_variable_get(:"@#{attribute}").present?
              instance_variable_get(:"@#{attribute}")
            else
              value = instance_eval(&block)

              set_virtual_attribute_was(attribute, value)

              instance_variable_set(:"@#{attribute}", value)
            end
          end
        end
      end
    end

    module InstanceMethods
      # Used to persists the changes to the virtual attribute in the mutation_tracker used by
      # AR::Dirty so that it looks like every other attribute.
      # Using attribute_will_change! does not place the value in the tracker but merely forces
      # the attribute to be returned when asking the object for changes.
      def set_virtual_attribute_was(attribute, value)
        attributes = mutation_tracker.send(:attributes)
        attributes[attribute.to_s].instance_variable_set(:@value_before_type_cast, value)
      end

      def set_virtual_attribute(attribute, value)
        attributes = mutation_tracker.send(:attributes)
        attributes[attribute.to_s] = attributes[attribute.to_s].with_value_from_user(value)
      end
    end
  end
end
