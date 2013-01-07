class JournalFormatter::NamedAssociation < JournalFormatter::Attribute
  unloadable

  private

  def format_details(key, values)
    label = label(key)

    old_value, value = *format_values(values, key)

    [label, old_value, value]
  end

  def format_values(values, key)
    field = key.to_s.gsub(/\_id$/, "").to_sym

    association = @journal.journaled.class.reflect_on_association(field)

    values.map do |value|
      if association
        record = association.class_name.constantize.find_by_id(value.to_i)
        record.name if record
      end
    end
  end
end
