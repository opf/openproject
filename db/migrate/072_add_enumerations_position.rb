class AddEnumerationsPosition < ActiveRecord::Migration
  def self.up
    add_column :enumerations, :position, :integer, :default => 1, :null => false
    Enumeration.find(:all).group_by(&:opt).each_value  do |enums|
      enums.each_with_index {|enum, i| enum.update_attribute(:position, i+1)}
    end
  end

  def self.down
    remove_column :enumerations, :position
  end
end
