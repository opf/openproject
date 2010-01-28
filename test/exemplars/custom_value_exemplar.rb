class CustomValue < ActiveRecord::Base
  generator_for :custom_field, :method => :generate_custom_field

  def self.generate_custom_field
    CustomField.generate!
  end
end
