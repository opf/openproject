class JournalFormatter::Plaintext < JournalFormatter::Attribute
  unloadable

  def format_values(values)
    values.map{ |v| v.try(:to_s) }
  end
end
