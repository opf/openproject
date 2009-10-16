class Rate < ActiveRecord::Base
  validates_numericality_of :rate, :allow_nil => false, :message => :activerecord_error_invalid
  validates_format_of :valid_from, :with => /^\d{4}-\d{2}-\d{2}/

  def self.clean_currency(value)
    if value && value.is_a?(String)
      value = value.strip
      value.gsub!(l(:currency_delimiter), '') if value.include?(l(:currency_delimiter)) && value.include?(l(:currency_separator))
      value.gsub(',', '.')
    else
      value
    end
  end
  
  def validate
    valid_from.to_date
  rescue Exception
    errors.add :valid_from, :activerecord_error_invalid
  end

  def before_save
    self.valid_from &&= valid_from.to_date
  end

end