class JournalFormatter::Id < JournalFormatter::Attribute
  unloadable

  def format_values(values)
    values.map{ |v| "##{v}" }
  end
end
