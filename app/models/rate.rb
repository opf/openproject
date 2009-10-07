class Rate < ActiveRecord::Base
  validates_numericality_of :rate, :allow_nil => false, :message => :activerecord_error_invalid

  def self.clean_currency(value)
    if value && value.is_a?(String)
      value = value.strip
      value.gsub!(l(:currency_delimiter), '') if value.include?(l(:currency_delimiter)) && value.include?(l(:currency_separator))
      value.gsub(',', '.')
    else
      value
    end
  end
end