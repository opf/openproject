class API::Experimental::WorkPackageDecorator < SimpleDelegator
  def self.decorate(collection)
    collection.map do |wp|
      new(wp)
    end
  end

  def custom_values_display_data(field_ids)
    field_ids = Array(field_ids)
    field_ids.map do |field_id|
      value = custom_values.detect do |cv|
        cv.custom_field_id == field_id.to_i
      end

      get_cast_custom_value_with_meta(value)
    end
  end

  private

  def get_cast_custom_value_with_meta(custom_value)
    return unless custom_value

    custom_field = custom_value.custom_field
    value = if custom_field.field_format == 'user'
              custom_field.cast_value(custom_value.value).as_json(methods: :name)
            else
              custom_field.cast_value(custom_value.value)
            end

    {
      custom_field_id: custom_field.id,
      field_format: custom_field.field_format, # TODO just return the cast value
      value: value
    }
  end
end
