class OpenProject::JournalFormatter::CustomField < ::JournalFormatter::Base
  unloadable

  include CustomFieldsHelper

  private

  def format_details(key, values)

    custom_field = CustomField.find_by_id(key.sub("custom_values", "").to_i)

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
