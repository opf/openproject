class Rate < ActiveRecord::Base
  validates_presence_of :valid_from
  validates_presence_of :rate
  validates_numericality_of :rate, :allow_nil => false

  belongs_to :user
  belongs_to :project

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
    errors.add :valid_from, :not_a_date
  end

  def before_save
    self.valid_from &&= valid_from.to_date
  end

end
