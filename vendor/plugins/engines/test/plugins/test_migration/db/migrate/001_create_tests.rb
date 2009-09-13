class CreateTests < ActiveRecord::Migration
  def self.up
    create_table 'tests' do |t|
      t.column 'name', :string
    end
  end

  def self.down
    drop_table 'tests'
  end
end
