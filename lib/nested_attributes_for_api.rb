#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module NestedAttributesForApi
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def accepts_nested_attributes_for_apis_for(*association_names)
      association_names.each do |association_name|
        if reflection = reflect_on_association(association_name)
          class_eval %Q{
            def #{association_name}_with_accepts_nested_attributes_for_apis=(new_value)
              if new_value.present? && new_value.is_a?(Hash) && new_value.has_key?(:id)
                obj = #{reflection.klass.name}.find_by_id(new_value[:id])

                if obj.present?
                  self.#{association_name}_without_accepts_nested_attributes_for_apis = obj
                else
                  @errors_in_nested_attributes ||= {}
                  @errors_in_nested_attributes[:#{association_name}] = [:invalid]
                end
              else
                self.#{association_name}_without_accepts_nested_attributes_for_apis = new_value
              end
            end
            alias_method_chain :#{association_name}=, :accepts_nested_attributes_for_apis

            attr_accessible :#{association_name} unless included_modules.include?(ActiveModel::ForbiddenAttributesProtection)
          }, __FILE__, __LINE__
        else
          raise ArgumentError, "No association found for name `#{association_name}'. Has it been defined yet?"
        end
      end
      include Validations
    end
  end

  module Validations
    def validate
      if @errors_in_nested_attributes.present?
        @errors_in_nested_attributes.each do |attribute, errs|
          errs.each do |error|
            errors.add attribute, error
          end
        end
      end
      super
    end
  end
end
