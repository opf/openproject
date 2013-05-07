class Rate < ActiveRecord::Base
  validates_numericality_of :rate, :allow_nil => false
  validate :validate_date_is_a_date

  belongs_to :user
  include ::OpenProject::Costs::DeletedUserFallback
  belongs_to :project

  include ActiveModel::ForbiddenAttributesProtection

  def self.clean_currency(value)
    if value && value.is_a?(String)
      value = value.strip
      value.gsub!(l(:currency_delimiter), '') if value.include?(l(:currency_delimiter)) && value.include?(l(:currency_separator))
      value.gsub(',', '.')
    else
      value
    end
  end

  def before_save
    self.valid_from &&= valid_from.to_date
  end

  private

  def validate_date_is_a_date
    valid_from.to_date
  rescue Exception
    errors.add :valid_from, :not_a_date
  end
end
