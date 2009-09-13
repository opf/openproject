class CreateExtras < ActiveRecord::Migration
  def self.up
    create_table 'extras' do |t|
      t.column 'name', :string
    end
  end

  def self.down
    drop_table 'extras'
  end
end
