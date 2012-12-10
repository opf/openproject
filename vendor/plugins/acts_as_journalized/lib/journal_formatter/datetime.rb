class JournalFormatter::Datetime < JournalFormatter::Attribute
  unloadable

  def format_values(values)
    values.map do |v|
      v.nil? ?
        nil :
        format_date(v.to_date)
    end
  end
end
