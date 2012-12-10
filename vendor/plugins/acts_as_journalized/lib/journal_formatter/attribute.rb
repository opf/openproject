class JournalFormatter::Attribute < JournalFormatter::Base
  unloadable

  private

  def format_details(key, values)
    label = label(key)

    old_value, value = *format_values(values)

    [label, old_value, value]
  end

  def format_values(values)
    values.map{ |v| v.try(:to_s) }
  end
end
