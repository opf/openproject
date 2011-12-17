#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class IssueDrop < BaseDrop
  allowed_methods :id
  allowed_methods :subject
  allowed_methods :description
  allowed_methods :project
  allowed_methods :tracker
  allowed_methods :status
  allowed_methods :due_date
  allowed_methods :category
  allowed_methods :assigned_to
  allowed_methods :priority
  allowed_methods :fixed_version
  allowed_methods :author
  allowed_methods :created_on
  allowed_methods :updated_on
  allowed_methods :start_date
  allowed_methods :done_ratio
  allowed_methods :estimated_hours
  allowed_methods :parent

  def custom_field(name)
    return '' unless name.present?
    custom_field = IssueCustomField.find_by_name(name.strip)
    return '' unless custom_field.present?
    custom_value = @object.custom_value_for(custom_field)
    if custom_value.present?
      return custom_value.value
    else
      return ''
    end
  end

  # TODO: both required, method_missing for Ruby and before_method for Liquid

  # Allows accessing custom fields by their name:
  #
  # - issue.the_name_of_player => CustomField(:name => "The name Of Player")
  #
  def before_method(method_sym)
    if custom_field_with_matching_name = has_custom_field_with_matching_name?(method_sym)
      custom_field(custom_field_with_matching_name.name)
    else
      super
    end
  end

  # Allows accessing custom fields by their name:
  #
  # - issue.the_name_of_player => CustomField(:name => "The name Of Player")
  #
  def method_missing(method_sym, *arguments, &block)
    if custom_field_with_matching_name = has_custom_field_with_matching_name?(method_sym)
      custom_field(custom_field_with_matching_name.name)
    else
      super
    end
  end

private
  def has_custom_field_with_matching_name?(method_sym)
    custom_field_with_matching_name = @object.available_custom_fields.detect {|custom_field|
      custom_field.name.downcase.underscore.gsub(' ','_') == method_sym.to_s
    }
  end
end
