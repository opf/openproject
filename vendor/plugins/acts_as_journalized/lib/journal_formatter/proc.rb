class JournalFormatter::Proc < JournalFormatter::Attribute
  unloadable

  class << self
    attr_accessor :proc
  end

  private

  def format_details(key, values)
    label = label(key)

    old_value, value = *format_values(values, key)

    [label, old_value, value]
  end

  def format_values(values, key)
    field = key.to_s.gsub(/\_id$/, "")

    values.map do |value|
      self.class.proc.call value, @journal.journaled, field
    end
  end
end
