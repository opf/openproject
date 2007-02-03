class SerializePossiblesValues < ActiveRecord::Migration
  def self.up
    CustomField.find(:all).each do |field|
      if field.possible_values and field.possible_values.is_a? String
        field.possible_values = field.possible_values.split('|')
        field.save
      end
    end
  end

  def self.down
  end
end
