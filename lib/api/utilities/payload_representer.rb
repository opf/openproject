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

module API
  module Utilities
    # PayloadRepresenter responsibility is to parse user params input and render
    # only the writable attributes.
    #
    # The `UpdateContract` or the `CreateContract` is used to filter out read
    # only attributes from the input parameters. Guessing is done by checking if
    # the record is a new record.
    #
    # This module is intended to be included in a dedicated PayloadRepresenter
    # class inheriting from the non-payload representer.
    module PayloadRepresenter
      def self.included(base)
        base.extend(ClassMethods)

        base.representable_attrs.each do |property|
          next if property.name == "meta"

          if property.name == "links"
            add_filter(property, LinkRenderBlock)
            next
          end

          # Note: `:writeable` is not a typo, it's used by declarative gem
          writable = property[:writeable]

          # If writable is a lambda, rely on it to determine if the property should be output
          # else if writable is explicitly false, do not output the property
          # else rely on #writable_attributes (through UnwritablePropertyFilter) to know if the property should be output
          next if writable.respond_to?(:call)

          if writable == false
            property.merge!(readable: false)
          else
            add_filter(property, UnwritablePropertyFilter)
          end
        end
      end

      module UnwritablePropertyFilter
        module_function

        def call(input, options)
          writable_attr = options[:decorator].writable_attributes

          as = options[:binding][:as].()
          if writable_attr.include?(as)
            input
          else
            ::Representable::Pipeline::Stop
          end
        end
      end

      module LinkRenderBlock
        module_function

        def call(input, options)
          writable_attr = options[:decorator].writable_attributes

          input.reject do |link|
            link.rel && writable_attr.exclude?(link.rel.to_s)
          end
        end
      end

      def self.add_filter(property, filter)
        return if property[:render_filter].include?(filter)

        property.merge!(render_filter: filter)
      end

      def from_hash(hash, *)
        # Prevent entries in _embedded from overriding anything in the _links section
        copied_hash = hash.deep_dup

        copied_hash.delete("_embedded")

        super(copied_hash, *)
      end

      def contract?(represented)
        contract_class(represented).present?
      end

      def writable_attributes
        @writable_attributes ||= begin
          contract = contract_class(represented)

          if contract
            contract
              .new(represented, current_user)
              .writable_attributes
              .map { |name| ::API::Utilities::PropertyNameConverter.from_ar_name(name) }
          else
            representable_attrs.map do |property|
              property[:as].()
            end
          end
        end
      end

      module ClassMethods
        def create_class(*)
          new_class = super

          new_class.send(:include, ::API::Utilities::PayloadRepresenter)

          new_class
        end
      end

      private

      def contract_class(represented)
        return nil unless represented.respond_to?(:new_record?)

        contract_namespace = represented.class.name.pluralize

        contract_name = if represented.new_record?
                          "CreateContract"
                        else
                          "UpdateContract"
                        end

        begin
          "#{contract_namespace}::#{contract_name}".constantize
        rescue NameError
          nil
        end
      end
    end
  end
end
