class CreateOthers < ActiveRecord::Migration
  def self.up
    create_table 'others' do |t|
      t.column 'name', :string
    end
  end

  def self.down
    drop_table 'others'
  end
end
