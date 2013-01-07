class JournalFormatter::Fraction < JournalFormatter::Attribute
  unloadable

  def format_values(values)
    values.map do |v|
      v.nil? ?
        nil :
        "%0.02f" % v.to_f
    end
  end
end
