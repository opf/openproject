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

class OpenProject::JournalFormatter::CustomField < ::JournalFormatter::Base
  # unloadable

  include CustomFieldsHelper

  private

  def format_details(key, values)
    custom_field = CustomField.find_by_id(key.to_s.sub("custom_fields_", "").to_i)

    if custom_field
      label = custom_field.name
      old_value = format_value(values.first, custom_field.field_format) if values.first
      value = format_value(values.last, custom_field.field_format) if values.last
    else
      label = l(:label_deleted_custom_field)
      old_value = values.first
      value = values.last
    end

    [label, old_value, value]
  end

end
