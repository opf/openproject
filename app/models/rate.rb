class Rate < ActiveRecord::Base
  validates_numericality_of :rate, :allow_nil => false
  validate :validate_date_is_a_date

  before_save :convert_valid_from_to_date

  belongs_to :user
  include ::OpenProject::Costs::DeletedUserFallback
  belongs_to :project

  attr_accessible :rate, :project, :valid_from

  def self.clean_currency(value)
    if value && value.is_a?(String)
      value = value.strip
      value.gsub!(l(:currency_delimiter), '') if value.include?(l(:currency_delimiter)) && value.include?(l(:currency_separator))
      value.gsub(',', '.')
    else
      value
    end
  end


  private

  def convert_valid_from_to_date
    self.valid_from &&= valid_from.to_date
  end

  def validate_date_is_a_date
    valid_from.to_date
  rescue Exception
    errors.add :valid_from, :not_a_date
  end
end
